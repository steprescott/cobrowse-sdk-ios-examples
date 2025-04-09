//
//  AgentPresentView.swift
//  Cobrowse - SwiftUI
//

import SwiftUI

import CobrowseSDK

struct AgentPresentView: View {
    
    @EnvironmentObject private var session: Session
    
    @Binding var isPresented: Bool
    
    @State var code: String?
    @State var shouldShake = false
    
    var body: some View {
            VStack(spacing: 16) {
                if let session = session.current, session.isActive() {
                    Text("You are now presenting")
                        .font(.title2)
                        .foregroundStyle(Color("Text"))
                    
                    Image(systemName: "rectangle.inset.filled.and.person.filled")
                        .font(.system(size: 120, weight: .thin))
                        .foregroundColor(Color("Primary"))
                    
                    Color("Background")
                } else {
                    VStack(spacing: 16) {
                        Text("Please enter your present code")
                            .font(.title2)
                            .foregroundStyle(Color("Text"))
                        
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
                        
                        Color("Background")
                    }
                }
            }
            .padding(.top, 30)
            .background { Color("Background").ignoresSafeArea() }
            .navigationTitle("Agent Present")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {                
                ToolbarItem(placement: .topBarTrailing) {
                    Button { isPresented = false }
                label: { Image(systemName: "xmark") }
                    .tint(Color("Primary"))
                }
            }
            .sessionToolbar()
        }
}
