import UIKit
import PDFKit
import PencilKit
import QuickLook
import os.log

private let log = Logger(subsystem: Bundle.main.bundleIdentifier ?? "PDFPreview",
                         category: "PDFPreviewController")

// MARK: - PDFPreviewController

/// Drop-in replacement for `QLPreviewController` backed by PDFKit's `PDFView`. Reuses
/// `QLPreviewControllerDataSource` so existing data sources work unchanged.
final class PDFPreviewController: UIViewController {

    // MARK: Public properties

    weak var dataSource: QLPreviewControllerDataSource?
    weak var delegate: QLPreviewControllerDelegate?

    // MARK: Private properties

    /// `QLPreviewControllerDataSource` methods require a `QLPreviewController` argument;
    /// we pass a throwaway instance so existing data sources can be reused as-is.
    private let previewController = QLPreviewController()

    private let pdfPreview: PDFPreviewView
    private let pageIndicator: PageIndicatorView
    private let tools: Tools

    private var previewItem: (any QLPreviewItem)? {

        guard let dataSource, dataSource.numberOfPreviewItems(in: previewController) == 1
            else { return nil }

        return dataSource.previewController(previewController, previewItemAt: 0)
    }
    
    // MARK: Init

    init() {

        pdfPreview = PDFPreviewView()
        pageIndicator = PageIndicatorView(for: pdfPreview)
        tools = Tools(for: pdfPreview)

        super.init(nibName: nil, bundle: nil)

        pdfPreview.delegate = self

        NotificationCenter.default.addObserver(
            self, selector: #selector(pdfPageChanged),
            name: .PDFViewPageChanged, object: pdfPreview
        )
    }

    required init?(coder: NSCoder) { fatalError() }

    // MARK: Overrides

    override func viewDidLoad() {
        super.viewDidLoad()

        view.clipsToBounds = true

        pdfPreview.install(in: view)
        tools.install(in: view)

        // Installed inside tools to better support animations that respect Reduce Motion.
        pageIndicator.install(in: tools,
                              alongside: tools.thumbnails,
                              pushedBelow: tools.searchBottomAnchor,
                              trailingLimit: tools.trailingAnchor)

        reloadData()
    }

    override func viewWillTransition(to size: CGSize, with coordinator: UIViewControllerTransitionCoordinator) {
        super.viewWillTransition(to: size, with: coordinator)

        // After rotation / split-view resize the previous scroll offset can leave the
        // highlighted thumbnail off-screen; re-focus it once the transition settles.
        coordinator.animate(alongsideTransition: nil) { _ in
            self.tools.thumbnails.scrollToCurrentPage(animated: false)
        }
    }

    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)

        // If the screen is leaving while markup is active, tear it down now — while the
        // responder chain is still intact — so the PKToolPicker observer is removed and the
        // host's nav-bar items are restored, rather than leaking on dismissal.
        tools.endMarkup()
    }

    // MARK: Public methods

    func reloadData() {

        guard let item = previewItem, let url = item.previewItemURL
            else { return }

        // Update the title if it is provided by the item
        if let itemTitle = item.previewItemTitle as? String, !itemTitle.isEmpty, let parent {
            parent.title = itemTitle
        }
        
        pdfPreview.load(from: url) { [weak self] in

            self?.tools.reload()
            self?.pageIndicator.reload()
        }
    }

    // MARK: Private methods

    @objc private func pdfPageChanged() {

        // Skip page-indicator refresh while markup is loading documents.
        guard tools.current != .markup
            else { return }

        pageIndicator.reload()
    }
}

extension PDFPreviewController: PDFViewDelegate {
    
    func pdfViewWillClick(onLink sender: PDFView, with url: URL) {

        guard let item = previewItem
            else { return }

        // Ask the QLPreviewControllerDelegate if we should open the link
        let shouldOpen = delegate?.previewController?(previewController,
                                                     shouldOpen: url,
                                                     for: item) ?? true

        guard shouldOpen
            else { return }

        UIApplication.shared.open(url)
    }
}

// MARK: - PDFPreviewView

private final class PDFPreviewView: PDFView {

    // MARK: Public properties

    /// Fired when the PDF view is tapped once; used by the host to toggle the thumbnails panel.
    var onSingleTap: (() -> Void)?

    /// Fires when the user begins any interaction (pan, pinch, or double-tap) that
    /// should dismiss floating chrome.
    var onInteraction: (() -> Void)?

    var isScrollEnabled: Bool {
        get { innerScrollView?.isScrollEnabled ?? true }
        set { innerScrollView?.isScrollEnabled = newValue }
    }

    /// True once the user has baked stamps via `applyModifications`. Used by the share
    /// flow to decide between exporting the original URL and writing the modified copy.
    var hasModifications: Bool { modifiedDocument != nil }

    /// Vertical insets taken by floating chrome (search bar on top, toolbar on bottom).
    /// Pushed into PDFKit's inner scroll view so content and scroll indicator both
    /// respect it. When the top inset changes and the user was scrolled to the very
    /// top, the scroll position is bumped so the page top stays parked just below the
    /// new chrome; mid-document positions are left alone (chrome covers what it covers).
    var chromeInsets: UIEdgeInsets = .zero {
        didSet {
            
            guard let scroll = innerScrollView
                else { return }

            let wasAtTop = scroll.contentOffset.y <= -oldValue.top + 0.5

            scroll.contentInset.top = chromeInsets.top
            scroll.contentInset.bottom = chromeInsets.bottom
            scroll.verticalScrollIndicatorInsets.top = chromeInsets.top
            scroll.verticalScrollIndicatorInsets.bottom = chromeInsets.bottom

            if wasAtTop, chromeInsets.top != oldValue.top {
                scroll.contentOffset.y = -chromeInsets.top
            }
        }
    }

    // MARK: Private properties

    /// The document as loaded from disk.
    private var originalDocument: PDFDocument?

    /// A copy of `originalDocument` carrying the current baked annotations. Lazily
    /// created on first apply and overwritten on each subsequent apply.
    private var modifiedDocument: PDFDocument?

    /// Cached width of the first page in PDF coordinates, used to compute `fullWidthScale`.
    private var pageWidth: CGFloat?

    /// The scale factor that fits the page to the available width.
    private var fullWidthScale: CGFloat?

    /// Spinner shown (after a short grace delay) while a document is parsed off the main
    /// thread. Centred over the view; `hidesWhenStopped` keeps it invisible otherwise.
    private let loadingIndicator: UIActivityIndicatorView = {
        
        let indicator = UIActivityIndicatorView(style: .large)

        indicator.hidesWhenStopped = true
        indicator.translatesAutoresizingMaskIntoConstraints = false
        indicator.accessibilityLabel = Strings.loadingDocument

        return indicator
    }()

    /// Bumped on every `load(from:)` so a slow parse that finishes after a newer load was
    /// requested can be discarded instead of clobbering the newer document.
    private var loadGeneration = 0

    /// True while a parse is in flight. The grace-delay spinner only starts if this is still set when the delay fires.
    private var isParsing = false

    private var contentOffset: CGPoint {
        get { innerScrollView?.contentOffset ?? .zero }
        set { innerScrollView?.contentOffset = newValue }
    }

    /// PDFKit doesn't expose its inner `UIScrollView`. We reach in for it here so we can
    /// drive content insets, scroll position, and keyboard-dismiss behaviour.
    private var innerScrollView: UIScrollView? {
        firstSubview(ofType: UIScrollView.self)
    }

    // MARK: Init

    override init(frame: CGRect) {
        super.init(frame: frame)
        
        displayMode = .singlePageContinuous
        displayDirection = .vertical
        pageBreakMargins = UIEdgeInsets(top: 0, left: 0, bottom: 16, right: 0)
        maxScaleFactor = 4.0
        backgroundColor = .systemGray5
        translatesAutoresizingMaskIntoConstraints = false

        setupGestures()
    }

    required init?(coder: NSCoder) { fatalError() }

    // MARK: Overrides

    override func didMoveToWindow() {
        super.didMoveToWindow()

        // Drag-to-dismiss the search keyboard while panning the PDF. Set here because
        // PDFKit's inner scroll view is lazily created and isn't ready in `init`.
        innerScrollView?.keyboardDismissMode = .interactive
    }

    /// Scrolls to `page`, aligned to the *unobscured* viewport (the region not covered
    /// by floating chrome, inset via `chromeInsets`). Centres the page if it fits,
    /// bottom-aligns if it spills into chrome but fits the viewport, or top-aligns if
    /// it's taller than the viewport. Final offset is clamped to the valid scroll range.
    override func go(to page: PDFPage) {
        
        guard let scrollView = innerScrollView else {
            super.go(to: page)
            return
        }

        scrollView.scrollIntoUnobscuredViewport(for: contentRect(for: page))
    }

    override func layoutSubviews() {
        super.layoutSubviews()

        let availableWidth = bounds.width - safeAreaInsets.left - safeAreaInsets.right

        guard let pageWidth, availableWidth > 0
            else { return }

        let scaleToFitWidth = availableWidth / pageWidth

        guard fullWidthScale != scaleToFitWidth
            else { return }

        if abs(scaleFactor - (fullWidthScale ?? scaleFactor)) < 0.001 {
            scaleFactor = scaleToFitWidth
        }

        fullWidthScale = scaleToFitWidth
    }

    // MARK: Public methods

    func install(in parent: UIView) {

        parent.addSubview(self)
        addSubview(loadingIndicator)

        NSLayoutConstraint.activate([
            topAnchor.constraint(equalTo: parent.safeAreaLayoutGuide.topAnchor),
            leadingAnchor.constraint(equalTo: parent.leadingAnchor),
            trailingAnchor.constraint(equalTo: parent.trailingAnchor),

            loadingIndicator.centerXAnchor.constraint(equalTo: centerXAnchor),
            loadingIndicator.centerYAnchor.constraint(equalTo: centerYAnchor)
        ])
    }

    /// Parses the PDF off the main thread and assigns it on the main thread.
    func load(from url: URL, completion: (() -> Void)? = nil) {

        // QLPreviewItem only supports local file URLs.
        guard url.isFileURL else {
            log.error("URL to PDF must be a local file URL: \(url, privacy: .public)")
            completion?()
            return
        }

        loadGeneration += 1
        let generation = loadGeneration
        
        isParsing = true

        // Show the spinner only if the parse is still running after a short grace delay,
        // so the fast local-file case doesn't flash it for a single frame.
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.15) { [weak self] in
            
            guard let self, self.loadGeneration == generation, self.isParsing
                else { return }

            self.loadingIndicator.startAnimating()
        }

