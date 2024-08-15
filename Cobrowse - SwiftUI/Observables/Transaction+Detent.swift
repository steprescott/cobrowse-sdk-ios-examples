//
//  Transaction+Detent.swift
//  Cobrowse - SwiftUI
//

import Combine

extension Transaction {
    enum Detent {
        case collapsed, fraction, large
    }
}

extension Transaction.Detent {
    class State: ObservableObject {
        @Published var current: Transaction.Detent
        
        init(_ detent: Transaction.Detent) {
            self.current = detent
        }
        
        func `is`(_ detent: Transaction.Detent) -> Bool {
            current == detent
        }
    }
}

extension Transaction.Detent.State: Equatable {
    
    static func == (lhs: Transaction.Detent.State, rhs: Transaction.Detent.State) -> Bool {
        switch (lhs.current, rhs.current) {
            case (.collapsed, .collapsed),
                 (.fraction, .fraction),
                 (.large, .large): return true
            default: return false
        }
    }
}
