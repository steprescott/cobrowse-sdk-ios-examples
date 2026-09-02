import UIKit
import SwiftUI
import CobrowseSDK

/// A CobrowseIODelegate that implements Privacy By Default and allows only approved views to be unredacted.
final class CobrowseRedactByDefaultDelegate: NSObject, CobrowseIODelegate {

    func cobrowseRedactedViews(for viewController: UIViewController) -> [UIView] {
        // Redact all windows connected to the app.
        UIApplication.shared.connectedScenes.compactMap { $0 as? UIWindowScene }.flatMap(\.windows)
    }

    func cobrowseUnredactedViews(for viewController: UIViewController) -> [UIView] {
        // Return only the view for view controllers that have been marked as unredacted.
        guard CobrowseUnredactionRegistry.controllers.allObjects.contains(viewController) else { return [] }
        return [viewController.view]
    }

    func cobrowseSessionDidUpdate(_ session: CBIOSession) {}
    func cobrowseSessionDidEnd(_ session: CBIOSession) {}
}
