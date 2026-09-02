import XCTest
import SwiftUI
import CobrowseSDK
@testable import PBD

/// **What actually reaches the agent.**
///
/// Every other test in this target asks the policy what it would return. This
/// one renders the frame the SDK would transmit and reads its pixels, because
/// the whole of this arc's surprises were cases where the policy answered
/// correctly and the rendered frame disagreed.
///
/// The sentinel is pure green, the only green in either fixture, so "is there
/// green in the frame" is exactly "did this screen reach the agent". Each test
/// captures with no redaction first: if the screen cannot reach the frame at
/// all, a black frame proves nothing.
@MainActor
final class TransmittedFrameTests: XCTestCase {

    private var window: UIWindow!

    override func setUp() {
        super.setUp()
        CBIOSelectorIndex.redacted.selectors = []
        CBIOSelectorIndex.unredacted.selectors = []
        let scene = UIApplication.shared.connectedScenes
            .compactMap { $0 as? UIWindowScene }
            .first!
        window = UIWindow(windowScene: scene)
        window.frame = UIScreen.main.bounds
    }

    override func tearDown() {
        // Process-global, so a leftover set would follow this suite into the next.
        CBIOSelectorIndex.redacted.selectors = []
        CBIOSelectorIndex.unredacted.selectors = []
        window?.isHidden = true
        window = nil
        super.tearDown()
    }

    /// The plant landing, and the render sentinel for everything below.
    func testAScreenReachesTheFrameWhenNothingIsRedacted() throws {
        let frame = try capture(GreenScreen(), policy: nil)
        XCTAssertTrue(frame.containsGreen,
                      "the fixture did not reach the transmitted frame with no policy at all, so "
                      + "the fixture or the oracle is broken, not the policy")
    }

    /// An unapproved screen: covered, and the cover survives into the frame.
    func testAnUnapprovedScreenIsBlackInTheFrame() throws {
        XCTAssertTrue(try capture(GreenScreen(), policy: nil).containsGreen, "precondition")

        let frame = try capture(GreenScreen(), policy: RedactByDefaultDelegate())
        XCTAssertFalse(frame.containsGreen,
                       "an unapproved screen reached the agent")
    }

    /// An approved screen: revealed, and the reveal survives into the frame.
    /// The pair is what makes either half mean anything. Same fixture shape,
    /// same policy, one line of `Approvals.swift` between them.
    func testAnApprovedScreenIsVisibleInTheFrame() throws {
        let frame = try capture(ApprovedGreenScreen(), policy: RedactByDefaultDelegate())
        XCTAssertTrue(frame.containsGreen,
                      "an approved screen was hidden from the agent")
    }

    // MARK: - a choice shows its live branch

    /// **A `switch` hosted directly shows its approved branch and hides its
    /// unapproved one, through the frame.** The choice-reveals-live-branch
    /// rule, asked of the transmitted pixels rather than of the returned
    /// array. Hosted directly, not pushed, so the frame renders reliably;
    /// `ChoiceStalenessTests` covers the pushed shape's hiding direction and
    /// the value's freshness while it flips.
    func testAChoiceShowsItsApprovedBranchAndHidesItsUnapprovedOne() throws {
        XCTAssertTrue(try capture(hostedChoice(showsApproved: true), policy: nil).containsGreen,
                      "precondition: the approved branch renders")
        XCTAssertTrue(try capture(hostedChoice(showsApproved: false), policy: nil).containsGreen,
                      "precondition: the unapproved branch renders (also green, so 'green' means 'reached')")

        XCTAssertTrue(try capture(hostedChoice(showsApproved: true), policy: RedactByDefaultDelegate()).containsGreen,
                      "the approved branch was hidden from the agent")
        XCTAssertFalse(try capture(hostedChoice(showsApproved: false), policy: RedactByDefaultDelegate()).containsGreen,
                       "the unapproved branch reached the agent")
    }

    /// The choice, hosted as `@ViewBuilder` hands it back: the hosted value IS
    /// the `_ConditionalContent`. Wrapping it in a named view of ours would be
    /// refused at that view, because the walk never enters a developer's own
    /// view, which is a different rule and a different test.
    @ViewBuilder private func hostedChoice(showsApproved: Bool) -> some View {
        if showsApproved { ApprovedGreenBranchScreen() } else { UnapprovedGreenBranchScreen() }
    }

