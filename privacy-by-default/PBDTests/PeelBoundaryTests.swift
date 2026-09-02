import XCTest
import SwiftUI
@testable import PBD

/// **Where the walk from a controller to its screen must STOP.**
///
/// Both routes to a screen peel wrappers: the value route through `Mirror`, the
/// name route through a type's structure. Each peel is a claim that what is
/// inside is what is on display, and a peel that goes one layer too far reveals
/// a view that is not on screen. Both cases here fail OPEN, which is the
/// direction nobody notices, so they are asserted.
@MainActor
final class PeelBoundaryTests: XCTestCase {

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

    /// **A view that HOLDS an approved view as a stored property is not that
    /// view.** Its body draws something else, and the property is never on
    /// screen. A value peel that takes "the only child" walks straight into it.
    func testAViewHoldingAnApprovedViewAsAPropertyStaysHidden() {
        let host = hosted(HoldsAnApprovedViewAsAProperty())
        XCTAssertTrue(policy.cobrowseUnredactedViews(for: host).isEmpty,
                      "a view was revealed because a stored property of it is approved")
    }

    /// **A sheet showing a framework view with an approved view attached as a
    /// modifier's payload is showing the framework view.** The presented
    /// content is wrapped in a `SheetContent` the peel cannot name, and a scan
    /// that then takes "the one app view named anywhere inside" finds the
    /// payload and reveals a `Text`.
    func testASheetOfFrameworkContentCarryingAnApprovedPayloadStaysHidden() throws {
        let host = hosted(PresentsFrameworkContentCarryingAnApprovedPayload())
        RunLoop.current.run(until: Date(timeIntervalSinceNow: 0.6))

        let sheet = try XCTUnwrap(host.presentedViewController, "nothing was presented")
        var leaf = sheet
        while let next = leaf.children.last { leaf = next }

        XCTAssertTrue(policy.cobrowseUnredactedViews(for: leaf).isEmpty,
                      "a sheet was revealed because a modifier payload inside it names an approved view")
    }

    private func hosted(_ screen: some View) -> UIViewController {
        let controller = UIHostingController(rootView: screen)
        window.rootViewController = controller
        window.makeKeyAndVisible()
        controller.view.layoutIfNeeded()
        return controller
    }
}

/// Draws red. Holds an approved view it never shows.
struct HoldsAnApprovedViewAsAProperty: View {
    let held = ApprovedGreenScreen()
    var body: some View { Color(red: 1, green: 0, blue: 0).ignoresSafeArea() }
}

/// Presents a `Text` whose type carries an approved view as a destination
/// payload. The destination is never presented; the `Text` is what shows.
struct PresentsFrameworkContentCarryingAnApprovedPayload: View {
    @State private var showing = true
    var body: some View {
        Color.white.sheet(isPresented: $showing) {
            Text("nothing approved is on display")
                .navigationDestination(isPresented: .constant(false)) { ApprovedPresentationView(depth: 1) }
        }
    }
}
