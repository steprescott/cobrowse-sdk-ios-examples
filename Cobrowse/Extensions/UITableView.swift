//
//  UITableView.swift
//  Cobrowse
//

import UIKit

extension UITableView {
    
    func dequeueReusableCell<T: UITableViewCell>(_ id: Cells, for indexPath: IndexPath) -> T? {
        dequeueReusableCell(withIdentifier: id.rawValue, for: indexPath) as? T
    }
}
