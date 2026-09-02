import SwiftUI
import CobrowseSDK
extension View {
    /// Wrapper around cobrowseUnredactedScreen that only applies when the CobrowseRedactByDefaultDelegate is active
    @ViewBuilder func cobrowseUnredactedIfNeeded() -> some View {
        if CobrowseIO.instance().delegate is CobrowseRedactByDefaultDelegate {
            self.cobrowseUnredactedScreen()
        } else {
            self
        }
    }
}
