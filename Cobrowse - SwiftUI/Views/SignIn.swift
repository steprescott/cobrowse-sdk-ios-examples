//
//  SignIn.swift
//  Cobrowse - SwiftUI
//

import SwiftUI

struct SignIn: View {
    
    @EnvironmentObject private var account: Account
    
    @State private var username = ""
    @State private var password = ""
    
    @FocusState private var focusField: Field?
    
    private var invalidField: Field? {
        switch (username.isEmpty, password.isEmpty) {
            case (true, _): return .username
            case (_, true): return .password
            default: return nil
        }
    }
    
    var body: some View {
        NavigationStack {
            VStack {
                Spacer()
                    .frame(height:40)
                
                if let icon = Locale.current.currency?.icon {
                    icon
                        .resizable()
                        .aspectRatio(1, contentMode: .fit)
                        .frame(maxWidth: 200)
                        .padding()
                        .foregroundColor(Color.cbPrimary)
                }
                
                Text("Please enter your details")
                    .foregroundStyle(Color.text)
                
                VStack(spacing: 4) {
                    TextField("Username", text: $username)
                        .textFieldStyle(.roundedBorder)
                        .multilineTextAlignment(.center)
                        .focused($focusField, equals: .username)
                        .onSubmit { signIn() }
                        .accessibilityIdentifier("INPUT_USERNAME")
                        .cobrowseRedacted()
                    
                    SecureField("Password", text: $password)
                        .textFieldStyle(.roundedBorder)
                        .multilineTextAlignment(.center)
                        .focused($focusField, equals: .password)
                        .onSubmit { signIn() }
                        .accessibilityIdentifier("INPUT_PASSWORD")
                        .cobrowseRedacted()
                }
                .padding(.horizontal, 16)
                .frame(maxWidth: 500)
                
                Button {
                    signIn()
                } label: {
                    Text("Sign in")
                        .fontWeight(.semibold)
                        .frame(minWidth: 120)
                        .foregroundColor(Color(invalidField == nil ? "CBSecondary" : "Text"))
                }
                .buttonStyle(.borderedProminent)
                .disabled(invalidField != nil)
                .padding(.top, 16)
                .accessibilityIdentifier("SIGN_IN_BUTTON")
                
                Spacer()
            }
            .background { Color.background.ignoresSafeArea() }
            .sessionToolbar()
        }

    }
    
    private func signIn() {
        focusField = invalidField
        
        guard invalidField == nil
            else { return }
        
        account.isSignedIn = true
    }
}

extension SignIn {
    
    enum Field {
        case username, password
    }
}
