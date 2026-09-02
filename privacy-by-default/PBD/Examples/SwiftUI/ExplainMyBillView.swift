//
//  ExplainMyBillView.swift
//  PBD
//
//  Created by Ste on 29/08/2026.
//

import SwiftUI

/// The middle of a three-deep stack, so the demo can show approval changing
/// from one screen to the next rather than one screen at a time.
struct ExplainMyBillView: View {

    @Environment(\.dismiss) private var dismiss

    @State private var showingContactUs = false

    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("Explain My Bill")
                .font(.largeTitle).bold()

            Text("Your bill has three parts:")
                .font(.subheadline)
                .foregroundStyle(.secondary)

            VStack(alignment: .leading, spacing: 8) {
                Label("Line rental, a fixed monthly charge.", systemImage: "house")
                Label("Usage, including calls, texts and data.", systemImage: "chart.bar")
                Label("Taxes and fees.", systemImage: "percent")
            }

            Button("Contact Us") { showingContactUs = true }
                .buttonStyle(.bordered)

            Spacer()
        }
        .padding()
        .navigationTitle("Explain My Bill")
        .navigationBarTitleDisplayMode(.inline)
        .closable()
        .navigationDestination(isPresented: $showingContactUs) {
            ContactUsView()
        }
        .viewDetails(isApproved: isApproved)
        .cobrowseUnredactedIfNeeded()
    }
}
