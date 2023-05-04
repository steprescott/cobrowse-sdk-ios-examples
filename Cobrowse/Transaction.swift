//
//  Transaction.swift
//  Cobrowse
//

import UIKit

struct Transaction {
    
    let title: String
    let subtitle: String
    let amount: Double
    let date: Date
    let category: Category
    
    enum Category: String, CaseIterable {
        
        case childcare, groceries, leisure, utilities
    }
}

extension Transaction {
    
    static func generate(_ count: Int,
                         for categories: [Category] = Category.allCases,
                         between range: ClosedRange<Date>) -> [Transaction] {
        
        let transactions = (1...count).map { _ in
            let category = categories.randomElement()!
            
            let date = Date.random(between: range)
            let title = category.title
            let subtitle = "\(date.day.ordinalString ?? "Unkown") at \(date.timeString ?? "Unknown")"
            let amount = Double.random(in: category.amountRange)
            
            return Transaction(title: title,
                               subtitle: subtitle,
                               amount: amount,
                               date: date,
                               category: category)
        }
        
        return transactions.sorted { $0.date > $1.date }
    }
}

extension Transaction.Category {
    
    var icon: UIImage {
        switch self {
            case .childcare: return UIImage(systemName: "figure.and.child.holdinghands")!
            case .groceries: return UIImage(systemName: "cart")!
            case .leisure: return UIImage(systemName: "theatermask.and.paintbrush")!
            case .utilities: return UIImage(systemName: "lightbulb.2")!
        }
    }
    
    var color: UIColor {
        switch self {
            case .childcare: return UIColor(red: 82/255, green: 161/255, blue: 136/255, alpha: 1)
            case .groceries: return UIColor(red: 82/255, green: 135/255, blue: 161/255, alpha: 1)
            case .leisure: return UIColor(red: 92/255, green: 82/255, blue: 161/255, alpha: 1)
            case .utilities: return UIColor(red: 150/255, green: 161/255, blue: 82/255, alpha: 1)
        }
    }
    
    var title: String {
        switch self {
            case .childcare: return ["Bright Horizons", "KinderCare", "Tutor Time", "Busy Bees"].randomElement()!
            case .groceries: return ["Tesco", "Walmart", "Kroger", "Sainsbury's", "Asda", "Morrisons"].randomElement()!
            case .leisure: return ["Netflix", "Amazon Prime Video", "Hulu", "Now TV", "Sky", "Disney+"].randomElement()!
            case .utilities: return ["British Gas", "EDF Energy", "NPower", "EON", "SSE", "Verizon", "AT&T", "Comcast"].randomElement()!
        }
    }
    
    var amountRange: ClosedRange<Double> {
        switch self {
            case .childcare: return 80...900
            case .groceries: return 10...200
            case .leisure: return 3...20
            case .utilities: return 60...200
        }
    }
}
