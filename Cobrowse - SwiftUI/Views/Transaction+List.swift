//
//  Transaction+List.swift
//  Cobrowse - SwiftUI
//

import SwiftUI

extension Transaction {
    
    struct List: View {
        
        @EnvironmentObject private var account: Account
        
        private let transactions: [Transaction]
        
        private var transactionsByMonth: [Dictionary<Date, [Transaction]>.Element] {
            Dictionary(grouping: account.transactions, by: { $0.date.startOfMonth })
                .sorted { $0.key > $1.key }
        }
        
        var body: some View {
            SwiftUI.List {
                ForEach(transactionsByMonth, id: \.key) { (date, transactions) in
                    Section(header: Text(date.string!)) {
                        ForEach(transactions) { transaction in
                            Item(for: transaction)
                        }
                    }
                }
            }
            .listStyle(.plain)
            .navigationTitle("Transactions")
            .navigationBarTitleDisplayMode(.inline)
            .navigationDestination(for: Transaction.self, destination: { transaction in
                Transaction.Detail(for: transaction)
            })
            .sessionToolbar(trackDetent: true) 
        }
        
        init(transactions: [Transaction]) {
            self.transactions = transactions
        }
    }
}
