//
//  JourneyBView.swift
//  PBD
//
//  Created by Ste on 29/08/2026.
//

import SwiftUI

/// The other half of the pair. See `JourneyAView`.
struct JourneyBView: View {
    var body: some View {
        VStack(spacing: 16) {
            Text("Journey B")
                .font(.largeTitle).bold()

            Text("The second journey in the flow.")
                .font(.subheadline)
                .foregroundStyle(.secondary)
        }
        .padding()
        .navigationTitle("Journey B")
        .viewDetails(isApproved: isApproved)
        .cobrowseUnredactedIfNeeded()
    }
}
