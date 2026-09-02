import XCTest
import SwiftUI
@testable import PBD

/// **THE iOS 18 `Tab { }` API IS IDENTIFIED, and so is the old `.tabItem` one.**
/// Fixed and measured 2026-09-02, iOS 26.5.
///
/// Two things were wrong, and both are worth keeping written down because
/// neither announced itself — the tabs simply went black.
///
/// **1. The declaration was not reached.** `Tabs` looked for a `TupleView` as
/// the `TabView`'s content. The old API puts one there directly; `Tab { }`
/// produces `TabView<Never, Content<_TupleTabContent<…>>>`, where the tuple is
/// two levels further in. It declared ONE tab where there were two, the count
/// could not be aligned, and nothing was identified. `Tabs.tuple(in:)` now
/// finds it by CONFORMANCE, bounded to SwiftUI's own types.
///
/// **2. A type check could not tell two tabs apart.** Every new-API element is
/// `ModifiedContent<TabIdentifiedView, _TraitWritingModifier<…>>` — the SAME
/// type for every tab, because `TabIdentifiedView` is nested inside the generic
/// `Tab`. The app's view is in the VALUE, so `Tabs` judges each element's value
/// and carries a verdict per tab instead of a type.
///
/// Underneath both sat a third bug, in `Find.module(from:)`: `TabIdentifiedView`
/// spells as `(extension in SwiftUI):SwiftUI.Tab<…>.TabIdentifiedView`, so the
/// module read as `(extension in SwiftUI):SwiftUI` and SwiftUI's own type was
/// treated as one the developer wrote — the walk stopped there and refused it.
/// See `ModuleNameTests`.
@available(iOS 18, *)
@MainActor
final class NewTabApiTests: XCTestCase {

    private var window: UIWindow!
    private let policy = RedactByDefaultDelegate()

    override func setUp() {
        super.setUp()
        let scene = UIApplication.shared.connectedScenes
            .compactMap { $0 as? UIWindowScene }.first!
        window = UIWindow(windowScene: scene)
        window.frame = UIScreen.main.bounds
    }

    override func tearDown() { window?.isHidden = true; window = nil; super.tearDown() }

    /// The old API, as the control: unchanged by the fix.
    func testTheOldTabItemApiStillIdentifiesItsTabs() throws {
        let tabs = try tabControllers(for: OldStyleTabs())

        XCTAssertEqual(tabs.count, 2)
        XCTAssertTrue(reveals(tabs[0]), "the approved tab of the OLD API")
        XCTAssertFalse(reveals(tabs[1]), "its unapproved neighbour")
    }

    /// The new API: the approved tab is revealed and its unapproved neighbour
    /// is not — per tab, which is the part a type check could never do.
    func testTheNewTabApiIdentifiesEachTab() throws {
        let tabs = try tabControllers(for: NewStyleTabs())

        XCTAssertEqual(tabs.count, 2)
        XCTAssertTrue(reveals(tabs[0]), "the approved tab of the NEW API")
        XCTAssertFalse(reveals(tabs[1]), "its unapproved neighbour must stay hidden")
    }

    /// Both APIs declare both tabs. The old count was 1 for the new API, which
    /// is what made the whole container unidentifiable.
    func testBothApisDeclareBothTabs() throws {
        XCTAssertEqual(Tabs.declared(in: OldStyleTabs())?.all.count, 2, "old API")
        XCTAssertEqual(Tabs.declared(in: NewStyleTabs())?.all.count, 2, "new API")
    }

    // MARK: - fail-closed

