//
//  Color.swift
//  Cobrowse - SwiftUI
//

import SwiftUI

extension Color {
    
    enum Cobrowse {
        static var primary: Color {
            Color(red: 88 / 255, green: 13 / 255, blue: 245 / 255)
        }
        
        static var secondary: Color {
            Color(red: 224 / 255, green: 245 / 255, blue: 127 / 255, opacity: 1)
        }
        
        static var background: Color {
            Color(red: 248 / 255, green: 247 / 255, blue: 254 / 255)
        }
        
        static var text: Color {
            Color(red: 85 / 255, green: 85 / 255, blue: 85 / 255)
        }
        
        static var controlBar: Color {
            Color(red: 178 / 255, green: 103 / 255, blue: 245 / 255)
        }

    }
}
