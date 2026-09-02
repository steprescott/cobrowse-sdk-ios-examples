//
//  MakePaymentView.swift
//  PBD
//
//  Created by Ste on 29/08/2026.
//

import SwiftUI
import CobrowseSDK

/// `NavigationStack` driven by boolean destinations, as a contrast with
/// `MakePaymentPathView`'s typed path.
///
/// Nothing here approves anything. This screen and every destination it pushes
/// are hidden by default and revealed only by `Approvals.swift`.
///
/// The single `cobrowseRedacted()` below goes the other way: it hides the
/// amount field *because* the screen around it is revealed.
struct MakePaymentView: View {

    @Environment(\.dismiss) private var dismiss

    @State private var amount: String = "10.00"
    @State private var showingDetails = false
    @State private var showingExplainMyBill = false
    /// Two, because a `navigationDestination` presents from the view it is
    /// attached to. Both declared here would sit at the same depth, and
    /// activating one while the other is showing replaces it rather than
    /// pushing on top, so the review reached from the card entry screen is
    /// declared there instead.
    @State private var reviewingSavedCard: SavedCard?
    @State private var reviewingNewCard: SavedCard?

    var body: some View {
        NavigationStack {
            Form {
                Section("Amount") {
                    HStack {
                        Text("£")
                            .foregroundStyle(.secondary)
                        TextField("Amount", text: $amount)
                            .keyboardType(.decimalPad)
                            .cobrowseRedacted()
                    }
                }

                Section("Pay with") {
                    ForEach(SavedCard.onFile) { card in
                        Button {
                            reviewingSavedCard = card
                        } label: {
                            SavedCardRowView(card: card)
                        }
                        .foregroundStyle(.primary)
                    }
                }

                Section {
                    Button {
                        showingDetails = true
                    } label: {
                        Text("Add new payment method")
                            .frame(maxWidth: .infinity)
                            .bold()
                    }
                    .buttonStyle(.borderedProminent)
                    .listRowInsets(EdgeInsets())
                    .listRowBackground(Color.clear)

                    Button {
                        showingExplainMyBill = true
                    } label: {
                        Text("Explain My Bill")
                            .frame(maxWidth: .infinity)
                    }
                    .buttonStyle(.bordered)
                    .listRowInsets(EdgeInsets())
                    .listRowBackground(Color.clear)
                }
            }
            .navigationTitle("Make Payment")
            .navigationBarTitleDisplayMode(.inline)
            .navigationDestination(isPresented: $showingDetails) {
                PaymentDetailsView(amount: amount) { reviewingNewCard = $0 }
                    .navigationDestination(item: $reviewingNewCard) { card in
                        PaymentReviewView(amount: amount, card: card) { dismiss() }
                    }
            }
            .navigationDestination(item: $reviewingSavedCard) { card in
                PaymentReviewView(amount: amount, card: card) { dismiss() }
            }
            .navigationDestination(isPresented: $showingExplainMyBill) {
                ExplainMyBillView()
            }
            .closable()
            .viewDetails(isApproved: isApproved)
            .cobrowseUnredactedIfNeeded()
        }
        .closesModal()

    }
}
