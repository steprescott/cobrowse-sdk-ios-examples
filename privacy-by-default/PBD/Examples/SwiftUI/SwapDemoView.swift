//
//  SwapDemoView.swift
//  PBD
//

import SwiftUI

// Two screens a hosting controller alternates between, to show that approval
// follows the VALUE a controller is showing rather than the controller itself.
// `SwapDemoViewController` hosts them, and the button swaps which one it holds.

/// One of the two views `SwapDemoViewController` holds.
struct ApprovedSwapView: View {

    let swap: () -> Void

    var body: some View {
        VStack(spacing: 16) {
            Text(isApproved ? "Approved" : "Unapproved")
                .font(.largeTitle).bold()
                .foregroundStyle(isApproved ? .green : .red)

            Text("Swap replaces the `rootView` of this `UIHostingController`. The controller never changes, only the view inside it, so redaction follows what is on screen, not what the controller was when it appeared.")
                .font(.footnote)
                .foregroundStyle(.secondary)
                .multilineTextAlignment(.center)

            Button("Swap", action: swap)
                .buttonStyle(.bordered)
                .controlSize(.large)
        }
        .padding()
        .viewDetails(isApproved: isApproved)
        .cobrowseUnredactedIfNeeded()
    }
}

struct UnapprovedSwapView: View {

    let swap: () -> Void

    var body: some View {
        VStack(spacing: 16) {
            Text(isApproved ? "Approved" : "Unapproved")
                .font(.largeTitle).bold()
                .foregroundStyle(isApproved ? .green : .red)
            

            Text("Swap replaces the `rootView` of this `UIHostingController`. The controller never changes, only the view inside it, so redaction follows what is on screen, not what the controller was when it appeared.")
                .font(.footnote)
                .foregroundStyle(.secondary)
                .multilineTextAlignment(.center)

            Button("Swap", action: swap)
                .buttonStyle(.bordered)
                .controlSize(.large)
        }
        .padding()
        .viewDetails(isApproved: isApproved)
    }
}
