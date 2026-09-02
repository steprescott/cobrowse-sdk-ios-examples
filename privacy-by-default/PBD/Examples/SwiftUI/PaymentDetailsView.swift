//
//  PaymentDetailsView.swift
//  PBD
//
//  Created by Ste on 29/08/2026.
//

import SwiftUI

/// Card entry, the screen with something genuinely worth hiding on it.
struct PaymentDetailsView: View {
    let amount: String
    let onEntered: (SavedCard) -> Void

    @State private var cardNumber: String = ""
    @State private var expiry: String = ""
    @State private var cvv: String = ""
    @State private var cardholderName: String = ""

    var body: some View {
        Form {
            Section("Card") {
                TextField("Card number", text: $cardNumber)
                    .keyboardType(.numberPad)
                    .textContentType(.creditCardNumber)

                HStack {
                    TextField("MM/YY", text: $expiry)
                        .keyboardType(.numbersAndPunctuation)
                    Divider()
                    TextField("CVV", text: $cvv)
                        .keyboardType(.numberPad)
                }

                TextField("Cardholder name", text: $cardholderName)
                    .textInputAutocapitalization(.words)
                    .textContentType(.name)
            }

            Section {
                Button {
                    onEntered(.entered(number: cardNumber))
                } label: {
                    Text("Continue to review")
                        .frame(maxWidth: .infinity)
                        .bold()
                }
                .buttonStyle(.borderedProminent)
                .listRowInsets(EdgeInsets())
                .listRowBackground(Color.clear)
            }
        }
        .navigationTitle("New Payment Method")
        .navigationBarTitleDisplayMode(.inline)
        .closable()
        .viewDetails(isApproved: isApproved)
    }
}
