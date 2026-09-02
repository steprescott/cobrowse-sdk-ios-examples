//
//  AlertsDemoView.swift
//  PBD
//

import SwiftUI

/// An alert and a confirmation dialog, which SwiftUI puts in a window above the
/// app's own.
///
/// So this is the test of whether a screen presented outside the app's window is
/// covered like any other. The screen behind is approved, and the alert over it
/// is not.
struct AlertsDemoView: View {

    @State private var showingAlert = false
    @State private var showingDialog = false
    @State private var securityCode = ""

    var body: some View {
        VStack(spacing: 20) {
            Text("Alerts")
                .font(.title2).bold()

            Button("Alert") { showingAlert = true }
                .buttonStyle(.bordered)
                .controlSize(.large)

            Button("Confirmation dialog") { showingDialog = true }
                .buttonStyle(.bordered)
                .controlSize(.large)

            Spacer()
        }
        .padding()
        // Presented without a navigation stack, so there is no bar for the X to
        // sit in.
        .closableOverContent()
        .viewDetails(isApproved: isApproved)
        .alert("Confirm payment", isPresented: $showingAlert) {
            TextField("Security code", text: $securityCode)
            Button("Cancel", role: .cancel) {}
        } message: {
            Text("Card ending 4242 · £1,240.55")
        }
        .confirmationDialog("Pay with", isPresented: $showingDialog, titleVisibility: .visible) {
            ForEach(SavedCard.onFile) { card in
                Button("\(card.nickname) \(card.maskedNumber)") {}
            }
        }
        .cobrowseUnredactedIfNeeded()
    }
}
