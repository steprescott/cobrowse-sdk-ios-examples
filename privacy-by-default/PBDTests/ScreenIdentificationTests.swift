import XCTest
import SwiftUI
@testable import PBD

/// **Does the policy reveal the screen it should, for each shape SwiftUI writes?**
///
/// Asked through `RedactByDefaultDelegate` rather than through the resolver, so
/// the test says what the *policy* does, and the resolver can be replaced
/// without touching a line here.
///
/// On the simulator because the whole subject is `UIViewController` hosting:
/// a hosting controller vends its children only once its view is in a window
/// and laid out, and the tab cases are entirely about those children.
@MainActor
final class ScreenIdentificationTests: XCTestCase {

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

    // MARK: - the ground the rest stands on

    /// `Approvals.swift` is the fixture. If these two ever agree, every
    /// reveals/hides assertion below has stopped discriminating.
    func testTheApprovedAndUnapprovedFixturesDiffer() {
        XCTAssertTrue(CobrowseApproval.approves(JourneyBView.self), "JourneyBView is the approved fixture")
        XCTAssertFalse(CobrowseApproval.approves(JourneyAView.self), "JourneyAView is the unapproved fixture")
    }

    func testAnApprovedScreenIsRevealed() {
        XCTAssertTrue(reveals(JourneyBView()))
    }

    func testAnUnapprovedScreenIsHidden() {
        XCTAssertFalse(reveals(JourneyAView()))
    }

    // MARK: - a destination carrying another screen's modifier

    /// `Approved().navigationDestination { Unapproved() }` names both screens in
    /// one type, and only the outer one is on screen. Positional, so the
    /// structure separates them; a flat scan of the same string cannot, and
    /// refused the screen for having two names.
    func testAScreenCarryingAnotherScreensDestinationIsRevealed() {
        XCTAssertTrue(reveals(
            JourneyBView().navigationDestination(item: .constant(SavedCard?.none)) { _ in JourneyAView() }
        ))
    }

    /// The same shape the other way up: the screen on display is unapproved and
    /// the *payload* is approved. Revealing it would be the leak this rule risks,
    /// so it is asserted rather than assumed.
    func testAnUnapprovedScreenCarryingAnApprovedDestinationStaysHidden() {
        XCTAssertFalse(reveals(
            JourneyAView().navigationDestination(item: .constant(SavedCard?.none)) { _ in JourneyBView() }
        ))
    }

    // MARK: - a switch in a destination closure

    /// `_ConditionalContent<A, B>` names both branches; the VALUE holds only
    /// the live one, and the walk goes into it. Where both are approved the
    /// question does not arise.
    func testAChoiceBetweenTwoApprovedScreensIsRevealed() {
        XCTAssertTrue(reveals(choice(true, JourneyBView(), ContactUsView())))
    }

    /// **A choice is judged by the branch it is showing.** The approved branch
    /// live shows; the unapproved branch live hides, whichever side of the
    /// `if` it sits on. `ChoiceStalenessTests` is the evidence that the live
    /// branch the value holds is never ahead of the frame.
    func testAChoiceIsJudgedByItsLiveBranch() {
        XCTAssertTrue(reveals(choice(true, JourneyBView(), JourneyAView())), "approved branch live")
        XCTAssertTrue(reveals(choice(false, JourneyAView(), JourneyBView())), "approved branch live, other side")
        XCTAssertFalse(reveals(choice(true, JourneyAView(), JourneyBView())), "unapproved branch live")
        XCTAssertFalse(reveals(choice(false, JourneyBView(), JourneyAView())), "unapproved branch live, other side")
    }

    /// Three branches nest as `_ConditionalContent<_ConditionalContent<A, B>, C>`,
    /// and the live one is reached through both layers.
    func testAThreeWayChoiceIsJudgedByItsLiveBranch() {
        XCTAssertTrue(revealsScreen(threeWayChoice(0, JourneyBView(), ContactUsView(), MakePaymentView())))
        XCTAssertTrue(revealsScreen(threeWayChoice(0, JourneyBView(), ContactUsView(), JourneyAView())),
                      "the live branch is approved; the third is not, and is not showing")
        XCTAssertFalse(revealsScreen(threeWayChoice(0, JourneyAView(), ContactUsView(), MakePaymentView())),
                       "the live branch is unapproved")
        XCTAssertFalse(revealsScreen(threeWayChoice(2, JourneyBView(), ContactUsView(), JourneyAView())),
                       "the live branch is the unapproved third")
    }

