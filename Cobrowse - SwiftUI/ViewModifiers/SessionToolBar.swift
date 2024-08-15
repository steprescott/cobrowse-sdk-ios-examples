//
//  SessionToolBar.swift
//  Cobrowse - SwiftUI
//

import SwiftUI

struct SessionToolbar: ViewModifier {
    
    @EnvironmentObject private var session: Session
    @EnvironmentObject private var transactionDetent: Transaction.Detent.State
    
    fileprivate var trackDetent = false

    func body(content: Content) -> some View {
        content
            .toolbar {
                if let session = session.current, session.isActive() {
                    if !trackDetent || transactionDetent.is(.large) {
                        ToolbarItem(placement: .topBarTrailing) {
                            Button(action: { session.end() }) {
                                Image(systemName: "rectangle.badge.xmark")
                            }
                        }
                    }
                }
            }
    }
}

extension View {
    func sessionToolbar(trackDetent: Bool = false) -> some View {
        self.modifier(SessionToolbar(trackDetent: trackDetent))
    }
}


