import XCTest
import SwiftUI
@testable import PBD

/// **Every shape the app puts on screen, approved by conformance alone.**
///
/// There is no other route now: a tab's declaration and a popover's screen are
/// reached as values, by evaluating a body once per type, so the same
/// `is ApprovedForCobrowse` answers everywhere. This walks every shape and
/// NAMES the ones reached, so a screen the walk has stopped reaching is
/// noticed — and named — rather than discovered by a customer.
@MainActor
final class ConformanceCoverageTests: XCTestCase {

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

    func testEveryApprovedShapeIsReachedByConformance() throws {
        var approved: [String] = []

        for (label, make) in Self.shapes {
            let host = make()
            window.rootViewController = host
            window.makeKeyAndVisible()
            host.view.layoutIfNeeded()
            RunLoop.current.run(until: Date(timeIntervalSinceNow: 0.5))
            host.view.layoutIfNeeded()

            for controller in AgentFrameOracle.everyController(from: host) where controller.children.isEmpty {

                // As if on screen: an unselected tab has not loaded its view,
                // and the policy reveals only loaded views.
                controller.loadViewIfNeeded()

                guard policy.cobrowseUnredactedViews(for: controller).isEmpty == false
                    else { continue }

                XCTAssertTrue(controller.cobrowseVerdict.isApproved, "\(label): revealed without an approving verdict")
                approved.append("\(label)  \(type(of: controller))")
            }
        }

        print("PBD-PROBE approved: \(approved.count)")
        approved.forEach { print("PBD-PROBE   \($0)") }

        // ⚠ NAMED, NOT COUNTED. A count says a shape left and not WHICH, and a
        // count is also the thing that gets quietly lowered: this gate read
        // `>= 17` and went to 16 when the approval demo's tabs became
        // conditional, which is by design — a container with a conditional tab
        // is unidentifiable on purpose. Read as a count that looked like a
        // regression; read as a list it says exactly what changed.
        let reached = Set(approved.map { $0.split(separator: "  ").first.map(String.init) ?? $0 })

        // Every shape whose screen the walk MUST still reach. "approval demo"
        // is deliberately absent: its conditional tabs are unidentifiable by
        // design.
        let required: Set<String> = [
            "plain", "stack", "path stack", "tabs", "carried destination",
            "pushed choice", "sheet", "plain approved", "alerts host",
            "modified", "erased", "erased and modified", "pushed plain",
            "cover", "popover",
        ]

        XCTAssertEqual(required.subtracting(reached), [],
                       "these shapes stopped being reached by conformance")
    }

    /// Every shape the app puts on screen, and a few the app does not, hosted
    /// the way the app hosts them.
    static let shapes: [(String, () -> UIViewController)] = [
        ("plain", { UIHostingController(rootView: JourneyBView()) }),
        ("stack", { UIHostingController(rootView: MakePaymentView()) }),
        ("path stack", { UIHostingController(rootView: MakePaymentPathView()) }),
        ("tabs", { UIHostingController(rootView: TabsDemoView()) }),
        ("approval demo", { UIHostingController(rootView: ConditionalApprovalDemoView()) }),
        // Left the approval demo, where it taught an unrelated lesson. Kept as
        // its own shape so the count still covers a screen whose type names
        // the NEXT screen's destination.
        ("carried destination", { UIHostingController(rootView: CarriedDestinationView()) }),
        ("pushed choice", { UIHostingController(rootView: PushesAChoice()) }),
        ("sheet", { UIHostingController(rootView: PresentsAnApprovedSheet()) }),
        ("plain approved", { UIHostingController(rootView: ContactUsView()) }),
        ("plain unapproved", { UIHostingController(rootView: JourneyAView()) }),
        ("alerts host", { UIHostingController(rootView: AlertsDemoView()) }),
        ("modified", { UIHostingController(rootView: JourneyBView().padding().opacity(0.99)) }),
        ("erased", { UIHostingController(rootView: AnyView(ContactUsView())) }),
        ("erased and modified", { UIHostingController(rootView: AnyView(JourneyBView().padding())) }),
        ("pushed plain", { UIHostingController(rootView: PushesAPlainDestination()) }),
        ("cover", { UIHostingController(rootView: PresentsApproved(kind: .cover)) }),
        ("popover", { UIHostingController(rootView: PresentsApproved(kind: .popover)) }),
    ]
}

/// A stack that pushes a plain destination, so the pushed leaf is answered by
/// the walk into its box rather than by the ancestor fallback.
struct PushesAPlainDestination: View {
    var body: some View {
        NavigationStack {
            Color.white.navigationDestination(isPresented: .constant(true)) { ContactUsView() }
        }
    }
}
