//
//  Account.swift
//  Cobrowse
//

import Combine
import Foundation

class Account: ObservableObject {
    
    let balance = 2495.34
    
    @Published var isSignedIn = true
    @Published var transactions: [Transaction] = []
    
    init() {
        loadData()
    }
    
    private func loadData() {
        
        var calendar = Calendar(identifier: .gregorian)
        calendar.timeZone = TimeZone(identifier: "UTC")!
        
        let currentDate = Date()
        let minDate = currentDate.months(ago: 3)!.startOfMonth
        let maxDate = currentDate.months(ago: 1)!.endOfMonth

        self.transactions = recentTransactions + Transaction.generate(30, between: minDate...maxDate)
    }
    
    private var recentTransactions: [Transaction] {
        
        let currentDate = Date()
        let startOfMonth = currentDate.startOfMonth
        
        return [
            Transaction.generate(1, for: [.childcare], between: startOfMonth...currentDate),
            Transaction.generate(2, for: [.groceries], between: startOfMonth...currentDate),
            Transaction.generate(1, for: [.utilities], between: startOfMonth...currentDate)
        ]
        .flatMap { $0 }
        .sorted { $0.date > $1.date }
    }
}
