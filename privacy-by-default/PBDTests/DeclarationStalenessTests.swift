import XCTest
import SwiftUI
@testable import PBD

/// **WHY A TAB CANNOT BE JUDGED ON ITS CONDITIONAL'S LIVE BRANCH, even though
/// a `_ConditionalContent` really does hold only one.**
///
/// The premise is right and it is why a HOSTED or PUSHED choice is judged
/// correctly: that conditional arrives as a value from the graph, so the
/// branch it holds is the one on screen.
///
/// A tab's is not the graph's conditional. There is no live value to read for
/// a tab — its own controller hosts a `_ViewList_View` whose content lives in
/// an `AGSubgraphRef` and holds no view at all — so the only way to see the
/// declaration is to evaluate the CONTAINER'S BODY OURSELVES, off-graph. That
/// produces a fresh `_ConditionalContent` whose condition we just evaluated
/// with a `@State` read that returns its INITIAL value. It holds one branch,
/// honestly, and it is the branch that was live at launch.
///
/// So this is a replica frozen at launch, not the app's live conditional.
@MainActor
final class DeclarationStalenessTests: XCTestCase {

    private var window: UIWindow!

    override func setUp() {
        super.setUp()
        let scene = UIApplication.shared.connectedScenes.compactMap { $0 as? UIWindowScene }.first!
        window = UIWindow(windowScene: scene)
        window.frame = UIScreen.main.bounds
    }

    override func tearDown() { window?.isHidden = true; window = nil; super.tearDown() }

    /// ⚠ **Asserts the STALENESS, so the fix that looks obvious cannot be
    /// landed quietly.** After a toggle the tab on screen is the unapproved
    /// branch while the declared conditional still holds the approved one and
    /// still reads APPROVED. Judging the tab on that would reveal the PII
    /// screen — the same fail-open shape as the borrow leak.
    ///
    /// This failing is GOOD NEWS: it means the declaration now tracks state,
    /// and a tab could then be judged on its live branch. Verify that the
    /// value being read really came from the graph before believing it.
    func testADeclaredConditionalsBranchGoesStaleAndMustNotBeTrusted() throws {
        let box = BranchBox()
        let host = UIHostingController(rootView: BranchTabs(box: box))
        window.rootViewController = host
        window.makeKeyAndVisible()
        host.view.layoutIfNeeded()
        settle()

        let bar = try XCTUnwrap(firstTabBar(in: host))
        bar.children.forEach { $0.loadViewIfNeeded() }
        report("initial", host: host, bar: bar)

        box.signedIn?.wrappedValue = false
        settle()
        let after = report("after toggle", host: host, bar: bar)

        XCTAssertEqual(after.onScreen, ["signed-out"],
                       "precondition: the toggle moved the tab on screen")

        XCTAssertEqual(after.branch, "BranchApproved",
                       "the declared conditional now tracks state — a tab MAY be judged on "
                       + "its live branch, if the value came from the graph rather than an "
                       + "off-graph body. Re-measure before loosening the policy.")

        XCTAssertTrue(after.verdictWasApproved,
                      "the declared conditional no longer reads APPROVED for a screen that "
                      + "is not on display")
    }

    /// What the tab shows, and what the declaration claims about it.
    private struct Reading {
        var onScreen: [String] = []
        var branch = "none found"
        var verdictWasApproved = false
    }

    /// What the tab shows on screen, against the branch the DECLARED
    /// conditional is holding.
    @discardableResult
    private func report(_ label: String, host: UIHostingController<BranchTabs>, bar: UITabBarController) -> Reading {

        var reading = Reading()
        let onScreen = bar.children.compactMap { $0.tabBarItem?.title }
        reading.onScreen = onScreen

        var branches: [String] = []
        if let tabView = Find.tabView(in: host.rootView),
           let content = Mirror(reflecting: tabView).children.first(where: { $0.value is any View })?.value {

            let elements = (content as? any AnyTupleView)
                .map { Mirror(reflecting: $0.anyValue).children.map(\.value) } ?? [content]

            for element in elements {
                // What the policy would conclude from this declared element,
                // which is the thing that decides whether the tab is revealed.
                let verdict = Find.Verdict.for(element)

                // And which branch the conditional is actually holding, named
                // by the app-module view at the end of the walk.
                let name = appView(in: element).map { "\(type(of: $0))" } ?? "none found"

                reading.branch = name
                reading.verdictWasApproved = verdict.isApproved
                branches.append("branch=\(name)  verdict=\(verdict)")
            }
        }

        print("PBD-PROBE \(label): onScreen=\(onScreen)")
        branches.forEach { print("PBD-PROBE    declared element holds: \($0)") }

        return reading
    }

    /// The app-module view this element eventually shows, by the same descent
    /// the policy uses.
    private func appView(in element: Any) -> Any? {
        var value = element
        for _ in 0 ..< 12 {
            if Module.isSystem(type(of: value)) == false, value is any View { return value }
            guard let next = Find.view.in(modifiedContent: value)
                ?? Find.view.in(conditionalContent: value)
                ?? Find.view.in(anyView: value)
                ?? Find.view.in(optional: value)
                ?? Find.view.in(properties: value)
            else { return nil }
            value = next
        }
        return nil
    }

    private func settle() {
        let until = Date(timeIntervalSinceNow: 0.5)
        while until.timeIntervalSinceNow > 0 {
            RunLoop.current.run(until: Date(timeIntervalSinceNow: 0.02))
        }
    }

    private func firstTabBar(in controller: UIViewController) -> UITabBarController? {
        if let bar = controller as? UITabBarController { return bar }
        for child in controller.children {
            if let found = firstTabBar(in: child) { return found }
        }
        return nil
    }
}

final class BranchBox {
    var signedIn: Binding<Bool>?
}

/// ONE tab whose CONTENT is an if/else — Ste's exact shape. The conditional is
/// the tab's content, so the declared element is a `_ConditionalContent`
/// holding a single live branch.
struct BranchTabs: View {

    let box: BranchBox

    @State private var signedIn = true

    var body: some View {
        TabView {
            branch.tabItem { Text(signedIn ? "signed-in" : "signed-out") }
        }
        .onAppear { box.signedIn = $signedIn }
    }

    @ViewBuilder private var branch: some View {
        if signedIn { BranchApproved() } else { BranchUnapproved() }
    }
}

struct BranchApproved: View { var body: some View { Text("approved, no PII") } }
extension BranchApproved: ApprovedForCobrowse {}

struct BranchUnapproved: View { var body: some View { Text("PII") } }
