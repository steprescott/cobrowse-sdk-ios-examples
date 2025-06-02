//
//  AgentPresentView.swift
//  Cobrowse - SwiftUI
//

import SwiftUI

import CobrowseSDK

struct AgentPresentView: View {
    
    @EnvironmentObject private var cobrowseSession: CobrowseSession
    
    @State var code: String?
    @State var shouldShake = false
    
    var body: some View {
            VStack(spacing: 16) {
                if let session = cobrowseSession.current, session.isActive() {
                    Text("You are now presenting")
                        .font(.title2)
                        .foregroundStyle(Color.text)
                    
                    Image(systemName: "rectangle.inset.filled.and.person.filled")
                        .font(.system(size: 120, weight: .thin))
                        .foregroundColor(Color.cbPrimary)
                    
                    Color.background
                } else {
                    VStack(spacing: 16) {
                        Text("Please enter your present code")
                            .font(.title2)
                            .foregroundStyle(Color.text)
                        
                        CodeInput(code: $code)
                            .shake($shouldShake) {
                                shouldShake = false
                                code = nil
                            }
                            .onChange(of: code, { _, _ in
                                guard let code = code
                                    else { return }
                                
                                Task {
                                    do {
                                        let agentSession = try await CobrowseIO.instance().getSession(code)
                                        try await agentSession.set(capabilities: [])
                                    } catch(let error) {
                                        print(error)
                                        shouldShake = true
                                    }
                                }
                            })
                        
                        Color.background
                    }
                }
            }
            .padding(30)
            .background { Color.background.ignoresSafeArea() }
            .navigationTitle("Agent Present")
            .navigationBarTitleDisplayMode(.inline)
            .closeModelToolBar()
            .sessionToolbar()
            .cobrowseRedacted(if: cobrowseSession.privateByDefault)
        }
}
