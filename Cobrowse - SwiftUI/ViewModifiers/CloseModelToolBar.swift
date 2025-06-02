//
//  SessionToolBar.swift
//  Cobrowse - SwiftUI
//

import SwiftUI

struct CloseModelToolBar: ViewModifier {

    fileprivate let unredact: Bool
    
    @EnvironmentObject private var cobrowseSession: CobrowseSession
    
    @State var closeModel: Bool = false
    
    func body(content: Content) -> some View {
        content
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button { closeModel = true }
                    label: { Image(systemName: "xmark") }
                        .tint(Color.cbPrimary)
                        .accessibilityIdentifier("CLOSE_BUTTON")
                        .cobrowseUnredacted(if: unredact)
                }
            }
            .preference(key: CloseModelKey.self, value: closeModel)
    }
}

extension View {
    
    func closeModelToolBar(unredact: Bool = false) -> some View {
        self.modifier(CloseModelToolBar(unredact: unredact))
    }
}

struct CloseModelKey: PreferenceKey {
    
    static let defaultValue: Bool = false
    
    static func reduce(value: inout Bool, nextValue: () -> Bool) {
        value = value || nextValue()
    }
}
