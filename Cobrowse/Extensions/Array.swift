//
//  Array.swift
//  Cobrowse
//

import Foundation

extension Array where Element == Transaction {
    
    var recentTransactions: [Transaction] {
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

extension Array where Element == URLQueryItem {
    
    mutating func pop(_ name: String) -> String? {
        guard let index = self.firstIndex(where: { $0.name == name })
            else { return nil }
        
        let item = self[index]
        self.remove(at: index)
        
        return item.value
    }
}

