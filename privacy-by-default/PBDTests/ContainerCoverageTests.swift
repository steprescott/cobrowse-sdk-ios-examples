import XCTest
import SwiftUI
@testable import PBD

/// **A container the policy has never met must not let what it shows reach the
/// agent.**
///
/// The reveal side refuses anything with children, so a custom container can
/// never be approved. The cover side blankets the window, so its children are
/// under the blanket whether or not anything recognises the container. This is
/// the guarantee that has to hold whatever either side is written as, asked of
/// the transmitted frame rather than of the returned arrays.
@MainActor
final class ContainerCoverageTests: XCTestCase {

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

    func testAnUnrecognisedContainersContentDoesNotReachTheAgent() throws {
        let container = CustomContainer()
        window.rootViewController = container
        window.makeKeyAndVisible()
        container.view.layoutIfNeeded()

        XCTAssertFalse(container.children.isEmpty, "the fixture should have children")

        let tracked = AgentFrameOracle.everyController(from: container)
        XCTAssertTrue(
            try AgentFrameOracle.frame(of: window, tracked: tracked, policy: nil).containsSentinelGreen,
            "precondition: the child renders at all")

        XCTAssertFalse(
            try AgentFrameOracle.frame(of: window, tracked: tracked, policy: policy).containsSentinelGreen,
            "an unrecognised container let its child reach the agent")
    }

    /// A custom container: a child screen, and none of UIKit's container
    /// classes involved. The child is unapproved, because an approved child
    /// inside an unrecognised container is a screen and is rightly revealed;
    /// what must hold is that the container itself cannot be, and that its
    /// unapproved content stays under the blanket.
    final class CustomContainer: UIViewController {
        override func viewDidLoad() {
            super.viewDidLoad()
            let child = UIHostingController(rootView: Color(red: 0, green: 1, blue: 0))
            addChild(child)
            view.addSubview(child.view)
            child.view.frame = view.bounds
            child.didMove(toParent: self)
        }
    }
}

extension CGImage {

    /// The sentinel the container fixtures paint, spelled by component because
    /// `Color.green`'s blue channel is too high to read as green.
    var containsSentinelGreen: Bool {
        (try? pixels(in: CGRect(x: 0, y: 0, width: width, height: height)))?
            .contains { $0.red <= 80 && $0.green >= 180 && $0.blue <= 80 } ?? false
    }
}