        DispatchQueue.global(qos: .userInitiated).async { [weak self] in

            // Parsing is the expensive part and is safe off the main thread; assigning
            // it to the PDFView is not, so that hops back to main below.
            let parsed = PDFDocument(url: url)

            DispatchQueue.main.async {

                // Bail early if load was called again before this
                guard let self, self.loadGeneration == generation
                    else { return }

                self.isParsing = false
                self.loadingIndicator.stopAnimating()

                if parsed == nil {
                    log.error("PDFDocument failed to parse URL: \(url, privacy: .public)")
                }

                self.originalDocument = parsed
                self.modifiedDocument = nil
                self.document = parsed

                self.pageWidth = parsed?.page(at: 0)?.bounds(for: self.displayBox).width
                self.fullWidthScale = nil
                
                self.setNeedsLayout()
                self.layoutIfNeeded()

                completion?()
            }
        }
    }

    /// Scroll a search selection into the centre of the unobscured viewport. Used in
    /// place of `PDFView.go(to: PDFSelection)`, which ignores `contentInset` (matches
    /// land under the search bar / toolbar).
    func reveal(_ selection: PDFSelection) {
        
        guard let scrollView = innerScrollView,
              let page = selection.pages.first,
              selection.numberOfTextRanges(on: page) > 0,
              let pageBounds = selection.firstOnPageGlyphBounds(on: page, in: displayBox)
        else { return }

        scrollView.scrollIntoUnobscuredViewport(for: contentRect(of: pageBounds, on: page))
    }
    
    func showActivityIndicator() {
        loadingIndicator.startAnimating()
    }
    
    func hideActivityIndicator() {
        loadingIndicator.stopAnimating()
    }

    /// Drop any baked modifications and display the original. The next
    /// `applyModifications` call will copy from a clean slate.
    func clearModifications() {
        
        modifiedDocument = nil
        swap(to: originalDocument)
    }

    /// Create a copy of the original, hand it to `apply` to bake changes onto,
    /// then display the result. `originalDocument` is left untouched so subsequent
    /// applies always start from a clean slate.
    func applyModifications(_ apply: (PDFDocument) -> Void) {

        guard let modified = originalDocument?.copy() as? PDFDocument else {
            log.error("Cannot apply markup: originalDocument is nil or not copyable.")
            return
        }

        apply(modified)
        modifiedDocument = modified
        swap(to: modified)
    }

    // MARK: Gestures

    private func setupGestures() {

        let singleTap = UITapGestureRecognizer(target: self, action: #selector(handleSingleTap(_:)))
        let doubleTap = UITapGestureRecognizer(target: self, action: #selector(handleDoubleTap))
        doubleTap.numberOfTapsRequired = 2

        let pan = UIPanGestureRecognizer(target: self, action: #selector(handleInteraction))
        let pinch = UIPinchGestureRecognizer(target: self, action: #selector(handleInteraction))

        for recognizer in [singleTap, doubleTap, pan, pinch] as [UIGestureRecognizer] {
            recognizer.delegate = self
            recognizer.cancelsTouchesInView = false
            addGestureRecognizer(recognizer)
        }
    }

    @objc private func handleSingleTap(_ gesture: UITapGestureRecognizer) {

        // If the tap landed on a link annotation, let PDFView handle the navigation
        // and don't toggle the floating chrome.
        let viewPoint = gesture.location(in: self)

        if let page = page(for: viewPoint, nearest: true) {
            
            let pagePoint = convert(viewPoint, to: page)
            
            if let annotation = page.annotation(at: pagePoint), annotation.isLink {
                return
            }
        }

        onSingleTap?()
    }

    @objc private func handleDoubleTap() {
        onInteraction?()
    }

    @objc private func handleInteraction(_ gesture: UIGestureRecognizer) {

        switch gesture.state {

            case .began:
                onInteraction?()

            case .ended, .cancelled:

                // Snap to fullWidthScale if the user released a pinch within 10% of it.
                guard let target = fullWidthScale, abs(scaleFactor - target) < target * 0.1
                    else { return }

                UIView.animateRespectingReduceMotion(duration: 0.2) {
                    self.scaleFactor = target
                }

            default: break
        }
    }

    // MARK: Coordinate conversion

    /// Convert a page-space rect to content space (scroll view's `contentSize` coords).
    private func contentRect(of pageRect: CGRect, on page: PDFPage) -> CGRect {

        var rect = convert(pageRect, from: page)
        rect.origin.y += contentOffset.y

        return rect
    }

    /// The whole page's bounds in content space.
    private func contentRect(for page: PDFPage) -> CGRect {
        contentRect(of: page.bounds(for: displayBox), on: page)
    }

    // MARK: Document swap

    /// Swap PDFView's `document` to `next` while preserving the user's viewport.
    private func swap(to next: PDFDocument?) {
        
        guard let next, document !== next
            else { return }

        let savedOffset = contentOffset
        let savedScale = scaleFactor

        document = next
        scaleFactor = savedScale
        contentOffset = savedOffset
    }
}

extension PDFPreviewView {

    /// Allow our recognizers to fire alongside PDFView's built-in ones, e.g. our
    /// double-tap that fires `onInteraction` runs in parallel with PDFView's own
    /// double-tap-to-zoom, and our pinch dismisses chrome while PDFView's pinch zooms.
    override func gestureRecognizer(_ gestureRecognizer: UIGestureRecognizer,
                                    shouldRecognizeSimultaneouslyWith other: UIGestureRecognizer) -> Bool {
        true
    }

    /// Defer our single-tap until any multi-tap (notably PDFView's built-in
    /// double-tap-to-zoom) has had a chance to fail, otherwise the first tap of a
    /// double-tap-to-zoom also triggers single-tap behaviour.
    override func gestureRecognizer(_ gestureRecognizer: UIGestureRecognizer,
                                    shouldRequireFailureOf other: UIGestureRecognizer) -> Bool {

        guard let tap = gestureRecognizer as? UITapGestureRecognizer, tap.numberOfTapsRequired == 1,
              let otherTap = other as? UITapGestureRecognizer, otherTap.numberOfTapsRequired >= 2
        else { return false }

        return true
    }
}

// MARK: - PageIndicatorView

/// QL-style page indicator: light pill with a doc icon and "X of Y".
private final class PageIndicatorView: UIView {

    // MARK: Private properties

    private let pdfPreview: PDFPreviewView
    private let imageView = UIImageView(image: UIImage(systemName: "book.pages"))
    private let label = UILabel()
    private var hideWorkItem: DispatchWorkItem?

    // MARK: Init

    init(for pdfPreview: PDFPreviewView) {

        self.pdfPreview = pdfPreview
        super.init(frame: .zero)

        alpha = 0
        translatesAutoresizingMaskIntoConstraints = false
        backgroundColor = UIColor.systemBackground.withAlphaComponent(0.92)

        // The pill is transient visual feedback that fades out so don't let VoiceOver chase it.
        accessibilityElementsHidden = true

        layer.cornerCurve = .continuous
        layer.shadowColor = UIColor.black.cgColor
        layer.shadowOpacity = 0.12
        layer.shadowRadius = 6
        layer.shadowOffset = CGSize(width: 0, height: 2)

        imageView.tintColor = .label
        imageView.contentMode = .scaleAspectFit
        imageView.preferredSymbolConfiguration = UIImage.SymbolConfiguration(textStyle: .subheadline)
            .applying(UIImage.SymbolConfiguration(weight: .semibold))

        label.adjustsFontForContentSizeCategory = true
        label.textColor = .label
        label.adjustsFontSizeToFitWidth = true
        label.minimumScaleFactor = 0.5
        label.font = UIFontMetrics(forTextStyle: .subheadline)
            .scaledFont(for: .monospacedDigitSystemFont(ofSize: 15, weight: .semibold))

        // When the thumbnails panel and pill compete for space (large Dynamic Type),
        // let the pill's label compress so the pill shrinks instead of pushing back
        // on thumbnails. The font scales down inside the compressed width so the
        // text stays fully visible.
        label.setContentCompressionResistancePriority(.defaultLow, for: .horizontal)

        let stack = UIStackView(arrangedSubviews: [imageView, label])
        stack.alignment = .center
        stack.spacing = 6
        stack.translatesAutoresizingMaskIntoConstraints = false
        addSubview(stack)

        NSLayoutConstraint.activate([
            stack.leadingAnchor.constraint(equalTo: leadingAnchor, constant: 14),
            stack.trailingAnchor.constraint(equalTo: trailingAnchor, constant: -14),
            stack.topAnchor.constraint(equalTo: topAnchor, constant: 8),
            stack.bottomAnchor.constraint(equalTo: bottomAnchor, constant: -8)
        ])
    }

    required init?(coder: NSCoder) { fatalError() }

    // MARK: Overrides

    /// Keep a capsule (fully-rounded) shape as the intrinsic height changes.
    override func layoutSubviews() {
        super.layoutSubviews()
        
        layer.cornerRadius = bounds.height / 2
    }

    // MARK: Public methods

    /// Adds the pill to `parent`, anchored to the right of `neighbour` and aligned with
    /// its top, but never crossing the parent's leading safe-area inset, pushed below
    /// `pushedBelow` (e.g. the search bar) when that anchor sits lower than the
    /// neighbour's top, and never extending past `trailingLimit` (the PDF view's
    /// trailing edge minus a gap) so the pill stays fully inside the viewport.
    func install(in parent: UIView,
                 alongside neighbour: UIView,
                 pushedBelow: NSLayoutYAxisAnchor,
                 trailingLimit: NSLayoutXAxisAnchor) {

        parent.addSubview(self)

        let gap: CGFloat = 12

        let pullLeading = leadingAnchor.constraint(equalTo: parent.leadingAnchor)
        pullLeading.priority = .defaultLow

        let pullTop = topAnchor.constraint(equalTo: neighbour.topAnchor)
        pullTop.priority = .defaultLow

        NSLayoutConstraint.activate([
            leadingAnchor.constraint(greaterThanOrEqualTo: parent.safeAreaLayoutGuide.leadingAnchor),
            leadingAnchor.constraint(greaterThanOrEqualTo: neighbour.trailingAnchor, constant: gap),
            trailingAnchor.constraint(lessThanOrEqualTo: trailingLimit, constant: -gap),

            pullLeading,

            topAnchor.constraint(greaterThanOrEqualTo: neighbour.topAnchor),
            topAnchor.constraint(greaterThanOrEqualTo: pushedBelow, constant: gap * 0.5),

            pullTop
        ])
    }

    /// Updates the label to the current page and flashes the pill in (auto-fades out).
    func reload() {

        guard let document = pdfPreview.document, let index = pdfPreview.currentPageIndex
            else { label.text = nil; return }

        label.text = Strings.pageOfPages(index + 1, of: document.pageCount)

        flash()
    }

    // MARK: Private methods

    /// Fades the pill in (if hidden) and queues an auto-fade-out after a short delay.
    /// Cancels any previously-queued fade-out so back-to-back calls don't hide it early.
    private func flash() {

        hideWorkItem?.cancel()

        if alpha < 1 {
            UIView.animate(withDuration: 0.2) { self.alpha = 1 }
        }

        let workItem = DispatchWorkItem { [weak self] in
            UIView.animate(withDuration: 0.4) { self?.alpha = 0 }
        }

        hideWorkItem = workItem

        DispatchQueue.main.asyncAfter(deadline: .now() + 1.5, execute: workItem)
    }
}

// MARK: - Thumbnails

/// Self-contained side panel showing a vertical scroll of page thumbnails.
private final class Thumbnails: UIVisualEffectView {

    // MARK: Public properties

    /// Fired with the selected page index when the user picks a page from the panel.
    var onPageSelected: ((Int) -> Void)?

    /// Toggle to slide the panel into view, or tuck it off the leading edge.
    /// Wrap the assignment in `UIView.animate` to animate the frame change.
    var isShown: Bool {
        get { shownConstraint.isActive }
        set {
            hiddenConstraint.isActive = !newValue
            shownConstraint.isActive = newValue
            
            accessibilityElementsHidden = !newValue
        }
    }

    // MARK: Private properties

    private let pdfPreview: PDFPreviewView
    private let flowLayout = UICollectionViewFlowLayout()
    private let collectionView: UICollectionView

    /// Un-scaled reference size, drives the bar's preferred (intrinsic) width via
    /// `UIFontMetrics` and the cell aspect ratio.
    private let baseSize: CGSize
    private let padding: CGFloat

    /// Rendered thumbnails keyed by page index.
    private let thumbnailCache: NSCache<NSNumber, UIImage> = {
        
        let cache = NSCache<NSNumber, UIImage>()
        cache.countLimit = 60
        
        return cache
    }()

    /// Concurrent queue for off-main thumbnail rendering.
    private let renderQueue = DispatchQueue(label: "io.cobrowse.pdf.thumbnails",
                                            qos: .userInitiated, attributes: .concurrent)

    /// Bumped whenever the cache is invalidated (new document, new item size) so an
    /// in-flight render sized for the old state is discarded instead of cached/displayed.
    private var cacheGeneration = 0

    /// Active when the panel is visible: leading pinned 16pt inside the safe area.
    private var shownConstraint: NSLayoutConstraint!

    /// Active when the panel is hidden: trailing pinned to the parent leading edge so
    /// the bar sits fully off-screen, no width math required.
    private var hiddenConstraint: NSLayoutConstraint!

    private var spacing: CGFloat { padding * 2 }

    /// Cell size derived from the bar's actual width so cells always fit inside.
    private var currentItemSize: CGSize {

        let itemWidth = max(0, bounds.width - padding * 2)

        return CGSize(width: itemWidth,
                      height: itemWidth * baseSize.height / baseSize.width)
    }
    
    /// Centre if the cell fits the visible region, otherwise pin to the top so the
    /// user sees the start of the (clipped) cell.
    private var preferredScrollPosition: UICollectionView.ScrollPosition {
        
        let visibleHeight = collectionView.bounds.height
            - collectionView.adjustedContentInset.top
            - collectionView.adjustedContentInset.bottom
        
        return flowLayout.itemSize.height <= visibleHeight ? .centeredVertically : .top
    }

    private var selectedPage: Int? {
        collectionView.indexPathsForSelectedItems?.first?.item
    }

    // MARK: Init

    init(for pdfPreview: PDFPreviewView,
         size: CGSize = CGSize(width: 72, height: 96),
         padding: CGFloat = 12) {

        self.pdfPreview = pdfPreview
        self.baseSize = size
        self.padding = padding

        let effect: UIVisualEffect

        if #available(iOS 26.0, *) {
            effect = UIGlassEffect()
        } else {
            effect = UIBlurEffect(style: .systemThickMaterial)
        }

        flowLayout.scrollDirection = .vertical
        flowLayout.minimumLineSpacing = padding
        flowLayout.sectionInset = UIEdgeInsets(top: 0, left: padding, bottom: 0, right: padding)

        collectionView = UICollectionView(frame: .zero, collectionViewLayout: flowLayout)
        collectionView.backgroundColor = .clear
        collectionView.showsVerticalScrollIndicator = false
        collectionView.alwaysBounceVertical = true
        collectionView.contentInsetAdjustmentBehavior = .never
        collectionView.contentInset = UIEdgeInsets(top: padding, left: 0, bottom: padding, right: 0)
        collectionView.translatesAutoresizingMaskIntoConstraints = false

        super.init(effect: effect)

        translatesAutoresizingMaskIntoConstraints = false
        layer.cornerRadius = 18
        layer.cornerCurve = .continuous
        clipsToBounds = true
        setContentHuggingPriority(.defaultHigh, for: .horizontal)
        accessibilityElementsHidden = true

        collectionView.dataSource = self
        collectionView.delegate = self
        collectionView.register(ThumbnailCell.self, forCellWithReuseIdentifier: ThumbnailCell.reuseID)

        contentView.addSubview(collectionView)

        NSLayoutConstraint.activate([
            collectionView.topAnchor.constraint(equalTo: contentView.topAnchor),
            collectionView.bottomAnchor.constraint(equalTo: contentView.bottomAnchor),
            collectionView.leadingAnchor.constraint(equalTo: contentView.leadingAnchor),
            collectionView.trailingAnchor.constraint(equalTo: contentView.trailingAnchor)
        ])
    }

    required init?(coder: NSCoder) { fatalError() }

    // MARK: Overrides

    /// Bar width (scaled by Dynamic Type) capped to half the PDF view's width so the
    /// panel never dominates the viewport.
    override var intrinsicContentSize: CGSize {
        
        let preferredWidth = UIFontMetrics.default.scaledValue(for: baseSize.width) + padding * 2
        
        return CGSize(width: preferredWidth, height: UIView.noIntrinsicMetric)
    }

    override func layoutSubviews() {
        super.layoutSubviews()

        let itemSize = currentItemSize

        if flowLayout.itemSize != itemSize {
            flowLayout.itemSize = itemSize
            flowLayout.invalidateLayout()

            // Cached images were rendered for the old size.
            // Drop them so cells re-render at the new dimensions.
            invalidateThumbnailCache()

            collectionView.reloadData()
            selectCurrentPage()
        }
    }

    /// Bumps the cache generation (discarding in-flight renders) and empties the cache.
    private func invalidateThumbnailCache() {
        
        cacheGeneration += 1
        thumbnailCache.removeAllObjects()
    }

    // MARK: Public methods

    /// Adds the panel to `parent`, pins its top and bottom edges (with breathing margin),
    /// and tucks it offscreen to the left.
    func install(in parent: UIView,
                 topAnchor: NSLayoutYAxisAnchor,
                 bottomAnchor: NSLayoutYAxisAnchor) {

        parent.addSubview(self)

        shownConstraint = leadingAnchor.constraint(equalTo: parent.safeAreaLayoutGuide.leadingAnchor, constant: 16)
        hiddenConstraint = trailingAnchor.constraint(equalTo: parent.leadingAnchor)

        NSLayoutConstraint.activate([
            self.topAnchor.constraint(equalTo: topAnchor, constant: spacing),
            self.bottomAnchor.constraint(equalTo: bottomAnchor, constant: -spacing),
            hiddenConstraint  // start hidden
        ])
    }

    func reload() {

        // A new document may have loaded; drop thumbnails rendered from the previous one.
        invalidateThumbnailCache()
        collectionView.reloadData()
    }

    /// Sync the highlighted cell to PDFView's current page. No-op if already selected.
    func selectCurrentPage() {

        guard let index = pdfPreview.currentPageIndex, selectedPage != index
            else { return }

        collectionView.selectItem(at: IndexPath(item: index, section: 0),
                                  animated: false, scrollPosition: [])
    }

    func scrollToCurrentPage(animated: Bool) {

        guard let index = pdfPreview.currentPageIndex
            else { return }

        collectionView.scrollToItem(at: IndexPath(item: index, section: 0),
                                    at: preferredScrollPosition, animated: animated)
    }

    /// Moves VoiceOver focus onto the current-page cell when the panel opens, so the user lands on the relevant thumbnail.
    func moveAccessibilityFocusToCurrentPage() {

        guard UIAccessibility.isVoiceOverRunning
            else { return }

        let target: Any = pdfPreview.currentPageIndex
            .flatMap {
                collectionView.cellForItem(at: IndexPath(item: $0, section: 0))
            } ?? self

        UIAccessibility.post(notification: .layoutChanged, argument: target)
    }
}

extension Thumbnails: UICollectionViewDataSource, UICollectionViewDelegate {

    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        pdfPreview.document?.pageCount ?? 0
    }

    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {

        let cell = collectionView.dequeueReusableCell(withReuseIdentifier: ThumbnailCell.reuseID, for: indexPath) as! ThumbnailCell

        let index = indexPath.item
        cell.representedIndex = index
        cell.accessibilityLabel = Strings.pageNumber(index + 1)

        let key = NSNumber(value: index)
        
        if let cached = thumbnailCache.object(forKey: key) {
            cell.display(cached)
            return cell
        }

        cell.display(nil)
        
        guard let page = pdfPreview.document?.page(at: index)
            else { return cell }

        let itemSize = flowLayout.itemSize
        let scale = renderScale
        let generation = cacheGeneration

        renderQueue.async { [weak self] in

            let image = page.thumbnail(
                of: CGSize(width: itemSize.width * scale, height: itemSize.height * scale),
                for: .cropBox
            )

            DispatchQueue.main.async {

                // Bail early if the document or item size changed.
                guard let self, self.cacheGeneration == generation
                    else { return }

                self.thumbnailCache.setObject(image, forKey: key)
                
                guard let liveCell = collectionView.cellForItem(at: indexPath) as? ThumbnailCell,
                      liveCell.representedIndex == index
                else { return }

                liveCell.display(image)
            }
        }

        return cell
    }

    func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {

        guard let page = pdfPreview.document?.page(at: indexPath.item)
            else { return }

        // Scroll the panel immediately rather than waiting for the PDFViewPageChanged
        // round-trip, feels more responsive on tap.
        collectionView.scrollToItem(at: indexPath, at: preferredScrollPosition, animated: true)
        
        pdfPreview.go(to: page)

        onPageSelected?(indexPath.item)
    }
}

// MARK: - ThumbnailCell

/// One thumbnail in the panel. `isSelected` drives a gray overlay marking the current page.
private final class ThumbnailCell: UICollectionViewCell {

    // MARK: Public properties

    static let reuseID = "ThumbnailCell"

    /// The page index this cell currently represents. Checked when an async thumbnail
    /// render finishes so a slow render can't land in a cell that's been reused.
    var representedIndex: Int?

    // MARK: Private properties

    private let imageView = UIImageView()
    private let overlay = UIView()

    // MARK: Init

    override init(frame: CGRect) {
        super.init(frame: frame)

        imageView.contentMode = .scaleAspectFit
        imageView.backgroundColor = .white
        imageView.layer.borderWidth = 0.5
        imageView.layer.borderColor = UIColor.separator.cgColor
        imageView.translatesAutoresizingMaskIntoConstraints = false
        contentView.addSubview(imageView)

        overlay.backgroundColor = UIColor.systemGray.withAlphaComponent(0.4)
        overlay.isHidden = true
        overlay.isUserInteractionEnabled = false
        overlay.translatesAutoresizingMaskIntoConstraints = false
        contentView.addSubview(overlay)

        NSLayoutConstraint.activate([
            imageView.topAnchor.constraint(equalTo: contentView.topAnchor),
            imageView.bottomAnchor.constraint(equalTo: contentView.bottomAnchor),
            imageView.leadingAnchor.constraint(equalTo: contentView.leadingAnchor),
            imageView.trailingAnchor.constraint(equalTo: contentView.trailingAnchor),

            overlay.topAnchor.constraint(equalTo: imageView.topAnchor),
            overlay.bottomAnchor.constraint(equalTo: imageView.bottomAnchor),
            overlay.leadingAnchor.constraint(equalTo: imageView.leadingAnchor),
            overlay.trailingAnchor.constraint(equalTo: imageView.trailingAnchor)
        ])

        layer.shadowColor = UIColor.black.cgColor
        layer.shadowOpacity = 0.15
        layer.shadowRadius = 4
        layer.shadowOffset = CGSize(width: 0, height: 2)

        // Treat the whole cell as one VoiceOver element
        isAccessibilityElement = true
        accessibilityTraits = .button
    }

    required init?(coder: NSCoder) { fatalError() }

    // MARK: Overrides

    override var isSelected: Bool {
        didSet {
            overlay.isHidden = !isSelected
            accessibilityTraits = isSelected ? [.button, .selected] : .button
        }
    }

    override func prepareForReuse() {
        super.prepareForReuse()

        representedIndex = nil
        imageView.image = nil
        
        accessibilityLabel = nil
        accessibilityTraits = .button
    }

    // MARK: Public methods

    /// Sets the thumbnail image (or clears it while a render is pending).
    func display(_ image: UIImage?) {
        imageView.image = image
    }
}

// MARK: - Tools

/// Owns the bottom action bar plus every chrome it launches (search, markup, thumbnails).
/// Encapsulates the tool state machine, what's currently shown, transitions, and the
/// per-tool behaviours (search results, markup baking, etc.). The host controller wires
/// callbacks for the few operations that need a UIViewController context (presenting the
/// share sheet, mutating the navigation bar during markup).
private final class Tools: UIView {

    // MARK: Tool

    enum Tool { case none, thumbnails, search, markup }

    // MARK: Public properties

    let thumbnails: Thumbnails

    /// The search bar's bottom edge, exposed so chrome that could collide with the
    /// search bar when it slides in (e.g. the page-indicator pill) can constrain itself
    /// below this anchor.
    var searchBottomAnchor: NSLayoutYAxisAnchor {
        search.bottomAnchor
    }

    private(set) var current: Tool = .none {
        didSet {

            guard oldValue != current
                else { return }

            animate(current: oldValue, .out)
            animate(current: current, .in)
        }
    }

    // MARK: Private properties

    private let pdfPreview: PDFPreviewView
    private let toolBar = UIToolbar()
    private let search = Search()
    private let markup = Markup()

    private let shareItem = UIBarButtonItem()
    private let searchItem = UIBarButtonItem()
    private let markupItem = UIBarButtonItem()

    /// Serial queue for running `findString` off the main thread.
    private let searchQueue = DispatchQueue(label: "PDFPreviewController.search", qos: .userInitiated)

    /// Queue for serializing a modified document to disk off the main thread (share flow).
    private let exportQueue = DispatchQueue(label: "PDFPreviewController.export", qos: .userInitiated)

    /// True while an export (serialise + write) is in flight.
    private var isExporting = false

    /// Bumped per export so a serialization that finishes after teardown is discarded.
    private var shareGeneration = 0

    private var defaultItems: [UIBarButtonItem] {
        toolBarItems([shareItem, searchItem, markupItem])
    }

    /// Standard breathing room used wherever floating chrome needs space from an edge
    /// or another sibling (toolbar bottom floor on iPad sheets, keyboard gap on iOS 26+,
    /// toolbar item edge padding on iOS < 26, thumbnails-to-PDF-centre gap).
    private let defaultGap: CGFloat = 16

    // MARK: Init

    init(for pdfPreview: PDFPreviewView) {

        self.pdfPreview = pdfPreview

        thumbnails = Thumbnails(for: pdfPreview)
        toolBar.translatesAutoresizingMaskIntoConstraints = false

        super.init(frame: .zero)

        translatesAutoresizingMaskIntoConstraints = false

        toolBar.items = defaultItems

        search.bar.delegate = self
        configureBarItemActions()

        pdfPreview.onSingleTap = { [weak self] in

            // Guard against iPad presenting share sheet, a tap-to-dismiss can leak
            // through to the gesture recogniser.
            guard let self,
                  let host = self.pdfPreview.parentViewController,
                  host.presentedViewController == nil
            else { return }

            self.toggle(.thumbnails)
        }

        pdfPreview.onInteraction = { [weak self] in
            self?.dismiss(.thumbnails)
        }

        // Under VoiceOver, picking a page from the panel dismisses it.
        // Sighted users keep the panel open to flip between pages.
        thumbnails.onPageSelected = { [weak self] pageIndex in

            guard UIAccessibility.isVoiceOverRunning, let self
                else { return }

            self.dismiss(.thumbnails)
            
            let total = self.pdfPreview.document?.pageCount ?? 0
            
            UIAccessibility.post(notification: .screenChanged,
                                 argument: [Strings.pageAnnouncement(pageIndex + 1, of: total), self.pdfPreview])
        }

        // Enabled state of every tool tracks whether a document has been loaded.
        NotificationCenter.default.addObserver(
            self, selector: #selector(updateToolsEnabledState),
            name: .PDFViewDocumentChanged, object: pdfPreview
        )

        // UIBarButtonItem images / titles don't auto-update on Dynamic Type changes,
        // and `UIFontMetrics.default.scaledValue(for:)` is resolved at the call site.
        // Refresh everything that depends on it whenever the content size changes.
        NotificationCenter.default.addObserver(
            self, selector: #selector(contentSizeCategoryChanged),
            name: UIContentSizeCategory.didChangeNotification, object: nil
        )

        updateToolsEnabledState()
    }

    required init?(coder: NSCoder) { fatalError() }

    // MARK: Overrides

    /// Touches that hit Tools' empty space pass through to the PDF view below. Only
    /// touches landing on actual chrome (bar, thumbnails, search, canvas) are absorbed.
    override func hitTest(_ point: CGPoint, with event: UIEvent?) -> UIView? {

        let hit = super.hitTest(point, with: event)

        return hit === self ? nil : hit
    }

    override func layoutSubviews() {
        super.layoutSubviews()

        // Top inset matches the search bar's live intrinsic height when shown, so it
        // tracks Dynamic Type changes that resize the bar mid-display.
        let topInset = current == .search ? search.bar.intrinsicContentSize.height : 0

        if pdfPreview.chromeInsets.top != topInset {
            pdfPreview.chromeInsets.top = topInset
        }

        // iOS 26+ Liquid Glass toolbar floats over the PDF.
        // Inset so content can scroll past it.
        if #available(iOS 26.0, *) {
            let bottomInset = bounds.height - toolBar.frame.minY - safeAreaInsets.bottom

            if pdfPreview.chromeInsets.bottom != bottomInset {
                pdfPreview.chromeInsets.bottom = bottomInset
            }
        }
    }

    // MARK: Public methods

    func install(in parent: UIView) {

        parent.addSubview(self)
        addSubview(toolBar)

        thumbnails.install(in: self,
                           topAnchor: safeAreaLayoutGuide.topAnchor,
                           bottomAnchor: toolBar.topAnchor)
        search.install(in: self)
        markup.install(in: self)

        // Toolbar prefers the safe-area bottom (home-indicator inset) but falls back to
        // a `defaultGap` floor on iPad sheets where there's no home indicator, and rides
        // above the keyboard when search is active.
        let toolBarFollowsSafeArea = toolBar.bottomAnchor.constraint(equalTo: safeAreaLayoutGuide.bottomAnchor)
        toolBarFollowsSafeArea.priority = .defaultHigh
        let toolBarMinMargin = toolBar.bottomAnchor.constraint(lessThanOrEqualTo: bottomAnchor, constant: -defaultGap)

        // iOS 26 Liquid Glass toolbar gets a small breathing gap above the keyboard;
        // a full `defaultGap` pushes it up into the search bar in landscape, but flush
        // looks pinned. Half-gap is the compromise. Pre-26 UIToolbar is opaque and sits
        // flush.
        let keyboardGap: CGFloat = if #available(iOS 26.0, *) { -defaultGap / 2 } else { 0 }
        let toolBarAboveKeyboard = toolBar.bottomAnchor.constraint(lessThanOrEqualTo: keyboardLayoutGuide.topAnchor, constant: keyboardGap)

        // On iOS 26 the toolbar floats over the PDF (PDF reaches the bottom edge); on
        // older iOS it's opaque and the PDF stops at its top.
        let pdfBottom: NSLayoutConstraint = if #available(iOS 26.0, *) {
            pdfPreview.bottomAnchor.constraint(equalTo: parent.bottomAnchor)
        } else {
            pdfPreview.bottomAnchor.constraint(equalTo: toolBar.topAnchor)
        }

        NSLayoutConstraint.activate([
            topAnchor.constraint(equalTo: parent.topAnchor),
            leadingAnchor.constraint(equalTo: parent.leadingAnchor),
            trailingAnchor.constraint(equalTo: parent.trailingAnchor),
            bottomAnchor.constraint(equalTo: parent.bottomAnchor),

            toolBar.leadingAnchor.constraint(equalTo: leadingAnchor),
            toolBar.trailingAnchor.constraint(equalTo: trailingAnchor),
            toolBarFollowsSafeArea,
            toolBarMinMargin,
            toolBarAboveKeyboard,

            pdfBottom,

            // Keep the thumbnail panel under half the PDF's width so it can never
            // dominate the viewport at large Dynamic Type sizes.
            thumbnails.widthAnchor.constraint(lessThanOrEqualTo: pdfPreview.widthAnchor, multiplier: 0.5, constant: -defaultGap * 2),

            markup.canvas.topAnchor.constraint(equalTo: pdfPreview.topAnchor),
            markup.canvas.bottomAnchor.constraint(equalTo: pdfPreview.bottomAnchor),
            markup.canvas.leadingAnchor.constraint(equalTo: pdfPreview.leadingAnchor),
            markup.canvas.trailingAnchor.constraint(equalTo: pdfPreview.trailingAnchor)
        ])
    }

    /// Move to a specific tool. Setting to `.none` dismisses whatever is currently shown.
    func setCurrentTool(to tool: Tool) {
        current = tool
    }

    /// Toggle between `.none` and the given tool.
    func toggle(_ tool: Tool) {
        
        switch current {
            case .none: current = tool
            case tool:  current = .none
            default: break
        }
    }

    /// Dismiss only if the given tool is currently shown.
    func dismiss(_ tool: Tool) {
        
        guard current == tool
            else { return }
        
        current = .none
    }

    /// Drops all annotations (committed + in-flight). Exposed for the markup nav-bar
    /// "Clear" button.
    func clearAnnotations() {

        markup.canvas.drawing = PKDrawing()
        markup.stamps.removeAll()
        pdfPreview.clearModifications()
    }

    /// Refreshes all chrome owned by `Tools` for a freshly-loaded document: resets any
    /// active/in-flight search and markup, and reloads the page thumbnails.
    func reload() {

        resetSearch()
        resetMarkup()
        thumbnails.reload()
    }

    /// Discards markup from the previous document so its stamps don't re-project onto the new
    /// one. Clears the canvas first so exiting markup doesn't bake stale strokes onto the new
    /// document.
    private func resetMarkup() {

        if current == .markup {
            markup.canvas.drawing = PKDrawing()
            setCurrentTool(to: .none)
        }

        clearAnnotations()
    }

    /// Exits markup if it's active, so the `PKToolPicker` observer is removed and the host's
    /// nav-bar items are restored. Called when the screen disappears; safe when not in markup.
    func endMarkup() {

        guard current == .markup
            else { return }

        setCurrentTool(to: .none)
    }

    /// Resets transient search state
    private func resetSearch() {

        if current == .search {
            setCurrentTool(to: .none)
        } else {
            search.pendingSearch?.cancel()
            search.searchGeneration += 1
        }
    }

    // MARK: Setup

    /// Re-creates the toolbar bar-item actions with freshly-resolved SF Symbol images
    /// at the current Dynamic Type size.
    private func configureBarItemActions() {

        shareItem.accessibilityLabel = Strings.share
        shareItem.primaryAction = UIAction(image: Self.toolbarSymbol("square.and.arrow.up")) { [weak self] _ in
            self?.shareDocument()
        }
        
        searchItem.accessibilityLabel = Strings.search
        searchItem.primaryAction = UIAction(image: Self.toolbarSymbol("magnifyingglass")) { [weak self] _ in
            guard let self
                else { return }

            // If search is already active but the user has dismissed the keyboard
            // re-focus the bar rather than dismissing the tool.
            if self.current == .search {
                if self.search.bar.isFirstResponder {
                    self.setCurrentTool(to: .none)
                } else {
                    self.search.bar.becomeFirstResponder()
                }
            } else {
                self.setCurrentTool(to: .search)
            }
        }

        markupItem.accessibilityLabel = Strings.markup
        markupItem.primaryAction = UIAction(image: Self.toolbarSymbol("pencil.tip.crop.circle")) { [weak self] _ in
            self?.setCurrentTool(to: .markup)
        }

        search.prevButton.accessibilityLabel = Strings.previousMatch
        search.prevButton.primaryAction = UIAction(image: Self.toolbarSymbol("chevron.up")) { [weak self] _ in
            self?.stepResult(by: -1)
        }

        search.nextButton.accessibilityLabel = Strings.nextMatch
        search.nextButton.primaryAction = UIAction(image: Self.toolbarSymbol("chevron.down")) { [weak self] _ in
            self?.stepResult(by: +1)
        }
    }

    @objc private func updateToolsEnabledState() {

        let enabled = pdfPreview.document != nil

        shareItem.isEnabled = enabled
        searchItem.isEnabled = enabled
        markupItem.isEnabled = enabled
    }

    @objc private func contentSizeCategoryChanged() {

        configureBarItemActions()
        thumbnails.invalidateIntrinsicContentSize()
    }

    /// SF Symbol image configured to scale with the user's Dynamic Type text size.
    /// `.title3` (20pt baseline) gives a slightly bigger toolbar icon than `.body`.
    private static func toolbarSymbol(_ systemName: String) -> UIImage? {
        UIImage(systemName: systemName, withConfiguration: UIImage.SymbolConfiguration(textStyle: .title3))
    }

    /// Spaces `items` with `.flexibleSpace()` separators. On iOS < 26 wraps in
    /// `.fixedSpace(defaultGap)` padding because pre-Liquid-Glass UIToolbar otherwise
    /// puts items flush against the edges; iOS 26+'s Liquid Glass toolbar already
    /// insets its capsule buttons.
    private func toolBarItems(_ items: [UIBarButtonItem]) -> [UIBarButtonItem] {

        var arranged: [UIBarButtonItem] = []

        for (i, item) in items.enumerated() {
            if i > 0 { arranged.append(.flexibleSpace()) }
            arranged.append(item)
        }

        if #available(iOS 26.0, *) {
            return arranged
        }

        return [.fixedSpace(defaultGap)] + arranged + [.fixedSpace(defaultGap)]
    }

    // MARK: Transitions

    private func animate(current: Tool, _ transition: Transition) {
        
        switch current {
            case .thumbnails: animateThumbnails(transition)
            case .search: animateSearchBar(transition)
            case .markup: animateMarkup(transition)
            case .none: break
        }
    }

    private func animateThumbnails(_ transition: Transition) {
        
        if transition == .in {
            thumbnails.selectCurrentPage()
            thumbnails.scrollToCurrentPage(animated: false)
        }

        UIView.animateRespectingReduceMotion(transition: transition, view: thumbnails, fade: false) {
            self.thumbnails.isShown = transition == .in
        }

        // Once the panel has slid in and settled, move VoiceOver focus to the current page.
        if transition == .in {
            DispatchQueue.main.asyncAfter(deadline: .now() + transition.duration) { [weak self] in
                self?.thumbnails.moveAccessibilityFocusToCurrentPage()
            }
        }
    }

    private func animateSearchBar(_ transition: Transition) {

        switch transition {
            case .in:
                search.bar.becomeFirstResponder()

            case .out:
                // Cancel any pending/in-flight search first so a result can't land during
                // teardown and repopulate the bar after it's been dismissed.
                search.pendingSearch?.cancel()
                search.searchGeneration += 1

                search.bar.resignFirstResponder()
                pdfPreview.highlightedSelections = nil
                toolBar.items = defaultItems
        }

        UIView.animateRespectingReduceMotion(transition: transition, view: search) {
            self.search.isShown = transition == .in
        }
    }

    // MARK: Share

    private func shareDocument() {

        current = .none

        guard let host = toolBar.parentViewController else {
            log.error("Cannot share: toolbar has no host view controller to present from.")
            return
        }

        // Fast path: No changes so share the original file URL immediately.
        guard pdfPreview.hasModifications else {

            guard let url = pdfPreview.document?.url else {
                log.error("Cannot share: no document URL available.")
                return
            }

            presentShareSheet(for: url, host: host, tempURL: nil)
            return
        }

        // Slow path: serialise the modified document off the main thread

        // Guard against tapping share multiple times
        guard !isExporting
            else { return }

        guard let document = pdfPreview.document else {
            log.error("Cannot share: no document available to export.")
            return
        }

        isExporting = true
        shareGeneration += 1
        
        let generation = shareGeneration
        let fallbackURL = document.url

        // Show the spinner only if the export is still running after a short grace delay,
        // so a fast serialization doesn't flash.
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.15) { [weak self] in
            
            guard let self, self.isExporting, self.shareGeneration == generation
                else { return }

            self.pdfPreview.showActivityIndicator()
        }

        exportQueue.async { [weak self] in

            // `dataRepresentation()` + the disk write are the expensive part and are safe
            // off the main thread; presenting the share sheet is not, so that hops back.
            let tempURL = document.writeToTempFile()

            DispatchQueue.main.async {

                // Bail early if there are newer exporting tasks
                guard let self, self.shareGeneration == generation else {
                    
                    // The temp file was already written, so delete it to ensure we clean up
                    if let tempURL {
                        try? FileManager.default.removeItem(at: tempURL)
                    }
                    
                    return
                }

                self.isExporting = false
                self.pdfPreview.hideActivityIndicator()

                guard let url = tempURL ?? fallbackURL else {
                    log.error("Cannot share: export failed and no original URL available.")
                    return
                }

                self.presentShareSheet(for: url, host: host, tempURL: tempURL)
            }
        }
    }
    
    private func presentShareSheet(for url: URL, host: UIViewController, tempURL: URL?) {

        let activity = UIActivityViewController(activityItems: [url], applicationActivities: nil)
        activity.popoverPresentationController?.barButtonItem = shareItem

        if let tempURL {
            activity.completionWithItemsHandler = { _, _, _, _ in
                try? FileManager.default.removeItem(at: tempURL)
            }
        }

        host.present(activity, animated: true)
    }

    // MARK: Search behaviour

    private func stepResult(by delta: Int) {
        
        guard !search.results.isEmpty
            else { return }
        
        search.index = (search.index + delta + search.results.count) % search.results.count
        focusOnCurrentResult()
    }

    private func focusOnCurrentResult() {
        
        guard search.results.indices.contains(search.index)
            else { return }

        let selection = search.results[search.index]

        pdfPreview.setCurrentSelection(selection, animate: true)
        pdfPreview.reveal(selection)

        search.resultsLabel.text = Strings.searchPosition(search.index + 1, of: search.results.count)
        
        let position = Strings.matchAnnouncement(search.index + 1, of: search.results.count)
        search.prevButton.accessibilityValue = position
        search.nextButton.accessibilityValue = position
    }

    /// Debounce entry point for live-typed queries. Cancels any pending search, clears
    /// immediately on an empty query, otherwise schedules `performSearch` after a short
    /// delay so we don't kick off a find on every keystroke.
    private func scheduleSearch(_ text: String) {

        search.pendingSearch?.cancel()

        if text.isEmpty {
            clearSearch()
            return
        }

        let workItem = DispatchWorkItem { [weak self] in
            self?.performSearch(text)
        }

        search.pendingSearch = workItem

        DispatchQueue.main.asyncAfter(deadline: .now() + 0.25, execute: workItem)
    }

    /// Clears all search state and restores the default toolbar. Bumps the generation so
    /// an in-flight background search from a prior query can't land and repopulate.
    private func clearSearch() {

        search.searchGeneration += 1
        
        search.results = []
        search.resultsLabel.text = ""
        search.prevButton.accessibilityValue = nil
        search.nextButton.accessibilityValue = nil
        
        pdfPreview.highlightedSelections = nil
        
        toolBar.items = defaultItems
    }

    /// Runs `findString` off the main thread, then applies the results on the main thread
    /// if this search hasn't been superseded by a newer one.
    private func performSearch(_ text: String) {

        guard let document = pdfPreview.document
            else { return }

        search.searchGeneration += 1
        let generation = search.searchGeneration

        searchQueue.async { [weak self] in

            let matches = document.findString(text, withOptions: .caseInsensitive)

            DispatchQueue.main.async {

                guard let self, self.search.searchGeneration == generation else {
                    // A newer search (or a teardown) superseded this one; discard.
                    return
                }

                self.applyResults(matches)
            }
        }
    }

    /// Applies a finished search's results to the UI. Runs on the main thread.
    private func applyResults(_ matches: [PDFSelection]) {

        search.index = 0
        search.results = matches

        pdfPreview.highlightedSelections = matches

        if matches.isEmpty {
            search.resultsLabel.text = Strings.noResults
            search.prevButton.accessibilityValue = nil
            search.nextButton.accessibilityValue = nil
        } else {
            focusOnCurrentResult()
        }

        toolBar.items = toolBarItems([search.prevButton, search.resultsItem, search.nextButton])

        search.prevButton.isEnabled = matches.count > 1
        search.nextButton.isEnabled = matches.count > 1
        
        UIAccessibility.announce(Strings.searchResultsAnnouncement(matches.count))
    }

    // MARK: Markup behaviour

    private func animateMarkup(_ transition: Transition) {
        
        switch transition {
            
            case .in:
                // Only reload + re-project when there are previously-committed strokes
                // to restore. First-time markup has nothing baked, so skipping avoids
                // an unnecessary document swap.
                if !markup.stamps.isEmpty {
                    pdfPreview.clearModifications()
                    markup.canvas.drawing = canvasDrawingFromStamps()
                }

                markup.canvas.isHidden = false
                pdfPreview.isScrollEnabled = false

                if markup.toolPicker == nil {
                    markup.toolPicker = PKToolPicker()
                }

                // PKToolPicker manages its own slide-in. Become first responder first
                // so the picker can find its anchor before it appears. Under Reduce
                // Motion, suppress the slide (`performWithoutAnimation`) and fade the
                // private `PKPaletteHostView` instead.
                markup.toolPicker?.addObserver(markup.canvas)
                markup.canvas.becomeFirstResponder()
                if UIAccessibility.isReduceMotionEnabled {
                    UIView.performWithoutAnimation {
                        markup.toolPicker?.setVisible(true, forFirstResponder: markup.canvas)
                    }
                    if let paletteHost = paletteHostView() {
                        paletteHost.alpha = 0
                        UIView.animate(withDuration: 0.25) { paletteHost.alpha = 1 }
                    }
                } else {
                    markup.toolPicker?.setVisible(true, forFirstResponder: markup.canvas)
                }

                toolBar.isHidden = true
                let doneItem = installMarkupNavItems()
            
                if let doneItem {
                    UIAccessibility.announce(Strings.markupModeEntered, thenFocus: doneItem)
                }

            case .out:

                bakeStrokesIntoAnnotations()
                
                pdfPreview.isScrollEnabled = true
                toolBar.isHidden = false
                restoreNavItems()

                if UIAccessibility.isReduceMotionEnabled, let paletteHost = paletteHostView() {

                    // Defer the hide / setVisible(false) until after the alpha fade,
                    // otherwise resigning first responder mid-fade makes PKToolPicker
                    // slide away natively. Wrap the commit in `performWithoutAnimation`
                    // to suppress the slide-out as well.
                    UIView.animate(withDuration: 0.25, animations: {
                        paletteHost.alpha = 0
                    }, completion: { _ in
                        UIView.performWithoutAnimation { self.hideMarkupToolPicker() }
                        paletteHost.alpha = 1
                    })
                } else {
                    hideMarkupToolPicker()
                }

                UIAccessibility.announce(Strings.markupModeClosed, thenFocus: markupItem)
        }
    }

    /// Tear-down for the markup tool picker, in the order PKToolPicker tolerates:
    /// hide, drop observer, resign FR, hide canvas.
    private func hideMarkupToolPicker() {
        
        markup.toolPicker?.setVisible(false, forFirstResponder: markup.canvas)
        markup.toolPicker?.removeObserver(markup.canvas)
        markup.canvas.resignFirstResponder()
        markup.canvas.isHidden = true
    }

    /// The UIViewController whose nav bar should host the markup Done/Clear items.
    /// Walks the responder chain up from the canvas, preferring the parent VC if the
    /// host is embedded (its nav bar is the visible one).
    private var navTarget: UIViewController? {
        
        let host = markup.canvas.parentViewController
        
        return host?.parent ?? host
    }

    /// Saves the host's current nav items into Markup state and replaces them with
    /// Done/Clear that call back into this Tools instance. Returns the Done item so the
    /// caller can move VoiceOver focus to it.
    @discardableResult
    private func installMarkupNavItems() -> UIBarButtonItem? {

        guard let target = navTarget else {
            log.warning("Entering markup but no nav target found — Done/Clear buttons won't be installed.")
            return nil
        }

        markup.previousRightBarButton = target.navigationItem.rightBarButtonItem
        markup.previousLeftBarButton  = target.navigationItem.leftBarButtonItem

        let doneItem = UIBarButtonItem(
            systemItem: .done,
            primaryAction: UIAction { [weak self] _ in self?.setCurrentTool(to: .none) }
        )
        
        target.navigationItem.rightBarButtonItem = doneItem

        let clearItem = UIBarButtonItem(
            primaryAction: UIAction(image: UIImage(systemName: "trash")) { [weak self] _ in
                self?.clearAnnotations()
            }
        )
        
        clearItem.accessibilityLabel = Strings.clearAnnotations

        target.navigationItem.leftBarButtonItem = clearItem

        return doneItem
    }

    private func restoreNavItems() {

        guard let target = navTarget else {
            log.warning("Exiting markup but no nav target found — previous nav items won't be restored.")
            return
        }

        target.navigationItem.rightBarButtonItem = markup.previousRightBarButton
        target.navigationItem.leftBarButtonItem  = markup.previousLeftBarButton

        markup.previousRightBarButton = nil
        markup.previousLeftBarButton  = nil
    }

    /// Rasterize each PKStroke and attach it to its page as a custom stamp annotation.
    /// Coordinate conversions go through the currently-displayed (pristine) pages, then
    /// the stamp is added to the same page index on the freshly-copied `modified`.
    private func bakeStrokesIntoAnnotations() {

        let drawing = markup.canvas.drawing

        guard !drawing.strokes.isEmpty
            else { return }

        guard let displayed = pdfPreview.document else {
            log.error("Cannot bake \(drawing.strokes.count) markup strokes: no PDF document loaded.")
            return
        }

        var newStamps: [Markup.Stamp] = []

        pdfPreview.applyModifications { modified in

            for stroke in drawing.strokes {

                guard let displayedPage = pdfPreview.page(for: stroke.renderBounds.center, nearest: true) else {
                    log.warning("Dropping a markup stroke: no PDF page found at its render centre.")
                    continue
                }

                let pageIndex = displayed.index(for: displayedPage)

                // `index(for:)` returns NSNotFound if the page isn't in `displayed`; never use
                // that as an Int index.
                guard pageIndex != NSNotFound else {
                    log.warning("Dropping a markup stroke: its page is not in the displayed document.")
                    continue
                }

                guard let modifiedPage = modified.page(at: pageIndex) else {
                    log.warning("Dropping a markup stroke: page \(pageIndex) missing from modified document copy.")
                    continue
                }

                // Rasterise with a small inset so anti-aliased edges aren't clipped.
                let renderRect = stroke.renderBounds.insetBy(dx: -4, dy: -4)
                let image = PKDrawing(strokes: [stroke]).image(from: renderRect, scale: pdfPreview.renderScale)
                let pageBounds = pdfPreview.convert(renderRect, to: displayedPage)
                modifiedPage.addAnnotation(Markup.Stamp.Annotation(image: image, bounds: pageBounds))

                newStamps.append(Markup.Stamp(
                    stroke: stroke,
                    pageIndex: pageIndex,
                    anchorOnPage: pdfPreview.convert(stroke.renderBounds.center, to: displayedPage),
                    pdfScaleAtCommit: pdfPreview.scaleFactor
                ))
            }
        }

        markup.stamps = newStamps
        markup.canvas.drawing = PKDrawing()
    }

    /// Builds a PKDrawing for the canvas by translating each baked stamp's stroke so
    /// its stored page-coord anchor lines up with the page's current on-screen position.
    private func canvasDrawingFromStamps() -> PKDrawing {

        // Stamp anchors reference pages from the displayed document.
        guard let document = pdfPreview.document else {
            log.error("Cannot re-project \(self.markup.stamps.count) stamps: no document loaded.")
            return PKDrawing()
        }

        let strokes = markup.stamps.compactMap { stamp -> PKStroke? in
            
            guard stamp.pageIndex < document.pageCount,
                  let page = document.page(at: stamp.pageIndex)
            else {
                log.warning("Dropping a stamp: page index \(stamp.pageIndex) out of bounds for the loaded document (\(document.pageCount) pages).")
                return nil
            }

            let targetCenter = pdfPreview.convert(stamp.anchorOnPage, from: page)
            let currentCenter = stamp.stroke.renderBounds.center
            let scale = pdfPreview.scaleFactor / stamp.pdfScaleAtCommit
            let adjust = CGAffineTransform.identity
                .translatedBy(x: targetCenter.x, y: targetCenter.y)
                .scaledBy(x: scale, y: scale)
                .translatedBy(x: -currentCenter.x, y: -currentCenter.y)

            var translated = stamp.stroke
            translated.transform = stamp.stroke.transform.concatenating(adjust)
            
            return translated
        }

        return PKDrawing(strokes: strokes)
    }

    /// PKToolPicker's palette lives in a side window (`UITextEffectsWindow`) as a view
    /// whose class is `PKPaletteHostView`. We reach for it by class-name walk so we
    /// can fade its alpha under Reduce Motion (PKToolPicker exposes no view API).
    private func paletteHostView() -> UIView? {
        UIApplication.shared.connectedScenes
            .compactMap { $0 as? UIWindowScene }
            .flatMap(\.windows)
            .lazy
            .compactMap { $0.firstSubview(matchingClassNamed: "PKPaletteHostView") }
            .first
    }
}

