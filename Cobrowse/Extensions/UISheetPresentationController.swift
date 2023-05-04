//
//  UISheetPresentationController.swift
//  Cobrowse
//

import UIKit

extension UISheetPresentationController.Detent {
    
    static func small() -> UISheetPresentationController.Detent {
        UISheetPresentationController.Detent.custom(identifier: .small) { context in
            context.maximumDetentValue * 0.4
        }
    }
}

extension UISheetPresentationController.Detent.Identifier {
    
    static let small = UISheetPresentationController.Detent.Identifier(Detent.small.rawValue)
}
