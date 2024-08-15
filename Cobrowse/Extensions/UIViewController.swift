//
//  UIViewController.swift
//  Cobrowse
//

import UIKit

extension UIViewController {
    
    func performSegue(to segue: Segue) {
        performSegue(withIdentifier: segue.rawValue, sender: self)
    }
}

extension UIViewController {
    
    func configureSheet(dismissable: Bool = false, detents: [UISheetPresentationController.Detent] = [ .medium() ]) {
        
        isModalInPresentation = !dismissable
        modalPresentationStyle = .pageSheet
        
        guard let sheet = sheetPresentationController
            else { return }
        
        sheet.detents = detents
    }
}