extension Tools: UISearchBarDelegate {
    
    func searchBar(_ searchBar: UISearchBar, textDidChange searchText: String) {
        scheduleSearch(searchText)
    }
    
    func searchBarSearchButtonClicked(_ searchBar: UISearchBar) {
        
        // Cycle to the next match (wraps via `stepResult`) so the user can repeat-press
        // Return to walk results without leaving the keyboard.
        stepResult(by: +1)
    }

    func searchBarCancelButtonClicked(_ searchBar: UISearchBar) {
        current = .none
    }
}

// MARK: - Search

/// Container for the search bar plus the in-flight result state and the stepper bar
/// buttons that get swapped into the toolbar while a search is active. As a `UIView`
/// it owns the slide-in animation directly (top constraint and alpha on self).
private final class Search: UIView {

    // MARK: Public properties

    let bar: UISearchBar
    let prevButton = UIBarButtonItem()
    let nextButton = UIBarButtonItem()
    
    let resultsLabel = UILabel()
    let resultsItem: UIBarButtonItem

    var results: [PDFSelection] = []
    var index = 0

    /// Pending debounced search, cancelled when a new keystroke arrives or search closes.
    var pendingSearch: DispatchWorkItem?

    /// Bumped per search so a background `findString` finishing after a newer query (or
    /// after the search tool closed) can be discarded instead of applied.
    var searchGeneration = 0

