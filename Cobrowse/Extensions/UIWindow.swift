//
//  UIWindow.swift
//  Cobrowse
//

import UIKit

extension UIWindow {
    
    var rootViews: [UIView] {
        
        guard isKeyWindow
            else { return [] }
        
        var views = [UIView]()

        if let navigationController = rootViewController as? UINavigationController {
            views.append(contentsOf: navigationController.rootViews)
        } else if let view = rootViewController?.view {
            views.append(view)
        }
        
        return views
    }
    
    static var keyWindow: UIWindow? {
        UIApplication.shared.connectedScenes
            .compactMap({ $0 as? UIWindowScene })
            .flatMap({ $0.windows })
            .first(where: { $0.isKeyWindow })
    }
}
