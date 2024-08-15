//
//  Transaction+Detail.swift
//  Cobrowse - SwiftUI
//

import SwiftUI

extension Transaction {
    
    struct Detail: View {
        
        @EnvironmentObject private var navigation: Navigation
        
        private let transaction: Transaction
        
        private var url: URL {
            var url = URL(string: "https://cobrowseio.github.io/cobrowse-sdk-ios-examples")!
            
            url.append(queryItems: [
                .init(name: "title", value: transaction.title),
                .init(name: "subtitle", value: transaction.subtitle),
                .init(name: "amount", value: transaction.amount.currencyString),
                .init(name: "category", value: transaction.category.rawValue)
            ])
            
            return url
        }
        
        var body: some View {
            WebView(url: url)
                .onNavigation { url in
                    navigation.path.append(url)
                }
                .navigationTitle("Transaction")
                .navigationBarTitleDisplayMode(.inline)
                .sessionToolbar(trackDetent: true)
                .navigationDestination(for: URL.self) { url in
                    WebView(url: url)
                        .navigationTitle("Transaction")
                        .sessionToolbar(trackDetent: true)
                }
        }
        
        init(for transaction: Transaction) {
            self.transaction = transaction
        }
    }
}
