import XCTest
import SwiftUI
@testable import PBD

/// **THE PATTERN THAT WORKS FOR A SIGN-IN / SIGN-OUT TAB, and it needs no
/// policy change: the tab never swaps, and the sensitive screen is PUSHED.**
///
/// The shape that does NOT work is swapping the tab itself, or switching a
/// tab's content with a conditional. Both need the policy to know which branch
/// is live, and a tab's identity is only readable by evaluating the container's
/// body OFF-GRAPH, where a `@State` read returns its INITIAL value — so the
/// declaration is frozen at launch and cannot say. Measured 2026-09-02, iOS
/// 26.5, including a read taken fresh from SwiftUI's own
/// `PresentationHostingController`, so the freeze is not an artifact of a test
/// holding the root: presence stayed `[opt+, opt-, req+]` while the tab on
/// screen went from the approved branch to the unapproved one. Reasoning and
/// the refusal it justifies: `DeclarationStalenessTests`.
///
/// This is also the platform's own idiom — a sign-in is normally a pushed or
/// presented screen rather than a tab that appears and disappears.
@MainActor
final class StableTabPatternTests: XCTestCase {

    private var window: UIWindow!
    private let policy = RedactByDefaultDelegate()

    override func setUp() {
        super.setUp()
        let scene = UIApplication.shared.connectedScenes.compactMap { $0 as? UIWindowScene }.first!
        window = UIWindow(windowScene: scene)
        window.frame = UIScreen.main.bounds
    }

    override func tearDown() { window?.isHidden = true; window = nil; super.tearDown() }

    /// The approved screen is seen, the sensitive one pushed over it is not,
    /// and the neighbouring tab is unaffected — which is the whole requirement,
    /// met without the policy having to resolve a conditional.
    func testAStableTabShowsItsApprovedScreenAndHidesThePushedOne() throws {
        let host = UIHostingController(rootView: StableTabWithPush())
        window.rootViewController = host
        window.makeKeyAndVisible()
        host.view.layoutIfNeeded()
        settle()

        let bar = try XCTUnwrap(firstTabBar(in: host), "no UITabBarController on screen")
        bar.children.forEach { $0.loadViewIfNeeded() }
        XCTAssertEqual(bar.children.count, 2, "the Account tab and its neighbour")

        var readings: [(type: String, revealed: Bool)] = []

        for tab in bar.children {
            for controller in AgentFrameOracle.everyController(from: tab) where controller.children.isEmpty {
                controller.loadViewIfNeeded()
                readings.append((
                    "\(controller.cobrowseVerdict)",
                    policy.cobrowseUnredactedViews(for: controller).isEmpty == false
                ))
            }
        }

        XCTAssertEqual(readings.filter(\.revealed).count, 2,
                       "the Account tab's own screen and the neighbouring tab")

        let hidden = try XCTUnwrap(readings.first { $0.revealed == false },
                                   "the pushed sign-in screen should be present and hidden")
        XCTAssertTrue(hidden.type.contains("BranchUnapproved"),
                      "the hidden screen should be the pushed unapproved one, was \(hidden.type)")
    }

    private func settle() {
        let until = Date(timeIntervalSinceNow: 0.6)
        while until.timeIntervalSinceNow > 0 {
            RunLoop.current.run(until: Date(timeIntervalSinceNow: 0.02))
        }
    }

    private func firstTabBar(in controller: UIViewController) -> UITabBarController? {
        if let bar = controller as? UITabBarController { return bar }
        for child in controller.children {
            if let found = firstTabBar(in: child) { return found }
        }
        return controller.presentedViewController.flatMap { firstTabBar(in: $0) }
    }
}

/// The Account tab is ALWAYS the approved screen; signing in happens on a
/// screen pushed from it, which is unapproved and therefore hidden, without
/// the tab having to change at all.
struct StableTabWithPush: View {

    @State private var signingIn = true

    var body: some View {
        TabView {
            AccountHome(signingIn: $signingIn).tabItem { Label("Account", systemImage: "person") }
            BranchApproved().tabItem { Label("Always", systemImage: "star") }
        }
    }
}

/// Approved: shows no PII itself, and pushes the sign-in screen.
struct AccountHome: View {

    @Binding var signingIn: Bool

    var body: some View {
        NavigationStack {
            Text("Account")
                .navigationDestination(isPresented: $signingIn) { BranchUnapproved() }
        }
    }
}

extension AccountHome: ApprovedForCobrowse {}
