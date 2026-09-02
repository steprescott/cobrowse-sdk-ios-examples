import UIKit
import SwiftUI
import CobrowseSDK

extension View {
    /// Marks a SwiftUI view as unredacted.
    ///
    /// Only apply to SwiftUI views hosted at the root of a UIHostingViewController. Has no effect on standard SwiftUI view placements.
    func cobrowseUnredactedScreen() -> some View {
        background(UnredactionMarker())
    }
}

/// Contains the ViewControllers for the SwiftUI views that have been marked as approved by `.cobrowseUnredactedScreen`
enum CobrowseUnredactionRegistry {
    static var controllers = NSHashTable<UIViewController>.weakObjects()
}

/// An invisible probe view that identifies the UIViewController to unredact for the view that it's attached to.
private struct UnredactionMarker: UIViewRepresentable {
    static func dismantleUIView(_ view: UnredactionMarkerView, coordinator: ()) {
        view.removeUnredaction()
    }

    func makeUIView(context: Context) -> UnredactionMarkerView {
        UnredactionMarkerView(frame: .zero)
    }

    func updateUIView(_ view: UnredactionMarkerView, context: Context) { }
}

private class UnredactionMarkerView: UIView {

    /// The nearest view controller to this view is the target for unredaction of approved views.
    var nearestViewController: UIViewController? {
        // Walk up the responder chain and find the first UIViewController
        var parent = next
        while let current = parent {
            if let controller = current as? UIViewController { return controller }
            parent = current.next
        }
        return nil
    }

    override func didMoveToWindow() {
        window == nil ? removeUnredaction() : addUnredaction()
    }

    func removeUnredaction() {
        nearestViewController.map(CobrowseUnredactionRegistry.controllers.remove)
    }

    func addUnredaction() {
        nearestViewController.map(CobrowseUnredactionRegistry.controllers.add)
    }
}
