//
//  Session.swift
//  Cobrowse
//

import Foundation

import CobrowseIO

class Session: NSObject, CobrowseIODelegate {
    
    @Published var current: CBIOSession?
    
    func cobrowseSessionDidUpdate(_ session: CBIOSession) {
        current = session
    }
    
    func cobrowseSessionDidEnd(_ session: CBIOSession) {
        current = nil
    }
}
