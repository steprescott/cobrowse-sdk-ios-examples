//
//  AccountView.swift
//  Cobrowse - SwiftUI
//

import SwiftUI

import CobrowseSDK

struct AccountView: View {
    
    @EnvironmentObject private var cobrowseSession: CobrowseSession
    
    @Binding var isPresented: Bool

    @State private var showSettings = false
    
    var body: some View {
        NavigationStack {
            VStack {
                Heading()
                    .cobrowseSelector(tag: "Heading")

                Spacer()
                
                VStack {
                    if !(cobrowseSession.current?.isActive() ?? false) {
                        Actions.SessionCode()
                        Actions.AgentPresent()
                    }
                    
                    Actions.Logout()
                        .cobrowseUnredacted()
                }
                .padding(.bottom, 20)
            }
            .frame(maxWidth: .infinity)
            .background { Color.background.ignoresSafeArea() }
            .navigationTitle("Account")
            .navigationBarTitleDisplayMode(.inline)
            .navigationDestination(isPresented: $showSettings, destination: {
                SettingsView()
            })
            .toolbar {
                ToolbarItem(placement: .topBarLeading) {
                    Button { showSettings = true }
                    label: {
                        Image(systemName: "gearshape")
                    }
                    .tint(Color.cbPrimary)
                    .accessibilityIdentifier("SETTINGS_BUTTON")
                    .cobrowseUnredacted()
                }
            }
            .closeModelToolBar(unredact: true)
            .sessionToolbar(unredact: true)
            .cobrowseRedacted(if: cobrowseSession.privateByDefault)
        }
        .onDisappear {
            guard let current = cobrowseSession.current, !current.isActive()
                else { return }
            
            cobrowseSession.current = nil
        }
        .onPreferenceChange(CloseModelKey.self) {
            isPresented = !$0
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
                    .foregroundColor(Color.cbPrimary)
                    .accessibilityIdentifier("ACCOUNT_PROFILE_IMAGE")
                
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
        
        @EnvironmentObject private var cobrowseSession: CobrowseSession
        
        let name: String
        let email: String
        
        var body: some View {
            VStack(spacing: 2) {
                Text(name)
                    .font(.largeTitle)
                    .foregroundStyle(Color.text)
                    .accessibilityIdentifier("ACCOUNT_NAME")
                
                Text(verbatim: email)
                    .font(.title2)
                    .foregroundStyle(Color.text)
                    .accessibilityIdentifier("ACCOUNT_EMAIL")
                    .cobrowseRedacted()
            }
            .cobrowseSelector(tag: "VStack")
        }
    }
}


extension AccountView {
    
    enum Actions {
        
        struct SessionCode: View {
            
            @EnvironmentObject private var cobrowseSession: CobrowseSession
            
            var body: some View {
                VStack {
                    if let code = cobrowseSession.current?.code() {
                        let string = "\(code.prefix(3)) - \(code.suffix(3))"
                        Text(string)
                            .font(.largeTitle)
                            .foregroundStyle(Color.text)
                    }
                    
                    Button { CobrowseIO.instance().createSession() }
                    label: {
                        Text("Get session code")
                            .frame(minWidth: 200)
                            .foregroundColor(Color.cbSecondary)
                    }
                    .buttonStyle(.borderedProminent)
                    .tint(Color.cbPrimary)
                    .accessibilityIdentifier("SESSION_CODE_BUTTON")
                }
            }
        }
        
        struct AgentPresent: View {
            
            var body: some View {
                NavigationLink(destination: AgentPresentView()) {
                    Text("Agent Present Mode")
                        .frame(minWidth: 200)
                        .foregroundColor(Color.cbPrimary)
                }
                .buttonStyle(.borderedProminent)
                .tint(Color.cbSecondary)
                .accessibilityIdentifier("AGENT_PRESENT_BUTTON")
            }
        }
        
        struct Logout: View {
            
            @EnvironmentObject private var account: Account
            
            var body: some View {
                Button("Logout") {
                    account.isSignedIn = false
                }
                .tint(Color.cbPrimary)
                .padding(.top, 8)
                .accessibilityIdentifier("LOGOUT_BUTTON")
            }
        }
    }
}
