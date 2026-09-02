import XCTest
import SwiftUI
import CobrowseSDK
@testable import PBD

/// **How does one screen become visible when the policy has redacted everything?**
///
/// This is the mechanism a redact-by-default policy actually runs on, and it is
/// the SDK's, not ours: a redaction that *contains* an unredaction is removed
/// and pushed towards the leaves, and every sibling along the unredaction's
/// ancestral path is redacted in its place. So blanketing the window and then
/// naming one screen leaves that screen visible and everything beside it
/// black, without the policy having to enumerate what "everything else" is.
///
/// Asked of the transmitted frame, because what matters is what reaches the
/// agent rather than what the sets say.
@MainActor
final class BlanketRedactionTests: XCTestCase {

    private var window: UIWindow!

    override func setUp() {
        super.setUp()
        CBIOSelectorIndex.redacted.selectors = []
        CBIOSelectorIndex.unredacted.selectors = []
        let scene = UIApplication.shared.connectedScenes
            .compactMap { $0 as? UIWindowScene }.first!
        window = UIWindow(windowScene: scene)
        window.frame = UIScreen.main.bounds
    }

    override func tearDown() {
        CBIOSelectorIndex.redacted.selectors = []
        CBIOSelectorIndex.unredacted.selectors = []
        window?.isHidden = true
        window = nil
        super.tearDown()
    }

    /// Two screens on show at once, one approved. The blanket covers the whole
    /// window; naming the approved one is the only positive statement made.
    func testABlanketPlusOneUnredactionShowsOnlyThatScreen() throws {
        let container = SideBySideContainer()
        window.rootViewController = container
        window.makeKeyAndVisible()
        container.view.layoutIfNeeded()

        // Control: with no policy at all, both halves reach the frame.
        let plain = try capture(container, redact: { _ in [] }, unredact: { _ in [] })
        XCTAssertTrue(plain.hasGreen, "precondition: the approved half renders")
        XCTAssertTrue(plain.hasRed, "precondition: the unapproved half renders")

        // The blanket, plus one name.
        let governed = try capture(
            container,
            redact: { [weak self] _ in self.map { [$0.window!] } ?? [] },
            unredact: { $0 === container.approved ? [$0.view] : [] }
        )

        XCTAssertTrue(governed.hasGreen, "the approved screen did not come back")
        XCTAssertFalse(governed.hasRed,
                       "the unapproved screen beside it reached the agent, so the relocation did "
                       + "not redact the siblings of the unredaction's path")
    }

    /// The same, with nothing named: the blanket alone must black the lot. If
    /// this ever shows a colour, the assertion above proves nothing.
    func testABlanketAloneBlacksEverything() throws {
        let container = SideBySideContainer()
        window.rootViewController = container
        window.makeKeyAndVisible()
        container.view.layoutIfNeeded()

        let governed = try capture(
            container,
            redact: { [weak self] _ in self.map { [$0.window!] } ?? [] },
            unredact: { _ in [] }
        )

        XCTAssertFalse(governed.hasGreen)
        XCTAssertFalse(governed.hasRed)
    }

    /// **Unredacting the CONTAINER is not the same move, and this is the
    /// difference.** An unredaction shields its whole subtree: a view whose
    /// nearest marked ancestor is unredacted is never redacted, whatever the
    /// blanket said. So lifting the container lifts everything inside it.
    func testUnredactingTheContainerShowsEverythingInsideIt() throws {
        let container = SideBySideContainer()
        window.rootViewController = container
        window.makeKeyAndVisible()
        container.view.layoutIfNeeded()

        let governed = try capture(
            container,
            redact: { [weak self] _ in self.map { [$0.window!] } ?? [] },
            unredact: { $0 === container ? [$0.view] : [] }
        )

        XCTAssertTrue(governed.hasGreen)
        XCTAssertTrue(governed.hasRed,
                      "the unapproved screen is no longer shielded by the unredacted container. "
                      + "If the SDK has changed this, the container rule can be revisited")
    }

    /// **…unless every screen beneath it is EXPLICITLY redacted.** `toRedact`
    /// starts as the whole explicit set and only drops members that are
    /// *ancestors* of an unredaction; a child is a descendant, so its own
    /// redaction survives. This is the arm that makes "blanket, then unredact
    /// the container" a workable design rather than a leak.
    func testAnExplicitRedactionSurvivesAnUnredactedContainer() throws {
        let container = SideBySideContainer()
        window.rootViewController = container
        window.makeKeyAndVisible()
        container.view.layoutIfNeeded()

        let governed = try capture(
            container,
            redact: { [weak self] controller in
                if controller === container.unapproved { return [controller.view] }
                return self.map { [$0.window!] } ?? []
            },
            unredact: { $0 === container ? [$0.view] : [] }
        )

        XCTAssertTrue(governed.hasGreen, "the approved screen should still show")
        XCTAssertFalse(governed.hasRed,
                       "an explicit redaction did not survive an unredacted ancestor")
    }