    // MARK: - content drawn beside a container

    /// An unapproved view's content must not reach the agent, including the
    /// part it draws beside a container.
    ///
    /// Stated as the requirement rather than as the behaviour, so it holds
    /// whichever way the cover side is written. The per-screen policy fails it:
    /// it never covers a container's own view, so a bar drawn there is covered
    /// by nothing. A window blanket passes it, because the blanket is above the
    /// bar and nothing on an unapproved view lifts it.
    func testAnUnapprovedViewsBarDoesNotReachTheAgent() throws {
        XCTAssertTrue(try capture(UnapprovedBarBesideContainerScreen(), policy: nil).containsGreen,
                      "precondition: the bar renders at all")

        XCTAssertFalse(
            try capture(UnapprovedBarBesideContainerScreen(), policy: RedactByDefaultDelegate()).containsGreen,
            "an unapproved view's bar reached the agent")
    }

    /// On an approved view the same bar stays visible, from iOS 26.
    ///
    /// Revealing the view is what defeats every arrangement. The SDK moves a
    /// redaction that contains an unredaction towards the leaves and redacts
    /// the sibling views along the path, and the bar is a `CALayer` with no
    /// backing view for that to land on. `.cobrowseRedacted()` on the bar
    /// gives it one, which is the fix an app applies.
    ///
    /// Measured on iOS 18.6, where the bar is covered, and on 26.5 and 27.0,
    /// where it is not. So this is iOS 26-era behaviour rather than the SDK
    /// alone. The guard says 26.0 because that is where the behaviour is
    /// assumed to start; 26.0 to 26.4 has not been measured.
    ///
    /// Asserted as it currently behaves, so a change in either direction is
    /// noticed.
    func testContentBesideAContainerIsVisibleFromIOS26() throws {
        XCTAssertTrue(try capture(BarBesideContainerScreen(), policy: nil).containsGreen,
                      "precondition: the bar renders at all")

        let reachesAgent = try capture(BarBesideContainerScreen(),
                                       policy: RedactByDefaultDelegate()).containsGreen

        if #available(iOS 26, *) {
            XCTAssertTrue(
                reachesAgent,
                "the bar is now covered on an approved view. If the SDK has changed relocation, "
                + "delete this test and the README entry with it")
        } else {
            XCTAssertFalse(
                reachesAgent,
                "the bar is visible below iOS 26 too, so this reaches further than measured")
        }
    }

    /// The remedy, proven in this app rather than only in the SDK's suite: the
    /// SwiftUI modifier materialises a real `UIView` over the bar, and a leaf
    /// view is never an ancestor of the unredaction, so relocation leaves it
    /// standing.
    func testTheModifierHoldsTheBarOnAnApprovedScreen() throws {
        let frame = try capture(RedactedBarBesideContainerScreen(), policy: RedactByDefaultDelegate())
        XCTAssertFalse(frame.containsGreen,
                       "cobrowseRedacted() did not hold the bar")
    }

    // MARK: - swapped tabs
    //
    // ⚠ NO FRAME-LEVEL ARM YET, DELIBERATELY. A swapped tab reveals an
    // unapproved screen at POLICY level — measured identically in the app's
    // own demo and in `SwappedTabsScreen`, see `ScreenIdentificationTests` —
    // but a frame arm built for it did NOT show the sentinel, with the leaf
    // registered and its view loaded. Policy and frame disagree and the reason
    // is not known. A passing frame test here would be a vacuous pass, so
    // there is none until the disagreement is explained.

    // MARK: - the app's own selector list

    /// **Can the app's `unredactedViews` class list lift a screen's own cover?**
    ///
    /// `AppDelegate` names `FloatingBarContainerView` and five other chrome
    /// classes there, to stop system chrome going black. An unredaction
    /// projects to the ROOT and a redaction containing one is relocated towards
    /// the leaves, so a class-name unredaction *inside* a screen would lift
    /// that screen's cover, approved or not. The screen here is unapproved and
    /// is a leaf, so its own view is the thing covered.
    func testTheAppsUnredactedClassListDoesNotLiftAScreensCover() throws {
        XCTAssertFalse(try capture(GreenScreen(), policy: RedactByDefaultDelegate()).containsGreen,
                       "baseline: an unapproved leaf is covered")

        applyTheAppsUnredactedSelectors()

        XCTAssertFalse(try capture(GreenScreen(), policy: RedactByDefaultDelegate()).containsGreen,
                       "the app's unredactedViews list lifted an unapproved screen's cover")
    }

    /// The list exactly as `AppDelegate` sets it.
    private func applyTheAppsUnredactedSelectors() {
        CBIOSelectorIndex.unredacted.selectors = Set(
            [
                "UIEditingOverlayGestureView",
                "FloatingBarContainerView",
                "_UIFloatingBarContainerView",
                "_UIRoundedRectShadowView",
                "_UIPopoverDimmingView",
                "_UIPopoverShapeLayerChromeView"
            ]
            .map { CBIOSelector(parts: [CBIOSelectorPart(tag: $0, attributes: [:])]) }
        )
    }

    // MARK: - driving the SDK

    /// Answers with the policy where there is one, and with nothing where there
    /// is not, so the uncovered arm runs the same capture path as the others.
    private final class CaptureDelegate: NSObject, CBIOUIKitRedactionDelegate, CBIOUIKitFrameSourceDelegate {

        let window: UIWindow
        let policy: RedactByDefaultDelegate?

        init(window: UIWindow, policy: RedactByDefaultDelegate?) {
            self.window = window
            self.policy = policy
        }

        func redactedViews(for viewController: UIViewController) -> [UIView] {
            policy?.cobrowseRedactedViews(for: viewController) ?? []
        }

        func unredactedViews(for viewController: UIViewController) -> [UIView] {
            policy?.cobrowseUnredactedViews(for: viewController) ?? []
        }

        func shouldCapture(_ window: UIWindow) -> Bool { window === self.window }
    }

    private enum CaptureError: Error { case noFrame }

    private func capture(_ screen: some View, policy: RedactByDefaultDelegate?) throws -> CGImage {

        let controller = UIHostingController(rootView: screen)
        window.rootViewController = controller
        window.makeKeyAndVisible()
        controller.view.layoutIfNeeded()

        let delegate = CaptureDelegate(window: window, policy: policy)
        let redaction = CBIOUIKitRedaction(delegate: delegate, webViewRedaction: nil)
        let frameSource = CBIOUIKitFrameSource(delegate: delegate, redaction: redaction)

        // ⚠ SwiftUI builds a container's children LAZILY, so a tab or stack
        // controller does not exist yet at layout time. Collecting the tracked
        // set here without settling registers only the root, the SDK never
        // asks about the leaf, the blanket stands, and the frame comes back
        // black — which reads exactly like a policy that covered everything.
        // A leak inside a tab was invisible to this instrument until this ran.
        let settle = Date(timeIntervalSinceNow: 0.5)
        while settle.timeIntervalSinceNow > 0 {
            RunLoop.current.run(until: Date(timeIntervalSinceNow: 0.02))
        }
        allControllers(from: controller).forEach { $0.loadViewIfNeeded() }

        // Every controller, the way the SDK tracks them live. Registering only
        // the root leaves the children unasked, which is not the shape the
        // policy runs in.
        let tracked = allControllers(from: controller)
        tracked.forEach { redaction.register($0) }
        redaction.show()

        frameSource.capturingWillStart()

        let deadline = Date(timeIntervalSinceNow: 2)
        while !frameSource.isNewFrameAvailable() && deadline.timeIntervalSinceNow > 0 {
            RunLoop.current.run(until: Date(timeIntervalSinceNow: 0.01))
        }

        guard let frame = frameSource.newFrame(1), let image = frame.cgImage else {
            throw CaptureError.noFrame
        }

        redaction.hide()
        frameSource.capturingWillStop()
        tracked.forEach { redaction.unregisterViewController($0) }

        return image
    }

    private func allControllers(from root: UIViewController) -> [UIViewController] {
        [root] + root.children.flatMap { allControllers(from: $0) }
    }
}

