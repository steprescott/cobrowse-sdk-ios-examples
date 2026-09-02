//
//  SwiftUIRouter.swift
//  PBD
//
//  Created by Ste on 29/08/2026.
//

import SwiftUI
import UIKit

/// The one place a SwiftUI screen becomes a view controller in this app.
///
/// There is nothing about Cobrowse in here. A hosting controller keeps the
/// concrete type of the screen it hosts, and that is all the policy needs, so
/// a controller made anywhere else, by any means, is treated exactly the same.
final class SwiftUIRouter {

    private weak var navigationController: UINavigationController?

    init(navigationController: UINavigationController) {
        self.navigationController = navigationController
    }

    func show<Screen: View>(_ screen: Screen, animated: Bool = true) {
        navigationController?.pushViewController(
            hostingController(for: screen),
            animated: animated
        )
    }

    func present<Screen: View>(
        _ screen: Screen,
        animated: Bool = true,
        completion: (() -> Void)? = nil
    ) {
        navigationController?.present(
            hostingController(for: screen),
            animated: animated,
            completion: completion
        )
    }

    private func hostingController<Screen: View>(for screen: Screen) -> UIViewController {
        UIHostingController(rootView: screen)
    }
}
