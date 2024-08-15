//
//  AccountView.swift
//  Cobrowse - SwiftUI
//

import SwiftUI

import CobrowseIO

struct AccountView: View {
    
    @EnvironmentObject private var session: Session
    @EnvironmentObject private var account: Account
    
    @Binding var isPresented: Bool

    var body: some View {
        NavigationStack {
            VStack {
                
                AccountView.Heading()
                
                Color.Cobrowse.background.ignoresSafeArea()
                
                VStack {
                    
                    if !(session.current?.isActive() ?? false) {
                        if let code = session.current?.code() {
                            let string = "\(code.prefix(3)) - \(code.suffix(3))"
                            Text(string)
                                .font(.largeTitle)
                                .foregroundStyle(Color.Cobrowse.text)
                        }
                        
                        Button { CobrowseIO.instance().createSession() }
                            label: {
                                Text("Get session code")
                                    .frame(minWidth: 200)
                            }
                        .buttonStyle(.borderedProminent)
                        
                        NavigationLink(destination: AgentPresentView(isPresented: $isPresented)) {
                            Text("Agent Present Mode")
                                .frame(minWidth: 200)
                                .foregroundColor(Color.Cobrowse.primary)
                        }
                        .buttonStyle(.borderedProminent)
                        .tint(Color.Cobrowse.secondary)
                    }
                    
                    Button("Logout") {
                        account.isSignedIn = false
                    }
                    .padding(.top, 8)

                }
                .padding(.bottom, 20)
            }
            .background { Color.Cobrowse.background.ignoresSafeArea() }
            .navigationTitle("Account")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button { isPresented = false }
                        label: { Image(systemName: "xmark") }
                }
            }
            .sessionToolbar()
        }
        .onDisappear {
            guard let current = session.current, !current.isActive()
            else { return }
            
            session.current = nil
        }
    }
}

extension AccountView {
    struct Heading: View {
        
        var body: some View {
            VStack {
                Image(systemName: "person.crop.circle.fill")
                    .resizable()
                    .aspectRatio(1, contentMode: .fit)
                    .frame(height: 120)
                    .foregroundColor(Color.Cobrowse.primary)
                
                Details(
                    name: "Frank Spencer",
                    email: "f.spencer@example.com"
                )
            }
        }
    }
}

extension AccountView.Heading {
    struct Details: View {
        
        let name: String
        let email: String
        
        var body: some View {
            VStack(spacing: 2) {
                Text(name)
                    .font(.largeTitle)
                    .foregroundStyle(Color.Cobrowse.text)
                
                Text(verbatim: email)
                    .font(.title2)
                    .foregroundStyle(Color.Cobrowse.text)
            }
        }
    }
}
