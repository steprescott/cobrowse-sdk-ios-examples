//
//  RootView.swift
//  Cobrowse - SwiftUI
//

import SwiftUI

struct RootView: View {
    
    @EnvironmentObject private var account: Account
    @Environment(\.horizontalSizeClass) var horizontalSizeClass
    
    var body: some View {
        
        if account.isSignedIn {
            if horizontalSizeClass == .compact {
                NavigationStack {
                    Dashboard(shouldPresentTransactionsSheet: true)
                }
            } else {
                NavigationSplitView {
                    Transaction.List(transactions: account.transactions)
                } detail: {
                    NavigationStack {
                        Dashboard(shouldPresentTransactionsSheet: false)
                    }
                }
            }
        } else {
            SignIn()
        }
    }
}
