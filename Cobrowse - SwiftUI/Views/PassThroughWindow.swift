//
//  PassThroughWindow.swift
//  Cobrowse
//

import UIKit

class PassThroughWindow: UIWindow {
    override func hitTest(_ point: CGPoint, with event: UIEvent?) -> UIView? {
        nil
    }
}
