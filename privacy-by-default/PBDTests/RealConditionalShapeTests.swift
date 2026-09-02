import XCTest
import SwiftUI
@testable import PBD

/// **WHEN IS A `rootView` EVER A `_ConditionalContent`? Two ways, both of them
/// what an app really writes.** Measured 2026-09-02, iOS 26.5.
///
/// This exists because the other choice tests host a `_ConditionalContent`
/// DIRECTLY — a shape a test can construct and an app might never — so they
/// could not answer whether the live-branch peel earns its keep on real
/// shapes. These two do.
///
///     WindowGroup { if signedIn { A() } else { B() } }
///       → UIHostingController<_ConditionalContent<A, B>>   the rootView IS one
///
///     .sheet { if x { A() } else { B() } }
///       → PresentationHostingController<AnyView> → peel reaches the conditional
///
/// With `view.in(conditionalContent:)` disabled both go `UNKNOWN`, so the
/// approved screen is hidden and every conditional app-root and conditional
/// sheet turns black. That is what the peel is for.
@MainActor
final class RealConditionalShapeTests: XCTestCase {

    private var window: UIWindow!

    override func setUp() {
        super.setUp()
        let scene = UIApplication.shared.connectedScenes.compactMap { $0 as? UIWindowScene }.first!
        window = UIWindow(windowScene: scene)
        window.frame = UIScreen.main.bounds
    }

    override func tearDown() { window?.isHidden = true; window = nil; super.tearDown() }

    /// A SHEET whose content closure is an if/else — the common real shape.
    /// The presented screen is judged on the branch on display; the presenter
    /// itself is unapproved and stays hidden either way.
    func testASheetWithAConditionalContent() throws {
        let host = UIHostingController(rootView: PresentsAConditionalSheet(showApproved: true))
        window.rootViewController = host
        window.makeKeyAndVisible()
        host.view.layoutIfNeeded()
        settle()

        let approved = report("sheet, approved branch", from: host)
        XCTAssertTrue(approved.contains { $0.isApproved },
                      "the approved branch of a conditional sheet was not identified")

        let other = UIHostingController(rootView: PresentsAConditionalSheet(showApproved: false))
        window.rootViewController = other
        window.makeKeyAndVisible()
        other.view.layoutIfNeeded()
        settle()

        let unapproved = report("sheet, unapproved branch", from: other)
        XCTAssertFalse(unapproved.contains { $0.isApproved },
                       "the unapproved branch of a conditional sheet reached the agent")
    }

    /// An APP ROOT that is an if/else — `WindowGroup { if signedIn { … } }`.
    func testAnAppRootThatIsAConditional() throws {
        let approved = report("app root, approved",
                              from: UIHostingController(rootView: rootChoice(true)), present: true)
        XCTAssertTrue(approved.contains { $0.isApproved },
                      "an app root that is a conditional was not identified on its approved branch")

        let unapproved = report("app root, unapproved",
                                from: UIHostingController(rootView: rootChoice(false)), present: true)
        XCTAssertFalse(unapproved.contains { $0.isApproved },
                       "an app root's unapproved branch reached the agent")
    }

    @ViewBuilder private func rootChoice(_ approved: Bool) -> some View {
        if approved { RealApproved() } else { RealUnapproved() }
    }

    @discardableResult
    private func report(_ label: String, from host: UIViewController, present: Bool = false) -> [Find.Verdict] {
        if present {
            window.rootViewController = host
            window.makeKeyAndVisible()
            host.view.layoutIfNeeded()
            settle()
        }

        var verdicts: [Find.Verdict] = []

        for controller in every(from: host) {
            controller.loadViewIfNeeded()
            guard let hosting = controller as? AnyHostingController else { continue }
            let verdict = controller.cobrowseVerdict
            verdicts.append(verdict)
            print("PBD-PROBE \(label): \(type(of: controller)) hosts=\(hosting.viewType) "
                  + "verdict=\(String(describing: verdict).prefix(70))")
        }

        return verdicts
    }

    private func every(from controller: UIViewController) -> [UIViewController] {
        var found = [controller] + controller.children.flatMap { every(from: $0) }
        if let presented = controller.presentedViewController { found += every(from: presented) }
        return found
    }

    private func settle() {
        let until = Date(timeIntervalSinceNow: 0.8)
        while until.timeIntervalSinceNow > 0 { RunLoop.current.run(until: Date(timeIntervalSinceNow: 0.02)) }
    }
}

struct PresentsAConditionalSheet: View {

    let showApproved: Bool

    @State private var showing = true

    var body: some View {
        Color.clear.sheet(isPresented: $showing) {
            if showApproved { RealApproved() } else { RealUnapproved() }
        }
    }
}

struct RealApproved: View { var body: some View { Text("approved") } }
extension RealApproved: ApprovedForCobrowse {}

struct RealUnapproved: View { var body: some View { Text("unapproved") } }
