//
//  Dashboard.swift
//  Cobrowse - SwiftUI
//

import SwiftUI

struct Dashboard: View {
    
    @State var shouldPresentTransactionsSheet: Bool
    @State private var transactionDetent = Transaction.Detent.State(.collapsed)
    
    @State private var isPresentingAccountSheet = false
    
    @EnvironmentObject private var account: Account
    
    @ObservedObject private var navigation = Navigation()
    
    private let offset = 65.0
    
    var body: some View {
        NavigationStack {
            GeometryReader { geometry in
                VStack(spacing: 0) {
                    
                    Heading()
                        .padding(.top, shouldPresentTransactionsSheet ? offset : 0)
                    
                    if !shouldPresentTransactionsSheet {
                        Color.clear
                    }
                    
                    PieChart(recentTransactions: account.transactions.recentTransactions)
                        .frame(maxWidth: shouldPresentTransactionsSheet ? nil : geometry.size.width,
                               maxHeight: shouldPresentTransactionsSheet ? nil : max(geometry.size.height - offset, 0))
                        .aspectRatio(1, contentMode: .fill)
                        .padding(.horizontal, 6)
                    
                    Spacer()
                    
                    if shouldPresentTransactionsSheet {
                        Color.Cobrowse.background
                            .sheet(isPresented: $shouldPresentTransactionsSheet) {
                                NavigationStack(path: $navigation.path) {
                                    Transaction.List(transactions: account.transactions)
                                }
                                .presentationDetents([.fraction(0.40), .large])
                                .presentationBackgroundInteraction(.enabled(upThrough: .fraction(0.40)))
                                .interactiveDismissDisabled()
                                .onHeightChange { height in
                                    let fractionHeight = (geometry.size.height - offset) * 0.9
                                    transactionDetent.current = height > fractionHeight ? .large : .fraction
                                }
                                .sheet(isPresented: $isPresentingAccountSheet) {
                                    AccountView(isPresented: $isPresentingAccountSheet)
                                }
                            }
                    } else {
                        Color.Cobrowse.background
                            .sheet(isPresented: $isPresentingAccountSheet) {
                                AccountView(isPresented: $isPresentingAccountSheet)
                            }
                    }
                }
                .background {
                    Color.Cobrowse.background
                }
            }
            .ignoresSafeArea()
        }
        .toolbar {
            ToolbarItem(placement: .topBarTrailing) {
                Button { isPresentingAccountSheet = true }
                    label: { Image(systemName: "person.crop.circle") }
            }
        }
        .sessionToolbar()
        .environmentObject(navigation)
        .environmentObject(transactionDetent)
    }
}

extension Dashboard {
    struct Heading: View {
        
        @EnvironmentObject private var account: Account
        
        var body: some View {
            VStack(spacing: 6) {
                Text("Balance")
                    .font(.title3)
                    .foregroundStyle(Color.Cobrowse.text)
                    .redacted()
                
                if let accountBalance = account.balance.currencyString {
                    Text(accountBalance)
                        .font(.title)
                        .foregroundStyle(Color.Cobrowse.primary)
                        .redacted()
                }
            }
        }
    }
}
