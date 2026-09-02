//
//  PaymentReviewView.swift
//  PBD
//

import SwiftUI

/// The last step: what is about to be paid, and with which card.
///
/// Approved, so an agent can help someone through the confirmation, and it
/// carries both an amount and a masked card number, which is what makes it the
/// interesting screen for `RedactedByRegexDelegate`.
struct PaymentReviewView: View {

    let amount: String
    let card: SavedCard
    let onComplete: () -> Void

    var body: some View {
        Form {
            Section("Paying") {
                LabeledContent("Amount", value: "£\(amount)")
                LabeledContent("Card") {
                    HStack(spacing: 6) {
                        Image(systemName: card.symbolName)
                        Text(card.brand)
                        Text(card.maskedNumber)
                            .monospacedDigit()
                    }
                }
                LabeledContent("Reference", value: "PBD-4471")
            }

            Section {
                Button {
                    onComplete()
                } label: {
                    Text("Complete payment")
                        .frame(maxWidth: .infinity)
                        .bold()
                }
                .buttonStyle(.borderedProminent)
                .listRowInsets(EdgeInsets())
                .listRowBackground(Color.clear)
            }
        }
        .navigationTitle("Review")
        .navigationBarTitleDisplayMode(.inline)
        .closable()
        .viewDetails(isApproved: isApproved)
        .cobrowseUnredactedIfNeeded()
    }
}
