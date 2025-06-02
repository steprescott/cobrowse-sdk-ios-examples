//
//  SessionToolBar.swift
//  Cobrowse - SwiftUI
//

import SwiftUI

struct SessionToolbar: ViewModifier {
    
    @EnvironmentObject private var cobrowseSession: CobrowseSession
    @EnvironmentObject private var transactionDetent: Transaction.Detent.State
    
    fileprivate let trackDetent: Bool
    fileprivate let unredact: Bool
    
    func body(content: Content) -> some View {
        content
            .toolbar {
                if let session = cobrowseSession.current, session.isActive() {
                    if !trackDetent || transactionDetent.is(.large) {
                        ToolbarItem(placement: .topBarTrailing) {
                            Button { session.end() }
                            label: { Image(systemName: "rectangle.badge.xmark") }
                            .tint(Color.cbPrimary)
                            .accessibilityIdentifier("SESSION_END_BUTTON")
                            .cobrowseUnredacted(if: unredact)
                        }
                    }
                }
            }
    }
}

extension View {
    func sessionToolbar(trackDetent: Bool = false, unredact: Bool = false) -> some View {
        self.modifier(SessionToolbar(trackDetent: trackDetent, unredact: unredact))
    }
}


