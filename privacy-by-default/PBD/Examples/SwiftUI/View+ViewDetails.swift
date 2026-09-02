//
//  View+ViewDetails.swift
//  PBD
//

import SwiftUI

// Demo chrome: which framework drew this screen, and whether the policy approves
// it. Nothing here knows anything about redaction. What the agent can see is
// the agent's view, not a label this app prints about itself.

extension View {

    /// - Parameter isApproved: the screen's own answer. A modifier sees the
    ///   chain it is attached to rather than the view that began it, so `Self`
    ///   here is a `ModifiedContent`, not the screen, so it has to be passed in.
    func viewDetails(isApproved: Bool) -> some View {
        frame(maxWidth: .infinity, maxHeight: .infinity)
            .overlay(alignment: .bottomTrailing) {
                HStack(spacing: 6) {
                    DetailPill(tint: .purple) { Text("SWIFTUI") }

                    DetailPill(tint: isApproved ? .green : .red) {
                        Image(systemName: isApproved ? "eye" : "eye.slash")
                    }
                }
                .padding(.trailing, 16)
                .padding(.bottom, 12)
            }
    }
}

/// The capsule both details are drawn in.
private struct DetailPill<Content: View>: View {

    let tint: Color
    @ViewBuilder let content: Content

    var body: some View {
        content
            .font(.system(size: 11, weight: .semibold))
            .foregroundStyle(tint)
            .padding(.horizontal, 8)
            .padding(.vertical, 3)
            .background(tint.opacity(0.12), in: Capsule())
    }
}
