//
//  JourneyAView.swift
//  PBD
//
//  Created by Ste on 29/08/2026.
//

import SwiftUI

/// One of a pair of plain pushed screens, so a push can move between an
/// approved and an unapproved screen with nothing else differing.
struct JourneyAView: View {
    var body: some View {
        VStack(spacing: 16) {
            Text("Journey A")
                .font(.largeTitle).bold()

            Text("The first journey in the flow.")
                .font(.subheadline)
                .foregroundStyle(.secondary)
        }
        .padding()
        .navigationTitle("Journey A")
        .viewDetails(isApproved: isApproved)
    }
}
