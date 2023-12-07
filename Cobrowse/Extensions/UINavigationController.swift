//
//  UINavigationController.swift
//  Cobrowse
//

import UIKit

extension UINavigationController {
    
    var rootViews: [UIView] {
        
        var views = [UIView]()
        
        [presentedViewController, visibleViewController]
            .compactMap { $0 }
            .forEach { viewController in
                if let navigationController = viewController as? UINavigationController {
                    views.append(contentsOf: navigationController.rootViews)
                } else {
                    views.append(view)
                }
            }
        
        return views
    }
}