    /// A `TabView` whose tabs come from a `ForEach` declares no tabs at all, so
    /// nothing can be aligned and the container stays hidden. Asserted because
    /// failing closed here is a decision, not an accident.
    func testTabsFromAForEachStayHidden() throws {
        let tabs = try tabControllers(for: TabView {
            ForEach(0 ..< 2, id: \.self) { _ in JourneyBView().tabItem { Text("b") } }
        })

        for (index, tab) in tabs.enumerated() {
            XCTAssertFalse(reveals(tab), "tab \(index) was revealed from an unalignable declaration")
        }
    }

    // MARK: - the ancestor fallback, and the leak it must not become

    /// A screen that owns its own `NavigationStack` puts an unnameable
    /// controller on screen: the stack's root hosts an erased view and cannot
    /// say what it is, and the nearest controller that CAN say anything is the
    /// one hosting the whole stack. So the root borrows its container's
    /// identity.
    func testAStacksRootBorrowsTheIdentityOfTheScreenContainingIt() throws {
        let root = try XCTUnwrap(stackRoot(of: hosted(ScreenOwningAStack(pushed: false))))
        XCTAssertTrue(reveals(root), "the stack's root should read as the approved screen around it")
    }

    /// **And the borrowing must stop at the root.** A pushed screen the reader
    /// cannot name is a screen in its own right; if it borrowed its container's
    /// identity too, every unnameable destination inside an approved screen
    /// would be revealed. That is a silent leak, an unapproved screen shown
    /// with nothing anywhere reporting it, which is why it is asserted rather
    /// than left to the guard.
    func testAPushedScreenDoesNotBorrowTheContainersIdentity() throws {
        let controllers = try XCTUnwrap(stackControllers(of: hosted(ScreenOwningAStack(pushed: true))))

        XCTAssertEqual(controllers.count, 2, "the fixture should have pushed a destination")
        XCTAssertTrue(reveals(controllers[0]), "the root still reads as the approved screen")
        XCTAssertFalse(reveals(controllers[1]),
                       "an unnameable pushed screen inherited its container's approval")
    }

    private func stackRoot(of controller: UIViewController) -> UIViewController? {
        stackControllers(of: controller)?.first
    }

    private func stackControllers(of controller: UIViewController) -> [UIViewController]? {
        if let navigation = controller as? UINavigationController { return navigation.children }
        for child in controller.children {
            if let found = stackControllers(of: child) { return found }
        }
        return nil
    }

    // MARK: - tabs

    /// The static case, which already worked: each tab is named by its index in
    /// the container's declaration.
    func testStaticTabsAreIdentifiedPerTab() throws {
        let tabs = try tabControllers(for: TabView {
            JourneyBView().tabItem { Text("b") }
            JourneyAView().tabItem { Text("a") }
        })

        XCTAssertEqual(tabs.count, 2)
        XCTAssertTrue(reveals(tabs[0]), "the approved tab")
        XCTAssertFalse(reveals(tabs[1]), "the unapproved tab")
    }

    /// A tab written `if flag { … }` is `Optional` in the container's type: the
    /// declaration is static and the tab's presence is not. Aligning the two is
    /// what keeps the *other* tabs identifiable: a count mismatch would take
    /// the whole container down and every tab with it.
    func testAConditionalTabPresentIsIdentifiedAndSoAreItsNeighbours() throws {
        let tabs = try tabControllers(for: TabView {
            JourneyBView().tabItem { Text("b") }
            if true { JourneyAView().tabItem { Text("a") } }
        })

        XCTAssertEqual(tabs.count, 2)
        XCTAssertTrue(reveals(tabs[0]))
        XCTAssertFalse(reveals(tabs[1]))
    }

    /// The same declaration with the tab absent. The count matches the
    /// always-present tabs, and the remaining tab must still be named.
    func testAConditionalTabAbsentLeavesItsNeighboursIdentified() throws {
        let tabs = try tabControllers(for: TabView {
            JourneyBView().tabItem { Text("b") }
            if false { JourneyAView().tabItem { Text("a") } }
        })

        XCTAssertEqual(tabs.count, 1)
        XCTAssertTrue(reveals(tabs[0]))
    }

