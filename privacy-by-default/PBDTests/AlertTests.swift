import XCTest
import SwiftUI
import CobrowseSDK
@testable import PBD

/// **Is an alert redacted by default, and can it be approved if we want it?**
///
/// An alert is the case the container rule has to get right: a
/// `UIAlertController` with a text field has a CHILD
/// (`_UIAlertControllerTextFieldViewController`), so a rule shaped "a container
/// contributes its bars" would send it down the container path and cover
/// nothing, letting the alert's title, message and buttons reach the agent
/// while the app believes every screen is hidden.
@MainActor
final class AlertTests: XCTestCase {

    private var window: UIWindow!
    private let policy = RedactByDefaultDelegate()

    override func setUp() {
        super.setUp()
        let scene = UIApplication.shared.connectedScenes
            .compactMap { $0 as? UIWindowScene }.first!
        window = UIWindow(windowScene: scene)
        window.frame = UIScreen.main.bounds
        // A background, so "black" in the transmitted frame means covered
        // rather than nothing having been drawn there.
        let root = UIViewController()
        root.view.backgroundColor = .white
        window.rootViewController = root
        window.makeKeyAndVisible()
    }

    override func tearDown() {
        window?.isHidden = true
        window = nil
        super.tearDown()
    }

    /// What the policy sees, printed, for both shapes of alert.
    func testWhatAnAlertLooksLikeToThePolicy() throws {
        for hasTextField in [false, true] {
            let alert = try present(textField: hasTextField)
            let approvedAlert = try present(textField: hasTextField, approved: true)
            print("PBD-PROBE approved alert textField=\(hasTextField) "
                  + "children=\(approvedAlert.children.count) "
                  + "unredacted=\(describe(policy.cobrowseUnredactedViews(for: approvedAlert), of: approvedAlert))")
            dismiss(approvedAlert)

            print("PBD-PROBE alert textField=\(hasTextField) "
                  + "class=\(type(of: alert)) children=\(alert.children.count) "
                  + "childClasses=\(alert.children.map { "\(type(of: $0))" }) "
                  + "redacted=\(describe(policy.cobrowseRedactedViews(for: alert), of: alert)) "
                  + "unredacted=\(describe(policy.cobrowseUnredactedViews(for: alert), of: alert))")
            dismiss(alert)
        }
    }

    /// **An unapproved alert must not reach the agent**, whichever shape it is.
    ///
    /// Asked of the transmitted frame rather than of the returned array,
    /// because the two policies cover an alert by different routes and only
    /// the frame says whether either worked. Per-screen, the alert covers its
    /// own view through `chrome(of:)`'s default. Under a window blanket the
    /// blanket is above it. The requirement is the same either way.
    func testAnUnapprovedAlertDoesNotReachTheAgent() throws {
        for hasTextField in [false, true] {
            let alert = try present(textField: hasTextField)
            let region = window.convert(alert.view.bounds, from: alert.view)

            let ungoverned = try frame(policy: nil)
            XCTAssertTrue(try ungoverned.hasAnyColour(in: region, of: window),
                          "precondition: an alert with textField=\(hasTextField) renders at all")

            let governed = try frame(policy: policy)
            XCTAssertTrue(try governed.isBlack(in: region, of: window),
                          "an unapproved alert with textField=\(hasTextField) reached the agent")

            dismiss(alert)
        }
    }

    /// **A plain alert can be approved.**
    func testAnApprovedAlertComesBack() throws {
        let alert = try present(textField: false, approved: true)
        XCTAssertFalse(policy.cobrowseUnredactedViews(for: alert).isEmpty,
                       "an approved alert did not come back")
        dismiss(alert)
    }

