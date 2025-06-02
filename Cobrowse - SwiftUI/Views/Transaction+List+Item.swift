//
//  Transaction+List+Item.swift
//  Cobrowse - SwiftUI
//

import SwiftUI

extension Transaction.List {
    
    struct Item: View {
        private let transaction: Transaction
        
        var body: some View {
            NavigationLink(value: transaction) {
                HStack {
                    transaction.category.icon
                        .resizable()
                        .aspectRatio(contentMode: .fit)
                        .padding(4)
                        .frame(width: 40, height: 40)
                        .foregroundColor(transaction.category.color)
                        .accessibilityIdentifier("TRANSACTION_CATEGORY")
                    
                    VStack(alignment:.leading, spacing: 2) {
                        Text(transaction.title)
                            .font(.body)
                            .foregroundStyle(Color.text)
                            .accessibilityIdentifier("TRANSACTION_TITLE")
                            .cobrowseRedacted()
                        
                        Text(transaction.subtitle)
                            .font(.caption2)
                            .foregroundStyle(Color.text)
                            .accessibilityIdentifier("TRANSACTION_SUBTITLE")
                            .cobrowseRedacted()
                    }
                    Spacer()
                    if let amount = transaction.amount.currencyString {
                        Text(amount)
                            .fontWeight(.bold)
                            .foregroundStyle(Color.cbPrimary)
                            .accessibilityIdentifier("TRANSACTION_AMOUNT")
                            .cobrowseRedacted()
                    }
                }
            }
        }
        
        init(for transaction: Transaction) {
            self.transaction = transaction
        }
    }
}
