//
//  Transaction+List.swift
//  Cobrowse - SwiftUI
//

import SwiftUI

extension Transaction {
    
    struct List: View {
        
        @ObservedObject private var navigation = Navigation()
        
        @EnvironmentObject private var account: Account
        
        private let transactions: [Transaction]
        
        private var transactionsByMonth: [Dictionary<Date, [Transaction]>.Element] {
            Dictionary(grouping: account.transactions, by: { $0.date.startOfMonth })
                .sorted { $0.key > $1.key }
        }
        
        var body: some View {
            NavigationStack(path: $navigation.path) {
                SwiftUI.List {
                    ForEach(transactionsByMonth, id: \.key) { (date, transactions) in
                        Section(header: Text(date.string!)) {
                            ForEach(transactions) { transaction in
                                Item(for: transaction)
                                    .cobrowseSelector(tag: "Item")
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
            }
            .sessionToolbar(trackDetent: true)
            .environmentObject(navigation)
        }
        
        init(transactions: [Transaction]) {
            self.transactions = transactions
        }
    }
}
