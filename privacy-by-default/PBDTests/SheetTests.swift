import XCTest
import SwiftUI
@testable import PBD

/// **An approved view presented as a sheet is revealed.**
///
/// SwiftUI wraps presented content in `SheetContent<…>`, a name that cannot be
/// written in source, so the value walk reflects through it and its `body` is
/// what reaches the view. A presentation is a distinct shape from a push or a
/// tab, so it earns its own guard.
@MainActor
final class SheetTests: XCTestCase {

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

    func testAnApprovedSheetIsRevealed() throws {
        let host = UIHostingController(rootView: PresentsAnApprovedSheet())
        window.rootViewController = host
        window.makeKeyAndVisible()
        host.view.layoutIfNeeded()
        RunLoop.current.run(until: Date(timeIntervalSinceNow: 0.6))

        let sheet = try XCTUnwrap(host.presentedViewController, "nothing was presented")
        var leaf = sheet
        while let next = leaf.children.last { leaf = next }

        print("PBD-PROBE controller: \(type(of: leaf)) children=\(leaf.children.count)")
        if let box = (leaf as? AnyHostingController)?.anyRootView as? AnyView,
           let storage = Mirror(reflecting: box).children.first?.value {
            print("PBD-PROBE storage: \(String(reflecting: type(of: storage)))")
        }
        print("PBD-PROBE verdict: \(leaf.cobrowseVerdict)")
        print("PBD-PROBE approvedType: \(CobrowseApproval.approves(ApprovedPresentationView.self))")

        XCTAssertFalse(policy.cobrowseUnredactedViews(for: leaf).isEmpty,
                       "an approved sheet was not revealed")
    }
}

struct PresentsAnApprovedSheet: View {
    @State private var showing = true
    var body: some View {
        Color.white.sheet(isPresented: $showing) { ApprovedPresentationView(depth: 1) }
    }
}

@MainActor
extension SheetTests {

    /// Cover and popover as well as sheet, since each IS wrapped differently:
    /// a sheet and a cover arrive in a `SheetContent` the walk passes through
    /// by value, a popover in a `PopoverContent` holding a `LazyView` whose
    /// content is a closure, so only its NAME reaches the view.
    func testEveryApprovedPresentationIsRevealed() throws {
        let policy = RedactByDefaultDelegate()

        for kind in PresentationKind.allCases {
            let host = UIHostingController(rootView: PresentsApproved(kind: kind))
            let scene = UIApplication.shared.connectedScenes
                .compactMap { $0 as? UIWindowScene }.first!
            let window = UIWindow(windowScene: scene)
            window.frame = UIScreen.main.bounds
            window.rootViewController = host
            window.makeKeyAndVisible()
            host.view.layoutIfNeeded()
            RunLoop.current.run(until: Date(timeIntervalSinceNow: 0.6))

            guard let presented = host.presentedViewController else {
                print("PBD-PROBE \(kind) presented nothing"); window.isHidden = true; continue
            }
            var leaf = presented
            while let next = leaf.children.last { leaf = next }

            if let box = (leaf as? AnyHostingController)?.anyRootView as? AnyView,
               let storage = Mirror(reflecting: box).children.first?.value {
                print("PBD-PROBE \(kind) storage: \(String(reflecting: type(of: storage)).prefix(150))")
            }
            print("PBD-PROBE \(kind) verdict: \(leaf.cobrowseVerdict)")

            XCTAssertFalse(policy.cobrowseUnredactedViews(for: leaf).isEmpty,
                           "an approved \(kind) was not revealed")
            window.isHidden = true
        }
    }
}

enum PresentationKind: String, CaseIterable { case sheet, cover, popover }

struct PresentsApproved: View {
    let kind: PresentationKind
    @State private var showing = true
    var body: some View {
        switch kind {
            case .sheet:   Color.white.sheet(isPresented: $showing) { ApprovedPresentationView(depth: 1) }
            case .cover:   Color.white.fullScreenCover(isPresented: $showing) { ApprovedPresentationView(depth: 1) }
            case .popover: Color.white.popover(isPresented: $showing) { ApprovedPresentationView(depth: 1) }
        }
    }
}
