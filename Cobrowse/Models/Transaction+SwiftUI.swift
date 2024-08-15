//
//  Transaction+SwiftUI.swift
//  Cobrowse
//

import SwiftUI

extension Transaction.Category {
    
    var icon: Image {
        switch self {
            case .childcare: return Image(systemName: "figure.and.child.holdinghands")
            case .groceries: return Image(systemName: "cart")
            case .leisure: return Image(systemName: "theatermask.and.paintbrush")
            case .utilities: return Image(systemName: "lightbulb.2")
        }
    }
    
    var color: Color {
        switch self {
            case .childcare: return Color(red: 82/255, green: 161/255, blue: 136/255)
            case .groceries: return Color(red: 82/255, green: 135/255, blue: 161/255)
            case .leisure: return Color(red: 150/255, green: 161/255, blue: 82/255)
            case .utilities: return Color(red: 92/255, green: 82/255, blue: 161/255)
        }
    }
}
