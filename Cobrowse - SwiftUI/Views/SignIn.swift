//
//  SignIn.swift
//  Cobrowse - SwiftUI
//

import SwiftUI
import Lottie

struct SignIn: View {
    
    @EnvironmentObject private var account: Account
    
    @State private var username = ""
    @State private var password = ""
    @State private var playbackMode: LottiePlaybackMode = .paused

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
            ZStack {
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
                            .onTapGesture(count: 3) {
                                playbackMode = .playing(.fromProgress(0, toProgress: 1, loopMode: .playOnce))
                            }
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

                LottieView(animation: .named("money"))
                    .playbackMode(playbackMode)
                    .animationSpeed(0.7)
                    .animationDidFinish { _ in playbackMode = .paused }
                    .ignoresSafeArea()
                    .allowsHitTesting(false)
            }
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
