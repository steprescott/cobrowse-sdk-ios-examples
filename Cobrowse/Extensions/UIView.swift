//
//  UIView.swift
//  Cobrowse
//

import UIKit

extension UIView {
    
    func shake() {
        
        let shakeValues = [-5, 5, -5, 5, -3, 3, -2, 2, 0]

        let translation = CAKeyframeAnimation(keyPath: "transform.translation.x")
        translation.timingFunction = CAMediaTimingFunction(name: .linear)
        translation.values = shakeValues
        translation.duration = 1.0

        layer.add(translation, forKey: "shake")
    }
}
