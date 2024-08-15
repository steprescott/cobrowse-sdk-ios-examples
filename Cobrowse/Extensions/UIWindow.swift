//
//  UIWindow.swift
//  Cobrowse
//

import UIKit
import Combine

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
    
    static func present(_ viewController: UIViewController, animated: Bool = true) {
        guard
            let rootViewController = UIWindow.keyWindow?.rootViewController,
            let presentedViewController = rootViewController.presentedViewController
        else { return }
        
        if let nav = presentedViewController as? UINavigationController,
           let visibleViewController = nav.visibleViewController {
            visibleViewController.present(viewController, animated: true)
        } else {
            presentedViewController.present(viewController, animated: true)
        }
    }
}

extension UIWindow {
    
    func subscribe(to session: Session, using bag: inout Set<AnyCancellable>, for view: SessionControlView) {
        
        guard let height = windowScene?.statusBarManager?.statusBarFrame.height
            else { return }

        addSubview(view)
        bringSubviewToFront(view)

        NSLayoutConstraint.activate([
            view.topAnchor.constraint(equalTo: topAnchor),
            view.leadingAnchor.constraint(equalTo: leadingAnchor),
            view.trailingAnchor.constraint(equalTo: trailingAnchor),
            view.heightAnchor.constraint(equalToConstant: height)
        ])
        
        session.$controlState
            .removeDuplicates()
            .sink { [unowned self] controlState in
                
                self.bringSubviewToFront(view)
                
                view.isHidden = controlState == .hidden
            }
            .store(in: &bag)
    }
}
