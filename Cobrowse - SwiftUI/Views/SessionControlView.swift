//
//  SessionControlView.swift
//  Cobrowse - SwiftUI
//

import SwiftUI

extension Session.Control {

    struct View: SwiftUI.View {
        
        @EnvironmentObject var session: Session
        
        var body: some SwiftUI.View {
            
            if session.controlState == .visible {
                Color.clear
                    .overlay(alignment: .top) {
                        Color.Cobrowse.controlBar
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
