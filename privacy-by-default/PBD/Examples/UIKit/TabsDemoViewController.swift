import UIKit

/// The UIKit twin of `TabsDemoView`.
///
/// Its tabs are UIKit view controllers, not hosted SwiftUI views, otherwise the
/// policy would identify each tab by the type it hosts, and the screen would be
/// a SwiftUI demo wearing a tab bar. Here a tab is named by its own controller
/// class, which is the route `ApprovedForCobrowse` conformance on a
/// `UIViewController` exists for.
final class TabsDemoViewController: UITabBarController {

    override func viewDidLoad() {
        super.viewDidLoad()

        title = "Tabs (UIKit)"


        let approved = ApprovedTabViewController()
        approved.tabBarItem = UITabBarItem(
            title: "Approved",
            image: UIImage(systemName: "checkmark.circle"),
            tag: 0
        )

        let unapproved = UnapprovedTabViewController()
        unapproved.tabBarItem = UITabBarItem(
            title: "Unapproved",
            image: UIImage(systemName: "eye.slash"),
            tag: 1
        )

        let payment = MakePaymentViewController()
        payment.tabBarItem = UITabBarItem(
            title: "Payment",
            image: UIImage(systemName: "creditcard"),
            tag: 2
        )

        viewControllers = [approved, unapproved, payment]
    }
}

/// The UIKit twin of `ApprovedTabView`. Named in `Approvals.swift`.
final class ApprovedTabViewController: UIViewController {

    override func viewDidLoad() {
        super.viewDidLoad()

        view.backgroundColor = .systemBackground
        addViewDetails()

        show(
            title: "Approved tab",
            figure: "£1,240.55"
        )
    }
}

/// The UIKit twin of `UnapprovedTabView`. Deliberately absent from
/// `Approvals.swift`.
final class UnapprovedTabViewController: UIViewController {

    override func viewDidLoad() {
        super.viewDidLoad()

        view.backgroundColor = .systemBackground
        addViewDetails()

        show(
            title: "Unapproved tab",
            figure: "Sort code 04-00-04 · Account 12345678"
        )
    }
}

private extension UIViewController {

    /// A title, a line of explanation and a figure, the same three things both
    /// SwiftUI tabs show, drawn through `UILabel` so the regex policy can read
    /// them too.
    func show(title: String, figure: String) {
        let titleLabel = UILabel()
        titleLabel.text = title
        titleLabel.font = .preferredFont(forTextStyle: .largeTitle)


        let figureLabel = UILabel()
        figureLabel.text = figure
        figureLabel.font = .preferredFont(forTextStyle: .title2)
        figureLabel.numberOfLines = 0
        figureLabel.textAlignment = .center

        let column = UIStackView(arrangedSubviews: [titleLabel, figureLabel])
        column.axis = .vertical
        column.spacing = 16
        column.alignment = .center
        column.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(column)

        NSLayoutConstraint.activate([
            column.centerYAnchor.constraint(equalTo: view.centerYAnchor),
            column.leadingAnchor.constraint(equalTo: view.layoutMarginsGuide.leadingAnchor),
            column.trailingAnchor.constraint(equalTo: view.layoutMarginsGuide.trailingAnchor)
        ])
    }
}
