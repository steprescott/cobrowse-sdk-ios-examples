//
//  Session.swift
//  Cobrowse
//

import Foundation
import CobrowseSDK
import Combine

class CobrowseSession: NSObject, ObservableObject, CobrowseIODelegate {
    
    @Published var current: CBIOSession?
    @Published var controlState: CobrowseSession.Control.State = .hidden

    @AppStorage("privateByDefault")
    var privateByDefault = false
    
    func cobrowseSessionDidUpdate(_ session: CBIOSession) {
        current = session
    }
    
    func cobrowseSessionDidEnd(_ session: CBIOSession) {
        current = nil
    }
    
    func cobrowseShowSessionControls(_ session: CBIOSession) {
        controlState = .visible
    }
    
    func cobrowseHideSessionControls(_ session: CBIOSession) {
        controlState = .hidden
    }
}

extension CobrowseSession {
    enum Control {
        enum State {
            case visible, hidden
        }
    }
}

#if canImport(SwiftUI)
import SwiftUI

extension CobrowseSession {
    struct Setting: Identifiable {
        let id = UUID()
        let title: String
        let binding: Binding<Bool>

        init(title: String, keyPath: ReferenceWritableKeyPath<CobrowseSession, Bool>) {
            self.title = title
            self.binding = Binding(
                get: { cobrowseSession[keyPath: keyPath] },
                set: { cobrowseSession[keyPath: keyPath] = $0 }
            )
        }
    }
}
#endif