    /// An unapproved conditional tab must not be revealed by the alignment
    /// itself. The neighbour is approved and this one is not, and a
    /// mis-alignment by one would swap them.
    func testAlignmentDoesNotSwapTabs() throws {
        let tabs = try tabControllers(for: TabView {
            JourneyAView().tabItem { Text("a") }
            if true { JourneyBView().tabItem { Text("b") } }
        })

        XCTAssertEqual(tabs.count, 2)
        XCTAssertFalse(reveals(tabs[0]), "the unapproved tab is first")
        XCTAssertTrue(reveals(tabs[1]), "the approved tab is second")
    }

    /// **A TAB WHOSE CONTENT IS A MIXED CHOICE STAYS HIDDEN IN BOTH STATES,
    /// AND THAT IS THE SOUND ANSWER RATHER THAN A GAP.**
    ///
    /// This began as the requirement — show the approved branch — and was
    /// measured 2026-09-02 to be UNSOUND to satisfy from the declaration.
    ///
    /// A hosted or pushed choice is judged on the branch on display because
    /// its `_ConditionalContent` arrives as a value FROM THE GRAPH, so the
    /// branch it holds is the live one. A tab's identity is not in any live
    /// value: it is read by evaluating the container's `body` OFF-GRAPH, and a
    /// `@State` read there returns its INITIAL value. Measured, same session,
    /// three declared tabs with the presence driven by `@State`:
    ///
    ///     initial       onScreen=[signed-in,  always]  declared=[opt+, opt-, req+]
    ///     after toggle  onScreen=[signed-out, always]  declared=[opt+, opt-, req+]
    ///
    /// The declaration is frozen at launch. So reading a live branch, or a
    /// present-tab position, out of it would map position 0 to the APPROVED
    /// screen while the UNAPPROVED one is on screen — a fail-open, and the same
    /// shape as the borrow leak closed earlier today.
    ///
    /// ⚠ **So do not "fix" this by trusting the declaration.** The type-level
    /// unanimity rule is state-independent and therefore sound; the count-based
    /// alignment resolves only where the count determines presence uniquely,
    /// and refuses otherwise. Both are conservative on purpose.
    ///
    /// The routes that could be sound, neither built: an `@ObservedObject`- or
    /// `@Observable`-driven container IS live off-graph (measured), but nothing
    /// outside can tell which kind of state drives a container, so the worst
    /// case has to be assumed. And a tab's RUNTIME traits carry a live
    /// `TabItemLabelKey`, which would make the refusal provable rather than
    /// incidental, and could match a live tab to a declared one — it cannot
    /// invent a declaration entry that a frozen read never produced.
    func testATabWhoseContentIsAMixedChoiceStaysHidden() throws {
        let tabs = try tabControllers(for: TabView {
            choice(true, SignedInScreen().tabItem { Text("account") },
                         SignedOutScreen().tabItem { Text("account") })
            JourneyAView().tabItem { Text("a") }
        })

        XCTAssertEqual(tabs.count, 2)
        XCTAssertFalse(reveals(tabs[1]), "control: the unapproved neighbour stays hidden")
        XCTAssertFalse(
            reveals(tabs[0]),
            "a mixed choice in a tab is revealed. If this is deliberate, prove the declaration "
            + "was read from a LIVE value and not an off-graph body, or it is a fail-open")
    }

    /// The same tab showing its UNAPPROVED branch. This must be hidden under
    /// either semantics, so it is the safety control for the test above: if
    /// both fail the fixture is wrong, if only the one above fails the two
    /// routes disagree.
    func testATabShowingItsUnapprovedBranchStaysHidden() throws {
        let tabs = try tabControllers(for: TabView {
            choice(false, SignedInScreen().tabItem { Text("account") },
                          SignedOutScreen().tabItem { Text("account") })
            JourneyAView().tabItem { Text("a") }
        })

        XCTAssertEqual(tabs.count, 2)
        XCTAssertFalse(reveals(tabs[0]), "the unapproved branch is on display and must be hidden")
    }

