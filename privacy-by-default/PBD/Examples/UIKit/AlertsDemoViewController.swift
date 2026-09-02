//
//  AlertsDemoViewController.swift
//  PBD
//

import UIKit

/// The UIKit twin of `AlertsDemoView`.
///
/// `UIAlertController` presents into a window above the app's own, so this is
/// where a policy that only speaks for the app's window would leave content
/// uncovered.
final class AlertsDemoViewController: UIViewController {

    override func viewDidLoad() {
        super.viewDidLoad()

        title = "Alerts"
        view.backgroundColor = .systemBackground
        addViewDetails()

        let alertButton = UIButton(configuration: .bordered(), primaryAction: UIAction(title: "Alert") { [weak self] _ in
            self?.presentAlert()
        })

        let sheetButton = UIButton(configuration: .bordered(), primaryAction: UIAction(title: "Action sheet") { [weak self] _ in
            self?.presentActionSheet()
        })

        let column = UIStackView(arrangedSubviews: [alertButton, sheetButton])
        column.axis = .vertical
        column.spacing = 12
        column.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(column)

        NSLayoutConstraint.activate([
            column.centerYAnchor.constraint(equalTo: view.centerYAnchor),
            column.leadingAnchor.constraint(equalTo: view.layoutMarginsGuide.leadingAnchor),
            column.trailingAnchor.constraint(equalTo: view.layoutMarginsGuide.trailingAnchor)
        ])
    }

    private func presentAlert() {
        let alert = UIAlertController(
            title: "Confirm payment",
            message: "Card ending 4242 · £1,240.55",
            preferredStyle: .alert
        )

        alert.addTextField { $0.placeholder = "Security code" }
        alert.addAction(UIAlertAction(title: "Cancel", style: .cancel))

        present(alert, animated: true)
    }

    private func presentActionSheet() {
        let sheet = UIAlertController(title: "Pay with", message: nil, preferredStyle: .actionSheet)

        for card in SavedCard.onFile {
            sheet.addAction(UIAlertAction(title: "\(card.nickname) \(card.maskedNumber)", style: .default))
        }

        sheet.addAction(UIAlertAction(title: "Cancel", style: .cancel))
        sheet.popoverPresentationController?.sourceView = view
        sheet.popoverPresentationController?.sourceRect = view.bounds

        present(sheet, animated: true)
    }
}
