//
//  RawRepresentable.swift
//  Cobrowse
//

import Foundation

extension Equatable where Self: RawRepresentable, Self.RawValue == String {
    
    static func == (lhs: Self, rhs: String?) -> Bool {
        lhs.rawValue == rhs
    }

    static func == (lhs: String?, rhs: Self) -> Bool {
        lhs == rhs.rawValue
    }
    
    static func == (lhs: Self, rhs: String) -> Bool {
        lhs.rawValue == rhs
    }

    static func == (lhs: String, rhs: Self) -> Bool {
        lhs == rhs.rawValue
    }
    
    static func != (lhs: Self, rhs: String) -> Bool {
        lhs.rawValue != rhs
    }
    
    static func != (lhs: String, rhs: Self) -> Bool {
        lhs != rhs.rawValue
    }
    
    static func != (lhs: Self, rhs: String?) -> Bool {
        !(lhs == rhs)
    }
    
    static func != (lhs: String?, rhs: Self) -> Bool {
        !(lhs == rhs)
    }
}
