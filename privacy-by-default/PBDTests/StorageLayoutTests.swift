import XCTest
import SwiftUI
@testable import PBD

/// **The layout the two-level routes depend on, and the refusals that keep
/// them safe.**
///
/// `in(anyView:)` and `in(conditionalContent:)` reach the view behind one
/// stored property that is NOT itself a view. If SwiftUI ever stored a second
/// property there, or made that storage a view, reflecting on into it would
/// reach INSIDE a view rather than stopping at it — the boundary
/// `PeelBoundaryTests` guards, breached from the other direction. That failure
/// would be silent and would reveal.
///
/// `AnyView` is concrete, so the guard cannot be handed a fake. The first two
/// tests instead pin the layout it depends on: if SwiftUI changes it, they
/// fail loudly here rather than quietly in the policy. The rest assert that an
/// unrecognised shape is refused, through the real entry point.
@MainActor
final class StorageLayoutTests: XCTestCase {

    /// What `in(anyView:)` depends on: one stored property, and not a view.
    func testAnAnyViewStoresOneNonViewBox() throws {

        let stored = Mirror(reflecting: AnyView(ApprovedGreenScreen())).children

        XCTAssertEqual(stored.count, 1, "AnyView no longer stores exactly one property")

        let box = try XCTUnwrap(stored.first?.value)
        XCTAssertFalse(box is any View, "AnyView's storage is now itself a view")
    }

    /// What `in(conditionalContent:)` depends on: one stored property, not a
    /// view, holding the live branch.
    func testAConditionalContentStoresOneNonViewStorage() throws {

        let stored = Mirror(reflecting: choice(showingApproved: true)).children

        XCTAssertEqual(stored.count, 1, "_ConditionalContent no longer stores exactly one property")

        let storage = try XCTUnwrap(stored.first?.value)
        XCTAssertFalse(storage is any View, "a choice's storage is now itself a view")
    }

    /// **The guard itself: storage that IS a view must be refused.**
    ///
    /// `AnyView` is concrete so it cannot be handed a fake, but the helper both
    /// routes share can be. Without the guard this returns the approved view
    /// stored inside — reaching a property of a view instead of stopping at
    /// the view.
    func testStorageThatIsItselfAViewIsRefused() {
        XCTAssertNil(Find.view.theViewBehindStorage(of: StoresAViewHoldingAnApprovedView()),
                     "a view was reached through storage that is itself a view")
    }

    /// The same helper on the layout it is for: one non-view stored property.
    func testStorageThatIsNotAViewIsFollowed() throws {

        let reached = try XCTUnwrap(Find.view.theViewBehindStorage(of: AnyView(ApprovedGreenScreen())),
                                    "the view behind AnyView's box was not reached")

        XCTAssertTrue(reached is ApprovedGreenScreen, "reached \(type(of: reached)) instead")
    }

    /// **An approved view reached through another view is not approved.** The
    /// walk stops at the first view it meets and never enters it, so a
    /// wrapper storing a view that holds an approved one is refused.
    func testAnApprovedViewBehindAnotherViewIsNotApproved() {
        XCTAssertFalse(Find.Verdict.for(StoresAViewHoldingAnApprovedView()).isApproved,
                       "an approved view was reached by entering another view")
    }

    /// Two stored views give nothing static to choose between, so nothing is
    /// returned rather than one of them guessed at.
    func testAWrapperStoringTwoViewsIsNotApproved() {
        XCTAssertFalse(Find.Verdict.for(StoresAnApprovedViewBesideAnother()).isApproved,
                       "one of two stored views was picked")
    }

    /// A wrapper storing no view at all names no screen.
    func testAWrapperStoringNoViewNamesNothing() {
        XCTAssertTrue(Find.Verdict.for(StoresNoView()).isUnknown,
                      "something was named for a wrapper storing no view")
    }

    @ViewBuilder private func choice(showingApproved: Bool) -> some View {
        if showingApproved { ApprovedGreenScreen() } else { Color.red }
    }
}

/// Storage that is itself a view, holding an approved view. Without the
/// boundary the approved one inside would be reached.
private struct StoresAViewHoldingAnApprovedView {
    let storage = HoldsAnApprovedInnerView()
}

private struct HoldsAnApprovedInnerView: View {
    let inner = ApprovedGreenScreen()
    var body: some View { Color.blue }
}

/// An approved view stored beside another view, so counting cannot say which
/// is on display.
private struct StoresAnApprovedViewBesideAnother {
    let approved = ApprovedGreenScreen()
    let other = Color.red
}

private struct StoresNoView {
    let size = CGSize.zero
    let flag = true
}
