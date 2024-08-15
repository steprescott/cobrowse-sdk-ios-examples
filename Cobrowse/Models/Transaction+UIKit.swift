//
//  Transaction+UIKit.swift
//  Cobrowse
//

import UIKit

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
            case .leisure: return UIColor(red: 150/255, green: 161/255, blue: 82/255, alpha: 1)
            case .utilities: return UIColor(red: 92/255, green: 82/255, blue: 161/255, alpha: 1)
        }
    }
}
