import XCTest
import SwiftUI
@testable import PBD

/// **When a `switch` destination flips, does the VALUE agree with the SCREEN?**
///
/// Approving a choice on its live branch is more accurate than requiring every
/// branch to be approved, and it is only safe if the value the policy would
/// read is never ahead of what is rendered. Ahead is the dangerous direction:
/// the value saying "approved" while the unapproved branch is still on screen
/// would reveal it.
///
/// Behind is fine. The value saying "unapproved" while the approved branch has
/// already appeared costs a frame of black.
@MainActor
final class ChoiceStalenessTests: XCTestCase {

    private var window: UIWindow!

    override func setUp() {
        super.setUp()
        let scene = UIApplication.shared.connectedScenes
            .compactMap { $0 as? UIWindowScene }.first!
        window = UIWindow(windowScene: scene)
        window.frame = UIScreen.main.bounds
    }

    override func tearDown() { window?.isHidden = true; window = nil; super.tearDown() }

    func testTheValueIsNeverAheadOfTheScreen() throws {
        let flag = SwitchedBranch()
        let host = UIHostingController(rootView: SwitchesItsDestination(branch: flag))
        window.rootViewController = host
        window.makeKeyAndVisible()
        host.view.layoutIfNeeded()
        RunLoop.current.run(until: Date(timeIntervalSinceNow: 0.6))

        var disagreements = 0
        var comparisons = 0

        for round in 0 ..< 6 {
            flag.showsApproved.toggle()

            // Sample straight after the flip and then as it settles, because a
            // lag of one frame is exactly what this is looking for.
            for sample in 0 ..< 4 {
                RunLoop.current.run(until: Date(timeIntervalSinceNow: 0.02))

                guard let pushed = pushedController(under: host) else { continue }
                let claimed = liveBranch(of: pushed)
                let frame = try AgentFrameOracle.frame(
                    of: window,
                    tracked: AgentFrameOracle.everyController(from: host),
                    policy: nil
                )
                let rendered = try rendering(in: frame)

                guard let claimed, let rendered else { continue }
                comparisons += 1

                if claimed != rendered {
                    disagreements += 1
                    print("PBD-PROBE round \(round) sample \(sample): value says \(claimed), screen shows \(rendered)"
                          + (claimed == .approved ? "   ← AHEAD, the dangerous direction" : "   (behind, safe)"))
                }
            }
        }

        print("PBD-PROBE comparisons: \(comparisons)  disagreements: \(disagreements)")

        // Without this the zero above is vacuous: a reading that always
        // returns nil skips every comparison and reports perfect agreement.
        XCTAssertGreaterThanOrEqual(comparisons, 12,
                                    "too few comparisons were made for the result to mean anything")

        XCTAssertEqual(disagreements, 0,
                       "the value and the screen disagreed; see the log for which direction")
    }

    /// **With the policy on, the unapproved branch never reaches the agent,
    /// whether it is mid-transition or settled.** The test above says the
    /// value is never ahead of the screen; this one asks the transmitted frame
    /// directly, and reads a black frame everywhere the red branch is live.
    ///
    /// Only the hiding direction is asserted here. The approved branch showing
    /// is proven by `TransmittedFrameTests`, on a hosted screen the frame
    /// renders reliably; this fixture pushes through a `.constant(true)`
    /// destination, which the offscreen render leaves black even settled, so
    /// asserting the positive arm here would be testing the fixture, not the
    /// policy.
    func testTheUnapprovedBranchNeverReachesTheAgentWhileItFlips() throws {
        let flag = SwitchedBranch()
        let host = UIHostingController(rootView: SwitchesItsDestination(branch: flag))
        window.rootViewController = host
        window.makeKeyAndVisible()
        host.view.layoutIfNeeded()
        RunLoop.current.run(until: Date(timeIntervalSinceNow: 0.6))

        let policy = RedactByDefaultDelegate()
        var unapprovedOnScreen = 0

        for _ in 0 ..< 6 {
            flag.showsApproved.toggle()

            for _ in 0 ..< 4 {
                RunLoop.current.run(until: Date(timeIntervalSinceNow: 0.02))
                let tracked = AgentFrameOracle.everyController(from: host)

                let plain = try rendering(in: AgentFrameOracle.frame(of: window, tracked: tracked, policy: nil))
                let governed = try rendering(in: AgentFrameOracle.frame(of: window, tracked: tracked, policy: policy))

                XCTAssertNotEqual(governed, .unapproved, "the unapproved branch reached the agent")
                if plain == .unapproved { unapprovedOnScreen += 1 }
            }
        }

        print("PBD-PROBE flips: unapproved on screen \(unapprovedOnScreen), never in the frame")

        // Without this the assertion is vacuous: if the red branch never
        // rendered, nothing was tested.
        XCTAssertGreaterThan(unapprovedOnScreen, 0, "the unapproved branch never showed, so nothing was tested")
    }

    private enum Branch: String { case approved, unapproved }

    /// What the `_ConditionalContent` value says is live, reached the way the
    /// policy would reach it.
    private func liveBranch(of controller: UIViewController) -> Branch? {
        guard let box = (controller as? AnyHostingController)?.anyRootView as? AnyView else { return nil }
        var value: Any = box
        for _ in 0 ..< 10 {
            if value is ApprovedGreenBranch { return .approved }
            if value is UnapprovedRedBranch { return .unapproved }
            let children = Mirror(reflecting: value).children
            let next = children.first { ($0.label ?? "") == "content" } ?? children.first
            guard let next else { return nil }
            value = next.value
        }
        return nil
    }

    /// What is actually on the wire.
    private func rendering(in frame: CGImage) throws -> Branch? {
        let whole = CGRect(x: 0, y: 0, width: frame.width, height: frame.height)
        let pixels = try frame.pixels(in: whole)
        let green = pixels.contains { $0.red <= 80 && $0.green >= 180 && $0.blue <= 80 }
        let red = pixels.contains { $0.red >= 180 && $0.green <= 80 && $0.blue <= 80 }
        if green && !red { return .approved }
        if red && !green { return .unapproved }
        return nil
    }

    private func pushedController(under root: UIViewController) -> UIViewController? {
        for controller in AgentFrameOracle.everyController(from: root) {
            if let navigation = controller as? UINavigationController, navigation.children.count > 1 {
                return navigation.children.last
            }
        }
        return nil
    }
}

final class SwitchedBranch: ObservableObject {
    @Published var showsApproved = true
}

struct ApprovedGreenBranch: View {
    var body: some View { Color(red: 0, green: 1, blue: 0).ignoresSafeArea() }
}

struct UnapprovedRedBranch: View {
    var body: some View { Color(red: 1, green: 0, blue: 0).ignoresSafeArea() }
}

extension ApprovedGreenBranch: ApprovedForCobrowse {}

struct SwitchesItsDestination: View {

    @ObservedObject var branch: SwitchedBranch

    var body: some View {
        NavigationStack {
            Color.white.navigationDestination(isPresented: .constant(true)) { destination }
        }
    }

    @ViewBuilder private var destination: some View {
        if branch.showsApproved { ApprovedGreenBranch() } else { UnapprovedRedBranch() }
    }
}
