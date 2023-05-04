//
//  UIStoryboard.swift
//  Cobrowse
//

import UIKit

extension UIStoryboard {
    
    static var main: UIStoryboard {
        .init(name: "Main", bundle: nil)
    }
    
    func viewControllerWith<T: UIViewController>(id: VC) -> T? {
        instantiateViewController(withIdentifier: id.rawValue) as? T
    }
}