    /// A screen generic over its model, as a real app writes one. Its declared tab is
    /// read as a value of the container's body, so the conformance answers
    /// whatever the generic arguments are.
    func testAGenericScreenIsIdentifiedAsATab() throws {
        let tabs = try tabControllers(for: TabView {
            GenericTab<Int>().tabItem { Text("g") }
            JourneyAView().tabItem { Text("a") }
        })

        XCTAssertEqual(tabs.count, 2)
        XCTAssertTrue(reveals(tabs[0]), "the generic approved tab")
        XCTAssertFalse(reveals(tabs[1]), "its unapproved neighbour")
    }

    // MARK: - helpers

    @ViewBuilder
    private func choice(_ flag: Bool, _ first: some View, _ second: some View) -> some View {
        if flag { first } else { second }
    }

    @ViewBuilder
    private func threeWayChoice(_ which: Int, _ first: some View, _ second: some View, _ third: some View) -> some View {
        switch which {
            case 0: first
            case 1: second
            default: third
        }
    }

    /// Whether the policy hands this screen's own view back to the agent.
    func revealsScreen(_ screen: some View) -> Bool { reveals(screen) }

    private func reveals(_ screen: some View) -> Bool {
        reveals(hosted(screen))
    }

    func reveals(_ controller: UIViewController) -> Bool {
        // As if it were on screen: the policy reveals only a LOADED view, and
        // an unselected tab has not loaded its own yet.
        controller.loadViewIfNeeded()
        return policy.cobrowseUnredactedViews(for: controller)
            .contains { $0 === controller.viewIfLoaded }
    }

    @discardableResult
    func hosted(_ screen: some View) -> UIViewController {
        let controller = UIHostingController(rootView: screen)
        window.rootViewController = controller
        window.makeKeyAndVisible()
        controller.view.layoutIfNeeded()
        return controller
    }

    /// The controllers SwiftUI made for a `TabView`'s tabs, in tab order.
    func tabControllers(for screen: some View) throws -> [UIViewController] {
        let controller = hosted(screen)
        let bar = try XCTUnwrap(
            firstTabBarController(in: controller),
            "SwiftUI vended no UITabBarController, so the fixture is not a tab container"
        )
        // `children` rather than `viewControllers` for the same reason the
        // policy uses it: SwiftUI leaves `viewControllers` nil on iOS 27.
        let tabs = bar.children
        XCTAssertFalse(tabs.isEmpty, "the tab bar controller vends no tabs")
        return tabs
    }

    private func firstTabBarController(in controller: UIViewController) -> UITabBarController? {
        if let bar = controller as? UITabBarController { return bar }
        for child in controller.children {
            if let found = firstTabBarController(in: child) { return found }
        }
        return nil
    }
}

@MainActor
extension ScreenIdentificationTests {

    /// The demo screen, end to end: the same three shapes as the unit cases
    /// above, but the app's own view rather than one built here, so the demo is
    /// covered by the same assertions the design is.
    ///
    /// Each tab holds a `NavigationStack`, so the tab's own controller is a
    /// container and the screen is the controller beneath it, which is the
    /// shape every stack-in-a-tab has, and the reason the assertion is on the
    /// leaf rather than on the tab.
    /// The demo, end to end: both its tabs are stable and approved, so both
    /// identify. The conditional lives INSIDE each tab — pushed on one,
    /// presented on the other — which is where a conditional works.
    ///
    /// The demo deliberately no longer contains a conditional TAB; that shape
    /// is asserted against fixtures below and in `DeclarationStalenessTests`,
    /// because it cannot be made to work and an example that only ever shows
    /// black teaches nothing.
    func testTheApprovalDemosTabsAreIdentified() throws {
        let tabs = try tabControllers(for: ConditionalApprovalDemoView())

        XCTAssertEqual(tabs.count, 2, "the Pushed tab and the Presented tab")

        for (index, tab) in tabs.enumerated() {
            XCTAssertTrue(reveals(leaf(of: tab)), "demo tab \(index) should be identified")
        }
    }