/// The sentinel screens. Pure green rather than `Color.green`, whose blue
/// channel is high enough to read as something else.
struct GreenScreen: View {
    var body: some View { Color(red: 0, green: 1, blue: 0).ignoresSafeArea() }
}

struct ApprovedGreenScreen: View {
    var body: some View { Color(red: 0, green: 1, blue: 0).ignoresSafeArea() }
}

extension ApprovedGreenScreen: ApprovedForCobrowse {}

/// An approved screen with a bar drawn around its container, the shape a
/// balance bar, banner or mini-player is normally written in.
struct BarBesideContainerScreen: View {
    var body: some View {
        NavigationStack { Color.blue.ignoresSafeArea() }
            .safeAreaInset(edge: .top) { bar }
    }

    @ViewBuilder var bar: some View {
        Color(red: 0, green: 1, blue: 0).frame(height: 60)
    }
}

/// The same screen with the SDK's own modifier on the bar.
struct RedactedBarBesideContainerScreen: View {
    var body: some View {
        NavigationStack { Color.blue.ignoresSafeArea() }
            .safeAreaInset(edge: .top) {
                Color(red: 0, green: 1, blue: 0).frame(height: 60).cobrowseRedacted()
            }
    }
}

/// The same shape, never approved, so a leak here cannot be blamed on a reveal.
struct UnapprovedBarBesideContainerScreen: View {
    var body: some View {
        NavigationStack { Color.blue.ignoresSafeArea() }
            .safeAreaInset(edge: .top) { Color(red: 0, green: 1, blue: 0).frame(height: 60) }
    }
}

