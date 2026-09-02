import XCTest
import SwiftUI
@testable import PBD

/// **A `switch` destination PUSHED into a stack, which is the shape the app
/// actually produces**, as opposed to a `_ConditionalContent` hosted directly,
/// which is what the unit fixture was doing and why this got through.
///
/// A pushed `switch` destination is the shape the app produces, as opposed to
/// a `_ConditionalContent` hosted directly, and the destination controller
/// hosts it inside an `AnyView` the walk has to reflect through.
@MainActor
final class PushedChoiceTests: XCTestCase {

    private var window: UIWindow!
    private let policy = RedactByDefaultDelegate()

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

    func testAPushedChoiceBetweenApprovedScreensIsRevealed() throws {
        let destination = try push(PushesAChoice())

        print("PBD-PROBE pushed choice verdict=\(destination.cobrowseVerdict)")
        if let box = (destination as? AnyHostingController)?.anyRootView as? AnyView {
            let storage = Mirror(reflecting: box).children.first?.value
            print("PBD-PROBE   box storage: \(storage.map { String(reflecting: type(of: $0)) } ?? "none")")
            print("PBD-PROBE   box verdict: \(Find.Verdict.for(box))")
        }

        XCTAssertFalse(policy.cobrowseUnredactedViews(for: destination).isEmpty,
                       "a switch destination between two approved screens was not revealed")
    }

    /// **The arm that discriminates the peel: a MIXED choice showing its
    /// APPROVED branch must be revealed.**
    ///
    /// The two tests either side of it cannot fail if the live-branch peel is
    /// deleted — one has both branches approved so the unanimity conformance
    /// answers, the other asserts hidden, which `unknown` also gives. Measured
    /// 2026-09-02: with `view.in(conditionalContent:)` disabled this one reads
    /// `unknown` and the screen goes black, and only this one fails.
    func testAPushedMixedChoiceShowingItsApprovedBranchIsRevealed() throws {
        let destination = try push(PushesAnApprovedMixedChoice())

        XCTAssertFalse(policy.cobrowseUnredactedViews(for: destination).isEmpty,
                       "the approved branch of a mixed pushed choice was hidden")
    }

    /// The control: the same shape showing its UNAPPROVED branch must stay
    /// hidden, whatever the other branch is.
    func testAPushedChoiceShowingAnUnapprovedScreenIsHidden() throws {
        let destination = try push(PushesAMixedChoice())
        XCTAssertTrue(policy.cobrowseUnredactedViews(for: destination).isEmpty,
                      "a switch destination showing an unapproved branch was revealed")
    }

    private func push(_ screen: some View) throws -> UIViewController {
        let host = UIHostingController(rootView: screen)
        window.rootViewController = host
        window.makeKeyAndVisible()
        host.view.layoutIfNeeded()
        RunLoop.current.run(until: Date(timeIntervalSinceNow: 0.4))
        host.view.layoutIfNeeded()

        let stack = try XCTUnwrap(navigation(in: host), "no navigation controller")
        XCTAssertEqual(stack.children.count, 2, "nothing was pushed")
        return stack.children[1]
    }

    private func navigation(in controller: UIViewController) -> UINavigationController? {
        if let navigation = controller as? UINavigationController { return navigation }
        for child in controller.children {
            if let found = navigation(in: child) { return found }
        }
        return nil
    }
}

/// Both branches approved, so the destination should show whichever is live.
/// **The arm that DISCRIMINATES the live-branch peel on a pushed destination.**
///
/// The two fixtures below cannot: `PushesAChoice` has both branches approved,
/// so the unanimity conformance answers without any peeling, and
/// `PushesAMixedChoice` asserts HIDDEN, which an `unknown` verdict also gives.
/// Both pass with `view.in(conditionalContent:)` disabled — measured
/// 2026-09-02 — so neither was evidence for the peel.
///
/// This one shows the APPROVED branch of a mixed choice and asserts it is
/// revealed. With the peel disabled it reads `unknown` and the screen goes
/// black, so it fails. That is what makes it evidence.
struct PushesAnApprovedMixedChoice: View {
    var body: some View {
        NavigationStack {
            Color.white.navigationDestination(isPresented: .constant(true)) { destination }
        }
    }
    @ViewBuilder private var destination: some View {
        if true { ContactUsView() } else { JourneyAView() }
    }
}

struct PushesAChoice: View {
    var body: some View {
        NavigationStack {
            Color.white.navigationDestination(isPresented: .constant(true)) { destination }
        }
    }
    @ViewBuilder private var destination: some View {
        if true { JourneyBView() } else { ContactUsView() }
    }
}

/// The unapproved branch is the live one, so it must stay hidden.
struct PushesAMixedChoice: View {
    var body: some View {
        NavigationStack {
            Color.white.navigationDestination(isPresented: .constant(true)) { destination }
        }
    }
    @ViewBuilder private var destination: some View {
        if true { JourneyAView() } else { JourneyBView() }
    }
}
