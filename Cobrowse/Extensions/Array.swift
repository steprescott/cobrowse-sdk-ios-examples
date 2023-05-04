//
//  Array.swift
//  Cobrowse
//

import Foundation

extension Array where Element == Transaction {
    
    var recentTrnsactions: [Transaction] {
        let date = sorted { $0.date > $1.date }.first!.date.startOfMonth
        
        return filter { transaction in
            transaction.date.isAfterDate(date)
        }
    }
    
    var totalSpent: Double {
        reduce(into: 0.0) { partialResult, transaction in
            partialResult += transaction.amount
        }
    }
}