extension BarBesideContainerScreen: ApprovedForCobrowse {}
extension RedactedBarBesideContainerScreen: ApprovedForCobrowse {}

/// Two mutually exclusive tabs plus one always-present tab, inside an approved
/// container — the shape a sign-in/sign-out tab swap makes.
struct SwappedTabsScreen: View {

    let signedIn: Bool

    var body: some View {
        TabView {
            if signedIn {
                SwapApprovedScreen()
                    .tabItem { Text("out") }
            }

            if signedIn == false {
                SwapUnapprovedScreen()
                    .tabItem { Text("in") }
            }

            SwapApprovedScreen()
                .tabItem { Text("other") }
        }
    }
}

extension SwappedTabsScreen: ApprovedForCobrowse {}

/// ⚠ **Each screen OWNS its `NavigationStack`, as every screen in this app
/// does, and that is load-bearing for the leak.** A screen placed *inside* a
/// stack is named by the stack's root controller and refused outright, so no
/// borrow happens and no leak appears. A screen whose BODY is the stack puts
/// SwiftUI's own plumbing in that controller, which names nothing, so the root
/// borrows — and that is the route to the wrong authority. A fixture without
/// this detail passes while the app leaks.
struct SwapApprovedScreen: View {
    var body: some View {
        NavigationStack { Color.blue.ignoresSafeArea() }
    }
}

extension SwapApprovedScreen: ApprovedForCobrowse {}

/// The sentinel screen. Never approved, so green in the transmitted frame is a
/// leak by definition.
struct SwapUnapprovedScreen: View {
    var body: some View {
        NavigationStack { Color(red: 0, green: 1, blue: 0).ignoresSafeArea() }
    }
}

private extension CGImage {

    /// Whether any pixel is the sentinel green.
    var containsGreen: Bool {

        let bytesPerRow = width * 4
        var pixels = [UInt8](repeating: 0, count: height * bytesPerRow)

        guard width > 0, height > 0,
              let context = CGContext(
                data: &pixels,
                width: width, height: height,
                bitsPerComponent: 8, bytesPerRow: bytesPerRow,
                space: CGColorSpaceCreateDeviceRGB(),
                bitmapInfo: CGImageAlphaInfo.premultipliedLast.rawValue
              )
        else { return false }

        context.draw(self, in: CGRect(x: 0, y: 0, width: width, height: height))

        for offset in stride(from: 0, to: pixels.count, by: 4) {
            if pixels[offset] <= 80, pixels[offset + 1] >= 180, pixels[offset + 2] <= 80 {
                return true
            }
        }

        return false
    }
}

/// Both branches green, so "green in the frame" reads as "this branch reached
/// the agent" for whichever is live. One type is approved, the other is not.
struct ApprovedGreenBranchScreen: View {
    var body: some View { Color(red: 0, green: 1, blue: 0).ignoresSafeArea() }
}

struct UnapprovedGreenBranchScreen: View {
    var body: some View { Color(red: 0, green: 1, blue: 0).ignoresSafeArea() }
}

extension ApprovedGreenBranchScreen: ApprovedForCobrowse {}
