//
//  Session.swift
//  Cobrowse
//

import Foundation
import CobrowseIO

class Session: NSObject, ObservableObject, CobrowseIODelegate {
    
    @Published var current: CBIOSession?
    @Published var controlState: Session.Control.State = .hidden
    
    @UserDefault(key: "isRedactionByDefaultEnabled", defaultValue: false)
    var isRedactionByDefaultEnabled: Bool
    
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

extension Session {
    enum Control {
        enum State {
            case visible, hidden
        }
    }
}