    /// Drives the slide and fade. Wrap the assignment in `UIView.animate` to animate
    /// both. Setting to `false` also clears the bar text and result state. First-responder
    /// handling stays in the caller so the keyboard dismiss can be sequenced before the
    /// slide-up animation (otherwise the keyboard tears the transform mid-flight).
    var isShown: Bool = false {
        didSet {
            
            hiddenConstraint.isActive = !isShown
            shownConstraint.isActive = isShown

            if !isShown {
                bar.text = nil
                results = []
            }
        }
    }

    // MARK: Private properties

    /// Active when the search bar is visible: top pinned to the safe-area top so the
    /// bar sits just below the status bar.
    private var shownConstraint: NSLayoutConstraint!

    /// Active when the bar is hidden: bottom pinned to the safe-area top so the bar
    /// sits entirely above the visible viewport (its full height above the top edge).
    private var hiddenConstraint: NSLayoutConstraint!

    // MARK: Init

    init() {
        
        let bar = UISearchBar()
        bar.placeholder = Strings.searchPlaceholder
        bar.showsCancelButton = true

        // iOS 26 Liquid Glass already provides background; on older versions keep the
        // opaque bar so it's not floating over the PDF without contrast.
        if #available(iOS 26.0, *) {
            bar.searchBarStyle = .minimal
        }

