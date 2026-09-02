import XCTest
import SwiftUI
@testable import PBD

/// **What the policy costs on the frame loop.**
///
/// `cobrowseUnredactedViews(for:)` is called for every tracked controller on
/// every captured frame, so its cost is per-controller-per-frame and a
/// regression here is a hitch on a live session rather than a slow test.
/// Reading a type's structure is the expensive part, which is why it is read
/// once per name and cached, and this measures that the cache is doing its job.
///
/// The ceilings are deliberately loose: they are there to catch a lost cache or
/// an accidental parse per frame, not to police a few nanoseconds. The measured
/// value is printed on every run, so the trend is visible even while the gate
/// stays quiet.
@MainActor
final class ScreenIdentificationPerformanceTests: XCTestCase {

    private var window: UIWindow!
    private let policy = RedactByDefaultDelegate()

    override func setUp() {
        super.setUp()
        let scene = UIApplication.shared.connectedScenes
            .compactMap { $0 as? UIWindowScene }
            .first!
        window = UIWindow(windowScene: scene)
        window.frame = UIScreen.main.bounds
    }

    override func tearDown() {
        window?.isHidden = true
        window = nil
        super.tearDown()
    }

    /// The steady state: the type has been seen before, which after the first
    /// frame of a session is every type.
    func testWarmApprovalCostPerCall() throws {
        let controller = hosted(
            JourneyBView().navigationDestination(item: .constant(SavedCard?.none)) { _ in JourneyAView() }
        )

        // Prime the caches, and prove the answer is the one we are timing.
        // Timing a refusal that returns on its first guard would measure
        // nothing.
        XCTAssertTrue(policy.cobrowseUnredactedViews(for: controller).isEmpty == false,
                      "the timed call must be the approving path, not an early refusal")

        let iterations = 20_000
        let start = DispatchTime.now().uptimeNanoseconds
        for _ in 0 ..< iterations {
            _ = policy.cobrowseUnredactedViews(for: controller)
        }
        let perCall = Double(DispatchTime.now().uptimeNanoseconds - start) / Double(iterations)

        print("PBD-PROBE warm approval: \(Int(perCall)) ns/call over \(iterations) calls")

        // On the iPhone 17 Pro simulator, iOS 26.5: ~1,043 ns/call in Release
        // and ~1,421 in Debug. The two agree, so the cost is runtime work
        // rather than anything the optimiser touches. The ceiling is ~4× the
        // slower of them, which leaves room for a loaded
        // machine while still catching a lost cache by three orders of
        // magnitude: the first uncached resolution in a process costs ~7 ms.
        XCTAssertLessThan(perCall, 6_000,
                          "approval cost per call has regressed. A lost cache would show here first")
    }

    /// The one-off, printed rather than gated.
    ///
    /// On the iPhone 17 Pro simulator, iOS 26.5, Release and Debug alike: the
    /// first call in a process costs ~7 ms, and every later screen the session
    /// has not shown before costs ~3 µs. The Swift runtime
    /// warms its own metadata lookup on that first call, so the cost is a
    /// launch-time one-off rather than something paid per screen. Worth
    /// keeping printed, because a change in that shape is exactly what would
    /// put a visible pause on a push.
    ///
    /// Two calls, because they measure different things. The first is the first
    /// of the whole process and carries every lazy initialisation with it; the
    /// second is what an app actually pays each time the customer reaches a
    /// screen the session has not shown before.
    ///
    /// The fixtures are the app's own unapproved screens rather than types
    /// declared here: a `private` type in a test file carries a file
    /// discriminator in its name, which never resolves, so timing one would
    /// measure a failed lookup rather than the ordinary path.
    func testColdApprovalCostIsReported() throws {
        // Hosting is outside the timer: building a hosting controller and
        // laying it out costs tens of milliseconds on its own and is not the
        // policy's work.
        let firstController = hosted(ExplainMyBillView())
        let first = time("first cold call in the process") {
            self.policy.cobrowseUnredactedViews(for: firstController)
        }

        let secondController = hosted(CarriedDestinationView())
        let second = time("a later screen, never seen before") {
            self.policy.cobrowseUnredactedViews(for: secondController)
        }

        // For comparison: spelling a type's name, which the module check pays
        // once per type.
        time("  spell the name") { String(reflecting: JourneyAView.self) }


        // That the reader did its work, rather than that these screens are
        // approved: `Approvals.swift` is the app's to change, and a timing test
        // has no business breaking when it does.
        XCTAssertFalse(firstController.cobrowseVerdict.isUnknown, "the first cold call named nothing")
        XCTAssertFalse(secondController.cobrowseVerdict.isUnknown, "the second cold call named nothing")
        _ = (first, second)
    }

    @discardableResult
    private func time<Value>(_ label: String, _ work: () -> Value) -> (value: Value, nanoseconds: UInt64) {
        let start = DispatchTime.now().uptimeNanoseconds
        let value = work()
        let elapsed = DispatchTime.now().uptimeNanoseconds - start
        print("PBD-PROBE \(label): \(elapsed) ns")
        return (value, elapsed)
    }

    private func hosted(_ screen: some View) -> UIViewController {
        let controller = UIHostingController(rootView: screen)
        window.rootViewController = controller
        window.makeKeyAndVisible()
        controller.view.layoutIfNeeded()
        return controller
    }
}
