//
//  PaymentDetailsViewController.swift
//  PBD
//

import UIKit

/// The UIKit twin of `PaymentDetailsView`, and deliberately not approved.
///
/// Under `RedactByDefaultDelegate` the whole screen is black. Under
/// `RedactedByRegexDelegate` only the pay button matches the pattern, and every
/// card field is visible, which is the difference between the two policies,
/// shown on one screen.
final class PaymentDetailsViewController: UIViewController {

    private let amount: String
    private let onEntered: (SavedCard) -> Void
    private let cardNumberField = UITextField()

    init(amount: String, onEntered: @escaping (SavedCard) -> Void) {
        self.amount = amount
        self.onEntered = onEntered
        super.init(nibName: nil, bundle: nil)
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func viewDidLoad() {
        super.viewDidLoad()

        title = "New Payment Method"
        navigationItem.largeTitleDisplayMode = .never
        view.backgroundColor = .systemGroupedBackground
        addViewDetails()
        addCloseButton()

        style(cardNumberField, placeholder: "Card number", content: .creditCardNumber)
        cardNumberField.keyboardType = .numberPad

        let expiryField = field(placeholder: "MM/YY")
        let securityCodeField = field(placeholder: "CVV")
        securityCodeField.keyboardType = .numberPad

        let shortRow = UIStackView(arrangedSubviews: [expiryField, securityCodeField])
        shortRow.axis = .horizontal
        shortRow.spacing = 8
        shortRow.distribution = .fillEqually

        let nameField = field(placeholder: "Cardholder name", content: .name)
        nameField.autocapitalizationType = .words

        var configuration = UIButton.Configuration.filled()
        configuration.title = "Continue to review"
        configuration.cornerStyle = .large
        configuration.buttonSize = .large

        let payButton = UIButton(configuration: configuration)
        payButton.addTarget(self, action: #selector(payTapped), for: .touchUpInside)

        let column = UIStackView(arrangedSubviews: [
            cardNumberField, shortRow, nameField, payButton
        ])
        column.axis = .vertical
        column.spacing = 12
        column.setCustomSpacing(24, after: nameField)
        column.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(column)

        NSLayoutConstraint.activate([
            column.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor, constant: 24),
            column.leadingAnchor.constraint(equalTo: view.layoutMarginsGuide.leadingAnchor),
            column.trailingAnchor.constraint(equalTo: view.layoutMarginsGuide.trailingAnchor)
        ])
    }

    private func field(placeholder: String, content: UITextContentType? = nil) -> UITextField {
        let field = UITextField()
        style(field, placeholder: placeholder, content: content)
        return field
    }

    private func style(_ field: UITextField, placeholder: String, content: UITextContentType?) {
        field.placeholder = placeholder
        field.borderStyle = .roundedRect
        field.font = .systemFont(ofSize: 17)
        field.textContentType = content
    }

    @objc private func payTapped() {
        onEntered(.entered(number: cardNumberField.text ?? ""))
    }
}