        bar.translatesAutoresizingMaskIntoConstraints = false
        self.bar = bar

        resultsLabel.translatesAutoresizingMaskIntoConstraints = false
        resultsLabel.font = .preferredFont(forTextStyle: .body)
        resultsLabel.adjustsFontForContentSizeCategory = true
        resultsLabel.textColor = .label

        // Wrap the label in a container pinned with inset constraints for left/right padding.
        // Autolayout derives the container's size from the label's intrinsic size plus the
        // insets, so the toolbar item grows to fit the text as it changes.
        let resultsContainer = UIView()
        resultsContainer.addSubview(resultsLabel)
        
        NSLayoutConstraint.activate([
            resultsLabel.topAnchor.constraint(equalTo: resultsContainer.topAnchor),
            resultsLabel.bottomAnchor.constraint(equalTo: resultsContainer.bottomAnchor),
            resultsLabel.leadingAnchor.constraint(equalTo: resultsContainer.leadingAnchor, constant: 8),
            resultsLabel.trailingAnchor.constraint(equalTo: resultsContainer.trailingAnchor, constant: -8)
        ])

        resultsItem = UIBarButtonItem(customView: resultsContainer)

        super.init(frame: .zero)

        alpha = 0
        translatesAutoresizingMaskIntoConstraints = false

