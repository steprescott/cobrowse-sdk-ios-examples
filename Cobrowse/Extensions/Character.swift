//
//  Character.swift
//  Cobrowse
//

import Foundation

extension Character {
    
    var isDigit: Bool {
        CharacterSet.decimalDigits.isSuperset(of: CharacterSet(charactersIn: String(self)))
    }
}
