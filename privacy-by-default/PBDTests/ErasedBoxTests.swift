import XCTest
import SwiftUI
@testable import PBD

/// **The erased box names a pushed destination and does NOT name a stack's
/// root**, and the difference is the whole reason the ancestor fallback exists.
///
/// A destination's `AnyView` wraps the app's own view, so walking into the
/// storage names it. A root's wraps the *content closure's* body,
/// `Tree<_VStackLayout, _VariadicView_Children>` and SwiftUI's navigation
/// plumbing, which names nothing of the app's, so the only identity available
/// is the screen containing the whole stack.
///
/// Asserted rather than printed because the fallback is written as if this
/// were true, and if SwiftUI ever started naming the root in its box the
/// fallback would be dead code nobody noticed.
@MainActor
final class ErasedBoxTests: XCTestCase {

    private var window: UIWindow!

    override func setUp() {
        super.setUp()
        let scene = UIApplication.shared.connectedScenes
            .compactMap { $0 as? UIWindowScene }.first!
        window = UIWindow(windowScene: scene)
        window.frame = UIScreen.main.bounds
    }

    override func tearDown() {
        window?.isHidden = true
        window = nil
        super.tearDown()
    }

    func testTheBoxNamesADestinationButNotTheRoot() throws {
        let (root, destination) = try stackControllers()

        XCTAssertEqual(root.cobrowseVerdict, .approved,
                       "the root should borrow the identity of the approved screen containing the stack")
        XCTAssertTrue(destination.cobrowseVerdict.isRefused,
                      "the destination should name JourneyAView out of its own box, which is unapproved")

        XCTAssertTrue(Find.Verdict.for(try box(of: root)).isUnknown,
                      "the root's box now names an app screen, so the ancestor fallback may be dead code")
        XCTAssertTrue(Find.Verdict.for(try box(of: destination)).isRefused,
                      "the destination's box no longer names its screen, so the walk into the box has stopped working")
    }

    private func box(of controller: UIViewController) throws -> AnyView {
        try XCTUnwrap((controller as? AnyHostingController)?.anyRootView as? AnyView,
                      "\(type(of: controller)) hosts no erased view")
    }

    private func stackControllers() throws -> (root: UIViewController, destination: UIViewController) {
        let host = UIHostingController(rootView: StackWithADestination())
        window.rootViewController = host
        window.makeKeyAndVisible()
        host.view.layoutIfNeeded()
        RunLoop.current.run(until: Date(timeIntervalSinceNow: 0.4))
        host.view.layoutIfNeeded()

        let stack = try XCTUnwrap(navigation(in: host))
        XCTAssertEqual(stack.children.count, 2, "the fixture should have pushed a destination")
        return (stack.children[0], stack.children[1])
    }

    func testPrintWhatTheBoxNames() throws {
        let host = UIHostingController(rootView: StackWithADestination())
        window.rootViewController = host
        window.makeKeyAndVisible()
        host.view.layoutIfNeeded()
        RunLoop.current.run(until: Date(timeIntervalSinceNow: 0.4))
        host.view.layoutIfNeeded()

        let stack = try XCTUnwrap(navigation(in: host))
        for (index, controller) in stack.children.enumerated() {
            let role = index == 0 ? "ROOT      " : "DESTINATION"
            let hosting = controller as? AnyHostingController

            print("PBD-PROBE \(role) hosts=\(hosting.map { "\($0.viewType)" } ?? "none")")
            print("PBD-PROBE   verdict: \(controller.cobrowseVerdict)")
        }
    }

    private func navigation(in controller: UIViewController) -> UINavigationController? {
        if let navigation = controller as? UINavigationController { return navigation }
        for child in controller.children {
            if let found = navigation(in: child) { return found }
        }
        return nil
    }
}

/// An approved screen owning a stack, with a nameable destination pushed.
struct StackWithADestination: View {
    var body: some View {
        NavigationStack {
            Color.white
                .navigationDestination(isPresented: .constant(true)) { JourneyAView() }
        }
    }
}

extension StackWithADestination: ApprovedForCobrowse {}