        addSubview(bar)

        NSLayoutConstraint.activate([
            bar.topAnchor.constraint(equalTo: topAnchor),
            bar.bottomAnchor.constraint(equalTo: bottomAnchor),
            bar.leadingAnchor.constraint(equalTo: leadingAnchor),
            bar.trailingAnchor.constraint(equalTo: trailingAnchor)
        ])
    }

    required init?(coder: NSCoder) { fatalError() }

    // MARK: Public methods

    func install(in parent: UIView) {

        parent.addSubview(self)

        shownConstraint = topAnchor.constraint(equalTo: parent.safeAreaLayoutGuide.topAnchor)
        hiddenConstraint = bottomAnchor.constraint(equalTo: parent.safeAreaLayoutGuide.topAnchor)

        NSLayoutConstraint.activate([
            leadingAnchor.constraint(equalTo: parent.leadingAnchor),
            trailingAnchor.constraint(equalTo: parent.trailingAnchor),
            hiddenConstraint  // start hidden
        ])
    }
}

// MARK: - Markup

/// Bundle of the PencilKit canvas overlay, the tool picker, the nav-bar items we saved
/// to restore on Done, and the per-page stroke history that lets us re-project committed
/// strokes when the user re-enters markup.
private final class Markup {

    // MARK: Public properties

