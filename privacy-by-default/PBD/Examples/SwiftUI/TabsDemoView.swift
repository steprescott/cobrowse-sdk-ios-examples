import SwiftUI

/// A SwiftUI `TabView`.
///
/// Its tabs can only be named from this container's `Body`: each tab's own
/// controller hosts a SwiftUI-internal type that says nothing about which tab
/// it is.
struct TabsDemoView: View {

    var body: some View {
        tabs
    }

    private var tabs: some View {
        TabView {
            ApprovedTabView()
                .tabItem { Label("Approved", systemImage: "checkmark.circle") }

            UnapprovedTabView()
                .tabItem { Label("Unapproved", systemImage: "eye.slash") }

            MakePaymentView()
                .tabItem { Label("Payment", systemImage: "creditcard") }
        }
    }
}

/// One of the tabs. Approval keys on this type.
struct ApprovedTabView: View {

    @Environment(\.dismiss) private var dismiss

    var body: some View {
        NavigationStack {
            content
                .navigationTitle("Tabs (SwiftUI)")
                .navigationBarTitleDisplayMode(.inline)
                .closable()
                .viewDetails(isApproved: isApproved)
        }
        .closesModal()
        .cobrowseUnredactedIfNeeded()
    }

    private var content: some View {
        VStack(spacing: 16) {
            Text("Approved tab")
                .font(.largeTitle).bold()

            Text("£1,240.55")
                .font(.title).monospacedDigit()
        }
        .padding()
    }
}

/// Another tab. See `ApprovedTabView`.
struct UnapprovedTabView: View {

    @Environment(\.dismiss) private var dismiss

    var body: some View {
        NavigationStack {
            content
                .navigationTitle("Tabs (SwiftUI)")
                .navigationBarTitleDisplayMode(.inline)
                .closable()
                .viewDetails(isApproved: isApproved)
        }
        .closesModal()
    }

    private var content: some View {
        VStack(spacing: 16) {
            Text("Unapproved tab")
                .font(.largeTitle).bold()

            Text("Sort code 04-00-04 · Account 12345678")
                .font(.callout).monospacedDigit()
        }
        .padding()
    }
}


