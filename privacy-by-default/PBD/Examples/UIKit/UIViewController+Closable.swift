import UIKit

extension UIViewController {

    /// The close affordance every presented example shows: an X, top right.
    ///
    /// Needs a navigation bar to sit in, so a controller presented on its own has
    /// to be wrapped in a `UINavigationController` first.
    func addCloseButton() {
        navigationItem.rightBarButtonItem = UIBarButtonItem(
            systemItem: .close,
            primaryAction: UIAction { [weak self] _ in self?.dismiss(animated: true) }
        )
    }

    /// This controller in a navigation controller, so it can carry a close button.
    var closable: UINavigationController {
        addCloseButton()

        return UINavigationController(rootViewController: self)
    }
}
