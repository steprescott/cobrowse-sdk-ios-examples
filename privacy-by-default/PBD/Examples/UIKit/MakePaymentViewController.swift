//
//  MakePaymentViewController.swift
//  PBD
//

import UIKit

/// The UIKit twin of `MakePaymentView`.
///
/// Here so the two policies can be compared on the same screen: UIKit draws its
/// text through `UILabel` and `UITextField`, which is what
/// `RedactedByRegexDelegate` can actually read, a subview walk over the
/// SwiftUI version finds nothing at all.
final class MakePaymentViewController: UIViewController {

    private let amountField = UITextField()
    private let totalLabel = UILabel()

    override func viewDidLoad() {
        super.viewDidLoad()

        title = "Make Payment"
        view.backgroundColor = .systemGroupedBackground
        addViewDetails()

        let amountLabel = UILabel()
        amountLabel.text = "Amount"
        amountLabel.font = .preferredFont(forTextStyle: .subheadline)
        amountLabel.textColor = .secondaryLabel

        // The pound sign lives on its own label, exactly as it does in the
        // SwiftUI screen, so a pattern matching `£` hides the symbol and
        // leaves the number beside it.
        let currencyLabel = UILabel()
        currencyLabel.text = "£"
        currencyLabel.font = .systemFont(ofSize: 22)
        currencyLabel.textColor = .secondaryLabel
        currencyLabel.setContentHuggingPriority(.required, for: .horizontal)

        amountField.text = "10.00"
        amountField.placeholder = "Amount"
        amountField.font = .systemFont(ofSize: 22)
        amountField.addTarget(self, action: #selector(amountChanged), for: .editingChanged)
        amountField.keyboardType = .decimalPad
        amountField.borderStyle = .roundedRect

        let amountRow = UIStackView(arrangedSubviews: [currencyLabel, amountField])
        amountRow.axis = .horizontal
        amountRow.spacing = 8
        amountRow.alignment = .center

        // Symbol and value on one label, so a match hides both together.
        totalLabel.font = .preferredFont(forTextStyle: .footnote)
        totalLabel.textColor = .secondaryLabel
        updateTotal()

        let cardsLabel = UILabel()
        cardsLabel.text = "Pay with"
        cardsLabel.font = .preferredFont(forTextStyle: .subheadline)
        cardsLabel.textColor = .secondaryLabel

        // Each row shows a masked card number, which the pattern matches as
        // readily as it matches a pound sign. One screen, two kinds of text
        // worth hiding.
        let cardButtons = SavedCard.onFile.enumerated().map { index, card -> SavedCardRow in
            let row = SavedCardRow(card: card)
            row.tag = index
            row.addTarget(self, action: #selector(savedCardTapped), for: .touchUpInside)
            return row
        }

        var newCardConfiguration = UIButton.Configuration.filled()
        newCardConfiguration.title = "Add new payment method"
        newCardConfiguration.cornerStyle = .large
        newCardConfiguration.buttonSize = .large

        let newCardButton = UIButton(configuration: newCardConfiguration)
        newCardButton.addTarget(self, action: #selector(addNewCardTapped), for: .touchUpInside)

        let column = UIStackView(arrangedSubviews:
            [amountLabel, amountRow, totalLabel, cardsLabel] + cardButtons + [newCardButton])
        column.axis = .vertical
        column.spacing = 8
        column.setCustomSpacing(24, after: totalLabel)
        column.setCustomSpacing(24, after: cardButtons.last ?? totalLabel)
        column.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(column)

        NSLayoutConstraint.activate([
            column.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor, constant: 24),
            column.leadingAnchor.constraint(equalTo: view.layoutMarginsGuide.leadingAnchor),
            column.trailingAnchor.constraint(equalTo: view.layoutMarginsGuide.trailingAnchor)
        ])
    }

    private var amount: String {
        let typed = amountField.text ?? ""
        return typed.isEmpty ? "0.00" : typed
    }

    @objc private func amountChanged() {
        updateTotal()
    }

    private func updateTotal() {
        totalLabel.text = "You will pay £\(amount) today"
    }

    @objc private func addNewCardTapped() {
        let details = PaymentDetailsViewController(amount: amount) { [weak self] card in
            guard let self else { return }
            self.review(with: card)
        }

        navigationController?.pushViewController(details, animated: true)
    }

    @objc private func savedCardTapped(_ sender: SavedCardRow) {
        review(with: SavedCard.onFile[sender.tag])
    }

    private func review(with card: SavedCard) {
        let review = PaymentReviewViewController(amount: amount, card: card)
        navigationController?.pushViewController(review, animated: true)
    }
}
