import SwiftUI
import SafariServices
import CobrowseSDK

struct SettingsView: View {
    
    @State private var showingPrivacyPolicy = false
    
    private let settings: [CobrowseSession.Setting] = [
        .init(title: "Private by Default", keyPath: \.privateByDefault),
    ]

    var body: some View {
        VStack(spacing: 10) {
            ForEach(settings) { setting in
                Toggle(setting.title, isOn: setting.binding)
                    .tint(Color.cbPrimary)
            }
            .padding(.horizontal, 20)
            
            Spacer()
            
            Button("Privacy Policy") {
                showingPrivacyPolicy = true
            }
            .accessibilityIdentifier("PRIVACY_POLICY_BUTTON")
        }
        .frame(maxWidth: .infinity)
        .background { Color.background.ignoresSafeArea() }
        .navigationTitle("Settings")
        .closeModelToolBar()
        .sessionToolbar()
        .cobrowseRedacted(if: cobrowseSession.privateByDefault)
        .sheet(isPresented: $showingPrivacyPolicy) {
            SafariView(url: "https://cobrowse.io/privacy")
        }
    }
}