    /// **⚠ RED: AN UNAPPROVED SCREEN IN A SWAPPED TAB IS REVEALED TO THE AGENT.**
    ///
    /// The shape: an Account tab that EXISTS in one sign-in state and a
    /// different tab in the other, written as two mutually exclusive `if`
    /// tabs, inside an approved container. Measured 2026-09-02, iOS 26.5, in
    /// this fixture AND in the app's own `ConditionalApprovalDemoView`:
    ///
    ///     signedIn=false  tab 0 item=in  declaredTab=nil  reveals=TRUE  verdict=APPROVED
    ///
    /// The chain, every link measured. Three declared tabs — two optional,
    /// one always — against two tabs on screen fits neither reading, so
    /// `Tabs.aligned(to:)` returns nil and `declaredTab` says nothing. Each
    /// screen OWNS its `NavigationStack`, so the leaf controller hosts
    /// SwiftUI's own plumbing and names no screen either. A navigation root
    /// with no reading of its own borrows the nearest ancestor that has one —
    /// and with the tab silent, that ancestor is the approved CONTAINER.
    ///
    /// A fail-OPEN, and the requirement the fix goes by.
    func testAnUnapprovedScreenInASwappedTabIsNotRevealed() throws {
        let tabs = try tabControllers(for: SwappedTabsScreen(signedIn: false))

        XCTAssertEqual(tabs.count, 2, "the unapproved account tab and the approved other tab")
        XCTAssertFalse(reveals(leaf(of: tabs[0])),
                       "the unapproved sign-in screen is revealed to the agent")
    }

    /// The other state, where the tab that exists IS approved — and it stays
    /// hidden too, because the declaration that would name it cannot be trusted
    /// to describe the current state. Reasoning and the measurement:
    /// `testATabWhoseContentIsAMixedChoiceStaysHidden`.
    ///
    /// ⚠ Asserted so that revealing it again is a deliberate act with evidence
    /// attached, not a quiet loosening. Over-covering is visible; the other way
    /// round is a leak nobody sees.
    func testTheApprovedScreenInASwappedTabStaysHiddenToo() throws {
        let tabs = try tabControllers(for: SwappedTabsScreen(signedIn: true))

        XCTAssertEqual(tabs.count, 2)
        XCTAssertFalse(reveals(leaf(of: tabs[0])),
                       "the approved sign-out screen is revealed from a frozen declaration")
    }

    /// **The tabs demo's unapproved tab stays hidden, behind its own stack.**
    ///
    /// The container, `TabsDemoView`, is approved. Each tab holds a
    /// `NavigationStack`, so the screen is the stack's root, and a root borrows
    /// the identity of the screen containing it. It must borrow from its TAB,
    /// which is unapproved, and not from the first approved ancestor it finds,
    /// which is the whole container. A fallback that took any approved
    /// ancestor revealed this tab.
    ///
    /// Each tab is selected before it is asked about: unselected, its stack is
    /// not realised and the tab's own controller is the screen, so the borrow
    /// this checks would not run and the leak would hide.
    func testTheTabsDemosUnapprovedTabStaysHiddenBehindItsStack() throws {
        let tabs = try tabControllers(for: TabsDemoView())
        XCTAssertEqual(tabs.count, 3)

        let bar = try XCTUnwrap(tabs[0].parent as? UITabBarController)
        var revealed: [Bool] = []
        for index in tabs.indices {
            bar.selectedIndex = index
            bar.view.layoutIfNeeded()
            RunLoop.current.run(until: Date(timeIntervalSinceNow: 0.4))
            let screen = leaf(of: tabs[index])
            XCTAssertTrue(screen.parent is UINavigationController, "tab \(index) should have realised its stack")
            revealed.append(reveals(screen))
        }

        XCTAssertTrue(revealed[0], "the approved tab")
        XCTAssertFalse(revealed[1], "the unapproved tab borrowed the container's approval")
        XCTAssertTrue(revealed[2], "the payment tab")
    }

    /// The deepest controller under this one, which is the screen wherever the
    /// controller itself is a container.
    private func leaf(of controller: UIViewController) -> UIViewController {
        var current = controller
        while let next = current.children.last { current = next }
        return current
    }
}

// MARK: - a screen from another module

/// Stands in for a screen declared in a third-party UI framework: it is a
/// `View`, it is not in the app's module, and the app approves it the only way
/// it can, by naming it without touching the type.
struct ScreenFromAnotherModule: View {
    var body: some View { Text("third party") }
}

struct UnapprovedScreenFromAnotherModule: View {
    var body: some View { Text("third party") }
}