    /// ⚠ **THE HAZARD THE CONFORMANCE SEARCH INTRODUCES: a developer's view
    /// may STORE a `TupleView`, and reading that as the tab declaration would
    /// map tabs onto the wrong screens.**
    ///
    /// `tuple(in:)` descends only through SwiftUI's own types, so the search
    /// stops at the developer's view rather than rummaging inside it. Here the
    /// single tab is such a view, holding a tuple of two OTHER screens; the
    /// declaration must be the one tab, judged on the view itself, and must not
    /// become two tabs from the stored tuple.
    func testTheTupleSearchDoesNotEnterAViewTheDeveloperWrote() throws {
        let declared = try XCTUnwrap(Tabs.declared(in: TabHoldingAStoredTuple()))

        XCTAssertEqual(declared.all.count, 1,
                       "the developer's stored TupleView was read as the tab declaration")

        let tabs = try tabControllers(for: TabHoldingAStoredTuple())
        XCTAssertEqual(tabs.count, 1)
        XCTAssertFalse(reveals(tabs[0]),
                       "the tab is an unapproved view of the app's and must stay hidden")
    }

    /// A container whose declaration cannot be read at all stays hidden —
    /// every route out of `declaredTab` returns nil, and a tab with no reading
    /// of its own is not revealed.
    func testAContainerWhoseDeclarationCannotBeReadStaysHidden() throws {
        let tabs = try tabControllers(for: TabsFromAForEach())

        XCTAssertEqual(tabs.count, 2, "SwiftUI still vends the tabs")
        for (index, tab) in tabs.enumerated() {
            XCTAssertFalse(reveals(tab),
                           "tab \(index) was revealed from a declaration nobody could read")
        }
    }

    // MARK: - helpers

    private func reveals(_ controller: UIViewController) -> Bool {
        controller.loadViewIfNeeded()
        return policy.cobrowseUnredactedViews(for: controller)
            .contains { $0 === controller.viewIfLoaded }
    }

    private func tabControllers(for screen: some View) throws -> [UIViewController] {
        let host = UIHostingController(rootView: screen)
        window.rootViewController = host
        window.makeKeyAndVisible()
        host.view.layoutIfNeeded()

        let until = Date(timeIntervalSinceNow: 0.5)
        while until.timeIntervalSinceNow > 0 {
            RunLoop.current.run(until: Date(timeIntervalSinceNow: 0.02))
        }

        let bar = try XCTUnwrap(firstTabBar(in: host), "SwiftUI vended no UITabBarController")
        bar.children.forEach { $0.loadViewIfNeeded() }
        return bar.children
    }

    private func firstTabBar(in controller: UIViewController) -> UITabBarController? {
        if let bar = controller as? UITabBarController { return bar }
        for child in controller.children {
            if let found = firstTabBar(in: child) { return found }
        }
        return nil
    }
}

/// The old `.tabItem` API — a `TupleView` of tab values.
struct OldStyleTabs: View {
    var body: some View {
        TabView {
            ContactUsView().tabItem { Label("Approved", systemImage: "person") }
            JourneyAView().tabItem { Label("Unapproved", systemImage: "gear") }
        }
    }
}

/// The iOS 18 `Tab { }` API — a `Content<_TupleTabContent<…>>`.
@available(iOS 18, *)
struct NewStyleTabs: View {
    var body: some View {
        TabView {
            Tab("Approved", systemImage: "person") { ContactUsView() }
            Tab("Unapproved", systemImage: "gear") { JourneyAView() }
        }
    }
}

/// One tab, whose view is the developer's own and happens to STORE a
/// `TupleView` of two other screens. The search must not read that as the tab
/// declaration.
struct TabHoldingAStoredTuple: View {
    var body: some View {
        TabView {
            HoldsATupleOfScreens().tabItem { Label("One", systemImage: "person") }
        }
    }
}

/// Not approved, and holding a tuple of screens as a stored property.
struct HoldsATupleOfScreens: View {

    let stored = TupleView((ContactUsView(), JourneyBView()))

    var body: some View { Text("one tab") }
}

/// Tabs from a `ForEach` declare no tuple of tab values at all.
struct TabsFromAForEach: View {
    var body: some View {
        TabView {
            ForEach(0 ..< 2, id: \.self) { index in
                ContactUsView().tabItem { Text("\(index)") }
            }
        }
    }
}
