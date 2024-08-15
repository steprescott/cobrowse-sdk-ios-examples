//
//  Locale.Currency+SwiftUI.swift
//  Cobrowse
//

import SwiftUI

extension Locale.Currency {
    
    var icon: Image {
        switch identifier {
            case "USD": return Image(systemName: "dollarsign.square")
            case "EUR": return Image(systemName: "eurosign.square")
            case "JPY": return Image(systemName: "yensign.square")
            default: return Image(systemName: "sterlingsign.square")
        }
    }
}
