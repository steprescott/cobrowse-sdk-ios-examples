import UIKit
import CobrowseSDK

/// Hides every screen from the agent, then reveals the ones `Approvals.swift` names.
final class RedactByDefaultDelegate: NSObject, CobrowseIODelegate {

    /// Guarantees everything on screen is redacted, including newly added journeys, by redacting all the windows.
    /// Approval is not consulted here so there is no decision to get wrong.
    func cobrowseRedactedViews(for viewController: UIViewController) -> [UIView] {

        return UIApplication.shared.connectedScenes
            .compactMap { $0 as? UIWindowScene }
            .flatMap { $0.windows }
    }

    /// Selectivly unredacts views where it's `rootView` conforms to `ApprovedForCobrowse`.
    func cobrowseUnredactedViews(for viewController: UIViewController) -> [UIView] {

        guard let view = viewController.viewIfLoaded,
              shouldUnredact(viewController)
            else { return [] }

        // At this point the content has been found to be approved.
        // Return this view so it can be unredacted and seen by the agent.
        return [view]
    }
    
    private func shouldUnredact(_ viewController: UIViewController) -> Bool {

        // A container is not a screen. Its children answer for themselves.
        guard viewController.children.isEmpty
            else { return false }

        switch viewController.cobrowseVerdict {
            
            // Found `rootView` to be approved
            case .approved: return true
            
            // No conformance found on `rootView`
            case .refused: return false

            // No verdict came from SwiftUI so we ask UIKit
            case .unknown:
                return viewController.isApproved
        }
    }

    func cobrowseSessionDidUpdate(_ session: CBIOSession) {}
    func cobrowseSessionDidEnd(_ session: CBIOSession) {}
}
