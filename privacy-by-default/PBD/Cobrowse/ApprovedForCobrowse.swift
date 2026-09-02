import SwiftUI
import UIKit

/// Conform a view or a view controller to reveal it to the agent.
protocol ApprovedForCobrowse {}

enum CobrowseApproval {

    static func approves(_ type: Any.Type) -> Bool {
        type is any ApprovedForCobrowse.Type
    }
}

extension View {

    var isApproved: Bool {
        CobrowseApproval.approves(type(of: self))
    }
}

extension UIViewController {

    var isApproved: Bool {
        CobrowseApproval.approves(type(of: self))
    }
}

// MARK: - Approval travels through SwiftUI's wrappers

// Use the SwiftUI type system to raise the `ApprovedForCobrowse` conformance to
// the public wrappers SwiftUI might use. This avoids the need to read the contents
// of the wrapper in order to know if it is approved. Without this more Mirroring
// would be needed to pull the wrapped value out correctly to check for conformance.

extension ModifiedContent: ApprovedForCobrowse where Content: ApprovedForCobrowse {}
extension Optional: ApprovedForCobrowse where Wrapped: ApprovedForCobrowse {}

// Covers the use of logic branches within SwiftUI Views.
// For example if you conditinally showed a Tab in a TabBar depending of the
// user was signed in but only one side of the condition was approved, only
// the approved content would show leaving the other unapproved branch redacted.
extension _ConditionalContent: ApprovedForCobrowse
    where TrueContent: ApprovedForCobrowse, FalseContent: ApprovedForCobrowse {}
