//
//  MakePaymentPathView.swift
//  PBD
//
//  Created by Ste on 29/08/2026.
//

import SwiftUI
import CobrowseSDK

/// Routes this stack can push, one type each.
///
/// One type per destination rather than one enum switched over, so that every
/// `navigationDestination` closure returns a single concrete view.
///
/// Not a style preference. SwiftUI erases a destination's type before the SDK
/// is told about it, and what survives is the closure's *static* type, so a
/// `switch` names every branch at once and nothing outside can say which is
/// showing. Reading the built value instead was tried and reverted: that graph
/// keeps views from pushes already dismissed, and a stale one revealed the
/// card details.
struct CardDetailsRoute: Hashable {}

/// One route type per destination. See `CardDetailsRoute`.
struct ExplainBillRoute: Hashable {}

/// One route type per destination. See `CardDetailsRoute`.
struct PaymentReviewRoute: Hashable {
    let card: SavedCard
}

/// `NavigationStack` driven by a typed path, as a contrast with
/// `MakePaymentView`'s boolean destinations.
///
/// Neither inspects its own navigation, and neither approves anything. Every
/// view is hidden by default and `Approvals.swift` decides which are revealed,
/// this one and its destinations alike.
///
/// The single `cobrowseRedacted()` below goes the other way: it hides the
/// amount field *because* the screen around it is revealed.
struct MakePaymentPathView: View {

    @Environment(\.dismiss) private var dismiss

    @State private var path = NavigationPath()
    @State private var amount: String = "10.00"

    var body: some View {
        NavigationStack(path: $path) {
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
                            path.append(PaymentReviewRoute(card: card))
                        } label: {
                            SavedCardRowView(card: card)
                        }
                        .foregroundStyle(.primary)
                    }
                }

                Section {
                    Button {
                        path.append(CardDetailsRoute())
                    } label: {
                        Text("Add new payment method")
                            .frame(maxWidth: .infinity)
                            .bold()
                    }
                    .buttonStyle(.borderedProminent)
                    .listRowInsets(EdgeInsets())
                    .listRowBackground(Color.clear)

                    Button {
                        path.append(ExplainBillRoute())
                    } label: {
                        Text("Explain My Bill")
                            .frame(maxWidth: .infinity)
                    }
                    .buttonStyle(.bordered)
                    .listRowInsets(EdgeInsets())
                    .listRowBackground(Color.clear)
                }
            }
            .navigationTitle("Make Payment (path)")
            .navigationBarTitleDisplayMode(.inline)
            .navigationDestination(for: CardDetailsRoute.self) { _ in
                PaymentDetailsView(amount: amount.isEmpty ? "0.00" : amount) { path.append(PaymentReviewRoute(card: $0)) }
            }
            .navigationDestination(for: PaymentReviewRoute.self) { route in
                PaymentReviewView(amount: amount.isEmpty ? "0.00" : amount, card: route.card) { dismiss() }
            }
            .navigationDestination(for: ExplainBillRoute.self) { _ in
                ExplainMyBillView()
            }
            .closable()
            .viewDetails(isApproved: isApproved)
            .cobrowseUnredactedIfNeeded()
        }
        .closesModal()

    }
}