    /// **An alert with a text field cannot, and that is the accepted cost of
    /// the reveal side refusing anything with children.**
    ///
    /// A text field gives the alert a child
    /// (`_UIAlertControllerTextFieldViewController`), and the reveal side
    /// cannot tell that child apart from the child screens of a container it
    /// has never met. Refusing costs a black alert; accepting would let an
    /// unrecognised container be approved and reveal everything inside it.
    ///
    /// Asserted so the limitation is recorded rather than rediscovered.
    func testAnApprovedAlertWithATextFieldStillCannotBeRevealed() throws {
        let alert = try present(textField: true, approved: true)
        XCTAssertTrue(policy.cobrowseUnredactedViews(for: alert).isEmpty,
                      "an alert with a text field can now be approved; if that is intended, check "
                      + "what else became approvable with it")
        dismiss(alert)
    }

    /// SwiftUI's own `.alert`, which is what the demo uses. Whether it becomes a
    /// `UIAlertController` at all is the question; if it does not, everything
    /// above is about UIKit alerts only.
    func testWhatASwiftUIAlertBecomes() {
        let host = UIHostingController(rootView: SwiftUIAlertScreen())
        window.rootViewController = host
        window.makeKeyAndVisible()
        host.view.layoutIfNeeded()
        RunLoop.current.run(until: Date(timeIntervalSinceNow: 0.5))

        var presented = host.presentedViewController
        while let controller = presented {
            print("PBD-PROBE swiftui alert → \(type(of: controller)) "
                  + "children=\(controller.children.map { "\(type(of: $0))" }) "
                  + "isAlert=\(controller is UIAlertController) "
                  + "redacted=\(describe(policy.cobrowseRedactedViews(for: controller), of: controller)) "
                  + "unredacted=\(describe(policy.cobrowseUnredactedViews(for: controller), of: controller))")
            presented = controller.presentedViewController
        }

        XCTAssertNotNil(host.presentedViewController, "SwiftUI presented nothing to inspect")
    }

    // MARK: - helpers

    /// The frame the SDK would transmit, with every controller on screen
    /// tracked the way it tracks them live.
    private func frame(policy: RedactByDefaultDelegate?) throws -> CGImage {
        let root = try XCTUnwrap(window.rootViewController)
        return try AgentFrameOracle.frame(
            of: window,
            tracked: AgentFrameOracle.everyController(from: root),
            policy: policy
        )
    }

    private func present(textField: Bool, approved: Bool = false) throws -> UIAlertController {
        let type = approved ? ApprovedAlertController.self : UIAlertController.self
        let alert = type.init(title: "Confirm payment",
                                      message: "Card ending 4242",
                                      preferredStyle: .alert)
        if textField { alert.addTextField { $0.placeholder = "Security code" } }
        alert.addAction(UIAlertAction(title: "Cancel", style: .cancel))

        window.rootViewController?.present(alert, animated: false)
        RunLoop.current.run(until: Date(timeIntervalSinceNow: 0.2))
        alert.view.layoutIfNeeded()
        return alert
    }

    private func dismiss(_ alert: UIAlertController) {
        alert.dismiss(animated: false)
        RunLoop.current.run(until: Date(timeIntervalSinceNow: 0.2))
    }

    private func describe(_ views: [UIView], of controller: UIViewController) -> String {
        guard views.isEmpty == false else { return "none" }
        return views.map { $0 === controller.viewIfLoaded ? "OWN VIEW" : "\(type(of: $0))" }
            .joined(separator: "+")
    }
}

/// A screen that raises a SwiftUI alert as soon as it appears.
struct SwiftUIAlertScreen: View {
    @State private var showing = true
    var body: some View {
        Color.white
            .alert("Confirm payment", isPresented: $showing) {
                TextField("Security code", text: .constant(""))
                Button("Cancel", role: .cancel) {}
            } message: {
                Text("Card ending 4242")
            }
    }
}

/// Approval is a static fact about a type, so the approved and unapproved arms
/// need different types, which is also how an app would really say it. Nobody
/// approves every alert in the process.
final class ApprovedAlertController: UIAlertController {}

extension ApprovedAlertController: ApprovedForCobrowse {}