    // MARK: - fixtures

    /// Two child view controllers on screen at the same time, so "the other
    /// one" is a real sibling rather than a screen a push has already removed.
    final class SideBySideContainer: UIViewController {

        let approved = UIHostingController(rootView: Color(red: 0, green: 1, blue: 0))
        let unapproved = UIHostingController(rootView: Color(red: 1, green: 0, blue: 0))

        override func viewDidLoad() {
            super.viewDidLoad()
            view.backgroundColor = .white
            for (index, child) in [approved, unapproved].enumerated() {
                addChild(child)
                view.addSubview(child.view)
                child.view.translatesAutoresizingMaskIntoConstraints = false
                NSLayoutConstraint.activate([
                    child.view.topAnchor.constraint(equalTo: view.topAnchor),
                    child.view.bottomAnchor.constraint(equalTo: view.bottomAnchor),
                    child.view.leadingAnchor.constraint(
                        equalTo: index == 0 ? view.leadingAnchor : view.centerXAnchor),
                    child.view.trailingAnchor.constraint(
                        equalTo: index == 0 ? view.centerXAnchor : view.trailingAnchor)
                ])
                child.didMove(toParent: self)
            }
        }
    }

    private final class Delegate: NSObject, CBIOUIKitRedactionDelegate, CBIOUIKitFrameSourceDelegate {
        let window: UIWindow
        let redact: (UIViewController) -> [UIView]
        let unredact: (UIViewController) -> [UIView]

        init(window: UIWindow,
             redact: @escaping (UIViewController) -> [UIView],
             unredact: @escaping (UIViewController) -> [UIView]) {
            self.window = window
            self.redact = redact
            self.unredact = unredact
        }

        func redactedViews(for viewController: UIViewController) -> [UIView] { redact(viewController) }
        func unredactedViews(for viewController: UIViewController) -> [UIView] { unredact(viewController) }
        func shouldCapture(_ window: UIWindow) -> Bool { window === self.window }
    }

    private enum CaptureError: Error { case noFrame }

    private struct Capture {
        let hasGreen: Bool
        let hasRed: Bool
    }

    private func capture(
        _ root: UIViewController,
        redact: @escaping (UIViewController) -> [UIView],
        unredact: @escaping (UIViewController) -> [UIView]
    ) throws -> Capture {

        let delegate = Delegate(window: window, redact: redact, unredact: unredact)
        let redaction = CBIOUIKitRedaction(delegate: delegate, webViewRedaction: nil)
        let source = CBIOUIKitFrameSource(delegate: delegate, redaction: redaction)

        let tracked = [root] + root.children
        tracked.forEach { redaction.register($0) }
        redaction.show()
        source.capturingWillStart()

        let deadline = Date(timeIntervalSinceNow: 2)
        while !source.isNewFrameAvailable() && deadline.timeIntervalSinceNow > 0 {
            RunLoop.current.run(until: Date(timeIntervalSinceNow: 0.01))
        }

        guard let frame = source.newFrame(1), let image = frame.cgImage else {
            throw CaptureError.noFrame
        }

        redaction.hide()
        source.capturingWillStop()
        tracked.forEach { redaction.unregisterViewController($0) }

        return Capture(hasGreen: image.has(.green), hasRed: image.has(.red))
    }
}

private enum Channel { case green, red }

private extension CGImage {
    func has(_ channel: Channel) -> Bool {
        let bytesPerRow = width * 4
        var pixels = [UInt8](repeating: 0, count: height * bytesPerRow)
        guard width > 0, height > 0,
              let context = CGContext(data: &pixels, width: width, height: height,
                                      bitsPerComponent: 8, bytesPerRow: bytesPerRow,
                                      space: CGColorSpaceCreateDeviceRGB(),
                                      bitmapInfo: CGImageAlphaInfo.premultipliedLast.rawValue)
        else { return false }
        context.draw(self, in: CGRect(x: 0, y: 0, width: width, height: height))
        for offset in stride(from: 0, to: pixels.count, by: 4) {
            let (r, g, b) = (pixels[offset], pixels[offset + 1], pixels[offset + 2])
            switch channel {
                case .green: if g >= 180, r <= 80, b <= 80 { return true }
                case .red:   if r >= 180, g <= 80, b <= 80 { return true }
            }
        }
        return false
    }
}
