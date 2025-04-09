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
                    
                    VStack(alignment:.leading, spacing: 2) {
                        Text(transaction.title)
                            .font(.body)
                            .cobrowseRedacted()
                            .foregroundStyle(Color("Text"))
                        
                        Text(transaction.subtitle)
                            .font(.caption2)
                            .cobrowseRedacted()
                            .foregroundStyle(Color("Text"))
                    }
                    Spacer()
                    if let amount = transaction.amount.currencyString {
                        Text(amount)
                            .fontWeight(.bold)
                            .cobrowseRedacted()
                            .foregroundStyle(Color("Primary"))
                    }
                }
            }
        }
        
        init(for transaction: Transaction) {
            self.transaction = transaction
        }
    }
}
