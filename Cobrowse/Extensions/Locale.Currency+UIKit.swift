//
//  Locale.Currency.swift
//  Cobrowse
//

import UIKit

extension Locale.Currency {
    
    var icon: UIImage? {
            switch identifier {
                case "USD": return UIImage(systemName: "dollarsign.square")
                case "EUR": return UIImage(systemName: "eurosign.square")
                case "JPY": return UIImage(systemName: "yensign.square")
                default: return UIImage(systemName: "sterlingsign.square")
            }
        }
}