extension ScreenFromAnotherModule: ApprovedForCobrowse {}

/// A screen generic over its model. See `testAGenericScreenIsIdentifiedAsATab`.
/// The signed-in half of an Account tab: a sign-out button and nothing else,
/// so it carries no PII and is approved.
struct SignedInScreen: View {
    var body: some View { Text("Sign out") }
}

extension SignedInScreen: ApprovedForCobrowse {}

/// The signed-out half: a sign-in form, so it carries PII and is never
/// approved.
struct SignedOutScreen: View {
    var body: some View { Text("Email and password") }
}

struct GenericTab<Model>: View {
    var body: some View { Text("generic") }
}

extension GenericTab: ApprovedForCobrowse {}

@MainActor
extension ScreenIdentificationTests {

    /// A screen hosted directly has always been identified whatever module it
    /// is in. Its controller's own generic parameter names it and no module
    /// rule ever ran. Asserted so the next reader does not credit the widening
    /// with this case.
    func testAnApprovedScreenFromAnotherModuleIsRevealed() {
        XCTAssertTrue(revealsScreen(ScreenFromAnotherModule()))
    }

    /// The case the widening is actually for: a foreign-module screen reached
    /// through a *structure* rather than hosted directly. The module rule used
    /// to filter it out of the container's declaration, and losing one name
    /// from a two-tab declaration took the whole container down with it.
    func testAnApprovedScreenFromAnotherModuleIsIdentifiedAsATab() throws {
        let tabs = try tabControllers(for: TabView {
            ScreenFromAnotherModule().tabItem { Text("third party") }
            JourneyAView().tabItem { Text("a") }
        })

        XCTAssertEqual(tabs.count, 2)
        XCTAssertTrue(reveals(tabs[0]), "the approved third-party tab")
        XCTAssertFalse(reveals(tabs[1]), "its unapproved neighbour")
    }

    /// The control that keeps the rule above from being a hole: widening admits
    /// approved types only, so an unapproved view from the same foreign module
    /// stays hidden exactly as a `Text` does.
    func testAnUnapprovedScreenFromAnotherModuleIsHidden() {
        XCTAssertFalse(revealsScreen(UnapprovedScreenFromAnotherModule()))
    }
}

@MainActor
extension ScreenIdentificationTests {

    /// Not an assertion: what SwiftUI actually builds for a `TabView` on this
    /// OS. Printed because the answer changed between iOS 26 and 27. On 26 a
    /// `UITabBarController` is vended and the tab lookup keys on it; on 27 the
    /// tab tests fail at the fixture because none appears.
    func testPrintWhatATabViewVends() {
        let controller = hosted(TabView {
            JourneyBView().tabItem { Text("b") }
            JourneyAView().tabItem { Text("a") }
        })

        print("PBD-PROBE OS \(UIDevice.current.systemVersion) idiom \(UIDevice.current.userInterfaceIdiom.rawValue)")
        describeControllers(controller, depth: 0)
        describeViews(controller.view, depth: 0)
    }

    private func describeControllers(_ controller: UIViewController, depth: Int) {
        let pad = String(repeating: "  ", count: depth)
        let hosted = (controller as? AnyHostingController).map { "\($0.viewType)" } ?? "none"
        print("PBD-PROBE \(pad)VC \(type(of: controller)) hosts=\(hosted) verdict=\(controller.cobrowseVerdict) children=\(controller.children.count)")
        controller.children.forEach { describeControllers($0, depth: depth + 1) }
    }

    private func describeViews(_ view: UIView, depth: Int) {
        guard depth < 5 else { return }
        print("PBD-PROBE \(String(repeating: "  ", count: depth))V \(type(of: view))")
        view.subviews.forEach { describeViews($0, depth: depth + 1) }
    }
}

/// An approved screen that owns its own `NavigationStack`, and can push a
/// destination made only of SwiftUI's own types, so the reader can name
/// nothing in it, and the only identity available would be the container's.
struct ScreenOwningAStack: View {

    let pushed: Bool

    var body: some View {
        NavigationStack {
            Color.white
                .navigationDestination(isPresented: .constant(pushed)) {
                    Text("nothing here names an app screen")
                }
        }
    }
}

extension ScreenOwningAStack: ApprovedForCobrowse {}
