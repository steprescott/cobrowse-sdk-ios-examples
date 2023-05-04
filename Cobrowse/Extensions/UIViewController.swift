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
