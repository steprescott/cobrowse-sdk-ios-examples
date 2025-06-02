//
//  SessionControlView.swift
//  Cobrowse - SwiftUI
//

import SwiftUI

extension CobrowseSession.Control {

    struct View: SwiftUI.View {
        
        @EnvironmentObject var session: CobrowseSession
        
        var body: some SwiftUI.View {
            
            if session.controlState == .visible {
                Color.clear
                    .overlay(alignment: .top) {
                        Color.cbPrimary
                            .ignoresSafeArea(edges: .top)
                            .frame(height: 0)
                            .offset(y: -5)
                    }
            } else {
                Color.clear
            }
        }
    }
}