    let canvas: PKCanvasView = {
        
        let canvas = PKCanvasView()
        canvas.backgroundColor = .clear
        canvas.isOpaque = false
        canvas.drawingPolicy = .anyInput
        canvas.isHidden = true
        canvas.translatesAutoresizingMaskIntoConstraints = false
        
        return canvas
    }()

    var toolPicker: PKToolPicker?
    var stamps: [Stamp] = []

    var previousRightBarButton: UIBarButtonItem?
    var previousLeftBarButton: UIBarButtonItem?

    // MARK: Public methods

    /// Adds the canvas to `parent`. The bottom/edge constraints to the PDF view are
    /// wired in the controller's bridging-constraints pass.
    func install(in parent: UIView) {
        parent.addSubview(canvas)
    }
}

// MARK: - Markup.Stamp

extension Markup {
    
    /// A baked stroke plus the page anchor and scale needed to re-project it onto the
    /// canvas when the user re-enters markup.
    struct Stamp {
        let stroke: PKStroke
        let pageIndex: Int
        let anchorOnPage: CGPoint
        let pdfScaleAtCommit: CGFloat
    }
}

// MARK: - Markup.Stamp.Annotation

extension Markup.Stamp {

    /// PDFAnnotation that draws a UIImage inside its bounds. Used to bake the stroke
    /// into the PDF with full visual fidelity (texture, blending, variable width).
    final class Annotation: PDFAnnotation {

        private let image: UIImage

        init(image: UIImage, bounds: CGRect) {
            
            self.image = image
            
            super.init(bounds: bounds, forType: .stamp, withProperties: nil)
        }

        required init?(coder: NSCoder) { fatalError() }

        override func draw(with box: PDFDisplayBox, in context: CGContext) {
            
            guard let cgImage = image.cgImage
                else { return }

            // CGContext.draw(_:in:) handles the image-vs-PDF Y orientation
            // internally, so we draw straight into bounds without a flip.
            context.draw(cgImage, in: bounds)
        }
    }
}

// MARK: - Transition

/// Direction of a chrome animation: `in` reveals, `out` dismisses.
private enum Transition {
    
    case `in`, out

