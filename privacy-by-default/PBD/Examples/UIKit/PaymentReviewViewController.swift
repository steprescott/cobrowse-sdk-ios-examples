//
//  PaymentReviewViewController.swift
//  PBD
//

import UIKit

/// The UIKit twin of `PaymentReviewView`.
final class PaymentReviewViewController: UIViewController {

    private let amount: String
    private let card: SavedCard

    init(amount: String, card: SavedCard) {
        self.amount = amount
        self.card = card
        super.init(nibName: nil, bundle: nil)
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func viewDidLoad() {
        super.viewDidLoad()

        title = "Review"
        view.backgroundColor = .systemGroupedBackground
        addViewDetails()
        addCloseButton()

        let column = UIStackView(arrangedSubviews: [
            row(title: "Amount", value: "£\(amount)"),
            row(title: card.brand, value: card.maskedNumber),
            row(title: "Reference", value: "PBD-4471")
        ])
        column.axis = .vertical
        column.spacing = 12

        var configuration = UIButton.Configuration.filled()
        configuration.title = "Complete payment"
        configuration.cornerStyle = .large
        configuration.buttonSize = .large

        let completeButton = UIButton(configuration: configuration)
        completeButton.addTarget(self, action: #selector(completeTapped), for: .touchUpInside)

        let outer = UIStackView(arrangedSubviews: [column, completeButton])
        outer.axis = .vertical
        outer.spacing = 32
        outer.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(outer)

        NSLayoutConstraint.activate([
            outer.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor, constant: 24),
            outer.leadingAnchor.constraint(equalTo: view.layoutMarginsGuide.leadingAnchor),
            outer.trailingAnchor.constraint(equalTo: view.layoutMarginsGuide.trailingAnchor)
        ])
    }

    private func row(title: String, value: String) -> UIStackView {
        let titleLabel = UILabel()
        titleLabel.text = title
        titleLabel.textColor = .secondaryLabel

        let valueLabel = UILabel()
        valueLabel.text = value
        valueLabel.textAlignment = .right

        let row = UIStackView(arrangedSubviews: [titleLabel, valueLabel])
        row.axis = .horizontal
        return row
    }

    @objc private func completeTapped() {
        navigationController?.popToRootViewController(animated: true)
    }
}
