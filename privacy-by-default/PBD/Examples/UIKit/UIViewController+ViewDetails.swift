//
//  UIViewController+ViewDetails.swift
//  PBD
//

import UIKit

// Demo chrome: which framework drew this screen, and whether the policy approves
// it. Nothing here knows anything about redaction. What the agent can see is
// the agent's view, not a label this app prints about itself.

extension UIViewController {

    func addViewDetails() {
        let details = UIStackView(arrangedSubviews: [
            pill(tint: .systemBlue) { $0.text = "UIKIT" },
            approvalPill()
        ])

        details.axis = .horizontal
        details.spacing = 6
        details.alignment = .center
        details.translatesAutoresizingMaskIntoConstraints = false

        view.addSubview(details)

        NSLayoutConstraint.activate([
            details.trailingAnchor.constraint(equalTo: view.safeAreaLayoutGuide.trailingAnchor, constant: -16),
            details.bottomAnchor.constraint(equalTo: view.safeAreaLayoutGuide.bottomAnchor, constant: -12)
        ])
    }

    private func approvalPill() -> UIView {
        let tint: UIColor = isApproved ? .systemGreen : .systemRed

        let image = UIImageView(image: UIImage(systemName: isApproved ? "eye" : "eye.slash"))
        image.tintColor = tint
        image.contentMode = .scaleAspectFit

        let container = UIView()
        container.backgroundColor = tint.withAlphaComponent(0.12)
        container.layer.cornerRadius = 9
        container.layer.masksToBounds = true

        image.translatesAutoresizingMaskIntoConstraints = false
        container.addSubview(image)

        NSLayoutConstraint.activate([
            image.widthAnchor.constraint(equalToConstant: 14),
            image.heightAnchor.constraint(equalToConstant: 14),
            image.topAnchor.constraint(equalTo: container.topAnchor, constant: 3),
            image.bottomAnchor.constraint(equalTo: container.bottomAnchor, constant: -3),
            image.leadingAnchor.constraint(equalTo: container.leadingAnchor, constant: 8),
            image.trailingAnchor.constraint(equalTo: container.trailingAnchor, constant: -8)
        ])

        return container
    }

    private func pill(tint: UIColor, configure: (UILabel) -> Void) -> UILabel {
        let label = PaddedLabel()
        configure(label)
        label.font = .systemFont(ofSize: 11, weight: .semibold)
        label.textColor = tint
        label.textAlignment = .center
        label.backgroundColor = tint.withAlphaComponent(0.12)
        label.layer.cornerRadius = 9
        label.layer.masksToBounds = true
        return label
    }
}

/// A label that carries its own padding, so a pill is one view rather than a
/// label inside a container.
private final class PaddedLabel: UILabel {

    private let insets = UIEdgeInsets(top: 3, left: 8, bottom: 3, right: 8)

    override func drawText(in rect: CGRect) {
        super.drawText(in: rect.inset(by: insets))
    }

    override var intrinsicContentSize: CGSize {
        let size = super.intrinsicContentSize

        return CGSize(
            width: size.width + insets.left + insets.right,
            height: size.height + insets.top + insets.bottom
        )
    }
}