    /// How long the animation should run. Reduce Motion fades benefit from a slightly
    /// slower curve than the regular slide.
    var duration: TimeInterval {
        UIAccessibility.isReduceMotionEnabled ? 0.5 : 0.25
    }
}

// MARK: - PDFView

private extension PDFView {

    /// Zero-based index of the current page, or `nil` if there's no document/current page or
    /// the current page isn't in the document (`index(for:)` returns `NSNotFound`, which must
    /// not be used as an `Int` index).
    var currentPageIndex: Int? {

        guard let document, let current = currentPage
            else { return nil }

        let index = document.index(for: current)

        return index == NSNotFound ? nil : index
    }
}

// MARK: - PDFDocument

private extension PDFDocument {

    /// Shorter alias for `documentURL`, reads naturally at call sites.
    var url: URL? {
        documentURL
    }

    /// Writes the document (including any baked annotations) to a temp file. Used by
    /// the share flow when there's a modified copy to export instead of the original
    /// URL. `.completeFileProtection` encrypts the file at rest while the device is
    /// locked; the caller removes the file via the share sheet's completion handler.
    func writeToTempFile() -> URL? {

        guard let data = dataRepresentation() else {
            log.error("Cannot write document to temp file: dataRepresentation returned nil.")
            return nil
        }
        
        guard let filename = url?.lastPathComponent else {
            log.error("Cannot write document to temp file: no source URL to derive a filename from.")
            return nil
        }

        let tempURL = FileManager.default.temporaryDirectory.appendingPathComponent(filename)

        do {
            try data.write(to: tempURL, options: [.atomic, .completeFileProtection])
            return tempURL
        } catch {
            log.error("Failed to write document to \(tempURL, privacy: .public): \(error.localizedDescription, privacy: .public)")
            return nil
        }
    }
}

// MARK: - PDFSelection

private extension PDFSelection {

    /// Bounds of the selection's first on-page glyph in page coordinates. Walks the
    /// text range because `characterBounds(at:)` occasionally returns off-page rects
    /// for line-edge glyphs, and `bounds(for:)` returns `.null` for matches on pages
    /// PDFView hasn't loaded yet.
    func firstOnPageGlyphBounds(on page: PDFPage, in displayBox: PDFDisplayBox) -> CGRect? {
        
        let range = self.range(at: 0, on: page)
        let pageRect = page.bounds(for: displayBox)
        
        return (0..<range.length).lazy
            .map { page.characterBounds(at: range.location + $0) }
            .first { !$0.isNull && !$0.isInfinite && pageRect.contains($0.center) }
    }
}

// MARK: - PDFAnnotation

private extension PDFAnnotation {
    
    var isLink: Bool {
        type == "Link"
    }
}

// MARK: - UIScrollView

private extension UIScrollView {

    /// Scroll so `target` sits inside the viewport's unobscured region (the area not
    /// covered by `adjustedContentInset`). Three sizing cases: fits → centre; spills
    /// into chrome but fits the full viewport → bottom-align so its bottom edge sits
    /// at the top of the floating chrome; taller than the viewport → top-align so the
    /// user sees its start. Final offset is clamped to the valid scroll range.
    func scrollIntoUnobscuredViewport(for target: CGRect) {
        
        // `adjustedContentInset` includes both our chrome insets and the scrollview's
        // automatic safe-area inset (home indicator); `contentInset` alone misses the
        // safe-area portion.
        let insets = adjustedContentInset
        let viewHeight = bounds.height
        let unobscuredHeight = viewHeight - insets.top - insets.bottom

        let desired: CGFloat
        
        if target.height <= unobscuredHeight {
            desired = target.midY - (insets.top + viewHeight - insets.bottom) / 2
        } else if target.height <= viewHeight {
            desired = target.maxY - viewHeight + insets.bottom
        } else {
            desired = target.minY - insets.top
        }

        let minY = -insets.top
        let maxY = contentSize.height + insets.bottom - viewHeight
        let clamped = min(max(desired, minY), max(minY, maxY))

        guard clamped.isFinite
            else { return }

        UIView.animateRespectingReduceMotion {
            self.contentOffset = CGPoint(x: 0, y: clamped)
        }
    }
}

// MARK: - CGRect

private extension CGRect {

    var center: CGPoint {
        CGPoint(x: midX, y: midY)
    }
}

// MARK: - UIView render scale

private extension UIView {
    
    var renderScale: CGFloat {

        let traitScale = traitCollection.displayScale

        if traitScale > 0 {
            return traitScale
        }

        return window?.windowScene?.screen.scale ?? 2.0
    }
}

// MARK: - UIView view search

private extension UIView {

    /// Breadth-first search for the first descendant of the given type.
    func firstSubview<T: UIView>(ofType type: T.Type) -> T? {
        firstSubview { $0 is T } as? T
    }

    /// Breadth-first search for the first descendant whose class name matches
    /// `className`. Useful for reaching system-managed views (e.g. `PKPaletteHostView`)
    /// that aren't exposed via public API.
    func firstSubview(matchingClassNamed className: String) -> UIView? {
        firstSubview { String(describing: type(of: $0)) == className }
    }

    /// BFS over self's descendant tree, returning the first view that satisfies
    /// `predicate`.
    private func firstSubview(where predicate: (UIView) -> Bool) -> UIView? {
        
        var queue: [UIView] = [self]
        
        while let next = queue.first {
            queue.removeFirst()
            
            if predicate(next) {
                return next
            }
            
            queue.append(contentsOf: next.subviews)
        }
        
        return nil
    }
}

// MARK: - UIView animations

private extension UIView {

    /// Run `animations` inside `UIView.animate`, or via `performWithoutAnimation` when
    /// Reduce Motion is enabled.
    static func animateRespectingReduceMotion(duration: TimeInterval = 0.25, _ animations: @escaping () -> Void) {
        
        if UIAccessibility.isReduceMotionEnabled {
            performWithoutAnimation(animations)
        } else {
            animate(withDuration: duration, animations: animations)
        }
    }

    /// Animate `view` in or out via `transition`. `stateChange` is the closure that
    /// flips the layout state (typically toggling constraint `isActive` flags).
    ///
    /// Normal motion: the slide (from `stateChange` + `layoutIfNeeded`) and the alpha
    /// fade run together inside a single `UIView.animate`.
    ///
    /// Reduce Motion: the layout state snaps instantly (no slide), wrapped in a
    /// `UIView.transition` cross-dissolve on the host. The cross-fade interpolates
    /// between the before/after snapshots, so dependent siblings (e.g. the page
    /// indicator pill anchored to the thumbnails panel) fade through the change
    /// rather than jumping when the constraint commits.
    ///
    /// The layout host (where the cross-fade snapshots and `layoutIfNeeded` cascade)
    /// is `view.superview`, the chrome's immediate container. The PDF view sits
    /// outside that container, so its scroll content isn't included in the snapshot
    /// (no fade artefacts from concurrent scrolling or inset changes).
    ///
    /// - Parameters:
    ///   - transition: `.in` to reveal, `.out` to dismiss. The duration is read from
    ///     `transition.duration` so it varies by motion preference.
    ///   - view: the view whose `alpha` fades and whose constraints `stateChange` flips.
    ///   - stateChange: the layout state change (e.g. toggling `isActive` on the
    ///     shown/hidden constraint pair).
    static func animateRespectingReduceMotion(
        transition: Transition,
        view: UIView,
        fade: Bool = true,
        stateChange: @escaping () -> Void
    ) {
        
        guard let host = view.superview
            else { return }

        guard UIAccessibility.isReduceMotionEnabled else {
            
            if !fade {
                view.alpha = 1
            }
            
            animate(withDuration: transition.duration) {
                stateChange()
                
                if fade {
                    view.alpha = transition == .in ? 1 : 0
                }
                
                host.layoutIfNeeded()
            }
            return
        }

        UIView.transition(with: host,
                          duration: transition.duration,
                          options: [.transitionCrossDissolve, .allowUserInteraction]) {
            
            UIView.performWithoutAnimation {
                
                stateChange()
                
                view.alpha = transition == .in ? 1 : 0
                
                host.layoutIfNeeded()
            }
        }
    }
}

// MARK: - UIResponder

private extension UIResponder {

    /// Walks the responder chain to find the nearest enclosing `UIViewController`.
    var parentViewController: UIViewController? {
        next as? UIViewController ?? next?.parentViewController
    }
}

// MARK: - UIAccessibility

private extension UIAccessibility {

    /// Speaks `message` via VoiceOver, only when it's running.
    static func announce(_ message: String, thenFocus element: Any? = nil) {

        guard isVoiceOverRunning
            else { return }

        if let element {
            post(notification: .layoutChanged, argument: [message, element])
        } else {
            post(notification: .announcement,
                 argument: NSAttributedString(string: message,
                                              attributes: [.accessibilitySpeechQueueAnnouncement: true]))
        }
    }
}

// MARK: - Strings

/// Strings used across the PDFPreviewController.
/// TODO: Think about localisation of strings.
private enum Strings {

    // Control accessibility labels
    static let share = "Share"
    static let search = "Search"
    static let markup = "Markup"
    static let previousMatch = "Previous match"
    static let nextMatch = "Next match"
    static let clearAnnotations = "Clear annotations"
    static let loadingDocument = "Loading document"

    // Search
    static let searchPlaceholder = "Search PDF"
    static let noResults = "No results"
    static func searchPosition(_ index: Int, of count: Int) -> String { "\(index) of \(count)" }

    /// Spoken summary of a finished search (VoiceOver).
    static func searchResultsAnnouncement(_ count: Int) -> String {
        
        switch count {
            case 0:  return noResults
            case 1:  return "1 result"
            default: return "\(count) results" // TODO: stringsdict plural when localised
        }
    }

    /// Spoken position when stepping between matches (VoiceOver).
    static func matchAnnouncement(_ index: Int, of count: Int) -> String { "Match \(index) of \(count)" }

    // Markup mode-change announcements (VoiceOver)
    static let markupModeEntered = "Markup mode"
    static let markupModeClosed = "Markup closed"

    // Pages
    static func pageNumber(_ page: Int) -> String { "Page \(page)" }
    static func pageOfPages(_ page: Int, of total: Int) -> String { "\(page) of \(total)" }
    static func pageAnnouncement(_ page: Int, of total: Int) -> String { "Page \(page) of \(total)" }
}
