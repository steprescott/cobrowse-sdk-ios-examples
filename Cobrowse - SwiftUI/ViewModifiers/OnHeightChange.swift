//
//  OnHeightChange.swift
//  Cobrowse - SwiftUI
//

import SwiftUI

struct OnHeightChange: ViewModifier {
    
    var didChange: (_ height: Double) -> Void
    
    init(_ didChange: @escaping (_: Double) -> Void) {
        self.didChange = didChange
    }
    
    func body(content: Content) -> some View {
        content
            .background(
                GeometryReader { geometry in
                    Color.clear
                        .onChange(of: geometry.size.height) { _, height in
                            didChange(height)
                        }
                }
            )
    }
}

extension View {
    
    func onHeightChange(_ didChange: @escaping (_ height: Double) -> Void) -> some View {
        self.modifier(OnHeightChange(didChange))
    }
}
