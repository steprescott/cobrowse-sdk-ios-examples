//
//  PresentationPlaygroundViewController.swift
//  PBD
//

import UIKit

// The UIKit twins. Same shape as the SwiftUI playground: two types with
// identical bodies, one approved and one not, each able to present either at
// the next depth as a sheet, a cover or a popover.

// Nothing but the type name differs, which is the point. Approval is per type,
// and each reads its own from the policy.

/// The approved half of the pair.
final class ApprovedPresentationViewController: PresentationPlaygroundViewController {}

/// The other half.
final class UnapprovedPresentationViewController: PresentationPlaygroundViewController {}

/// The UIKit twin of `PresentationPlayground`.
class PresentationPlaygroundViewController: UIViewController, UIPopoverPresentationControllerDelegate {

    private let depth: Int

    init(depth: Int) {
        self.depth = depth
        super.init(nibName: nil, bundle: nil)
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func viewDidLoad() {
        super.viewDidLoad()

        view.backgroundColor = .systemBackground
        addViewDetails()

        let title = UILabel()
        title.text = "\(isApproved ? "Approved" : "Unapproved") · depth \(depth)"
        title.font = .preferredFont(forTextStyle: .title2)
        title.textAlignment = .center


        let headers = row(of: [
            header("Approved", color: .systemGreen), header("Unapproved", color: .systemRed)
        ])

        let rows = [UIModalPresentationStyle.pageSheet, .overFullScreen, .popover].map { style in
            row(of: [button(style, approved: true), button(style, approved: false)])
        }

        let column = UIStackView(arrangedSubviews: [title, headers] + rows)
        column.axis = .vertical
        column.spacing = 12
        column.setCustomSpacing(24, after: title)
        column.translatesAutoresizingMaskIntoConstraints = false

        view.addSubview(column)

        NSLayoutConstraint.activate([
            column.centerYAnchor.constraint(equalTo: view.centerYAnchor),
            column.leadingAnchor.constraint(equalTo: view.layoutMarginsGuide.leadingAnchor),
            column.trailingAnchor.constraint(equalTo: view.layoutMarginsGuide.trailingAnchor)
        ])
    }

    private func row(of views: [UIView]) -> UIStackView {
        let row = UIStackView(arrangedSubviews: views)
        row.axis = .horizontal
        row.spacing = 8
        row.distribution = .fillEqually
        return row
    }

    /// Names the column, so each button does not have to repeat it.
    private func header(_ title: String, color: UIColor) -> UILabel {
        let label = UILabel()
        label.text = title
        label.font = .preferredFont(forTextStyle: .subheadline).withWeight(.semibold)
        label.textColor = color
        label.textAlignment = .center
        return label
    }

    private func button(_ style: UIModalPresentationStyle, approved: Bool) -> UIButton {
        var configuration = UIButton.Configuration.bordered()
        configuration.title = name(for: style)
        configuration.baseForegroundColor = approved ? .systemGreen : .systemRed
        // Tinted fill, matching the SwiftUI twin: approved and unapproved should
        // be tellable apart without reading the label.
        configuration.baseBackgroundColor = (approved ? UIColor.systemGreen : .systemRed)
            .withAlphaComponent(0.15)
        configuration.cornerStyle = .capsule
        configuration.buttonSize = .large
        // One line, or a wrapped title makes its row taller than the others and
        // the grid stops being a grid. `titleLabel` cannot say this, so a
        // configuration owns the title, and settings on the label are ignored.
        configuration.titleLineBreakMode = .byTruncatingTail
        configuration.titleTextAttributesTransformer = .init { attributes in
            var attributes = attributes
            attributes.font = .preferredFont(forTextStyle: .subheadline)
            return attributes
        }

        let button = UIButton(configuration: configuration)
        button.tag = style.rawValue * 2 + (approved ? 1 : 0)
        button.addTarget(self, action: #selector(presentTapped), for: .touchUpInside)
        return button
    }

    private func name(for style: UIModalPresentationStyle) -> String {
        switch style {
        case .overFullScreen: "Cover"
        case .popover: "Popover"
        default: "Sheet"
        }
    }

    @objc private func presentTapped(_ sender: UIButton) {
        let style = UIModalPresentationStyle(rawValue: sender.tag / 2) ?? .pageSheet
        let approved = sender.tag % 2 == 1

        let next: UIViewController = approved
            ? ApprovedPresentationViewController(depth: depth + 1)
            : UnapprovedPresentationViewController(depth: depth + 1)

        let presented = next.closable
        presented.modalPresentationStyle = style

        if style == .popover {
            presented.preferredContentSize = CGSize(width: 380, height: 380)
            presented.popoverPresentationController?.sourceView = sender
            presented.popoverPresentationController?.sourceRect = sender.bounds
            presented.popoverPresentationController?.delegate = self
        }

        present(presented, animated: true)
    }


    /// Keeps a popover a popover on iPhone, rather than adapting to a sheet.
    func adaptivePresentationStyle(
        for controller: UIPresentationController,
        traitCollection: UITraitCollection
    ) -> UIModalPresentationStyle {
        .none
    }
}

private extension UIFont {

    func withWeight(_ weight: UIFont.Weight) -> UIFont {
        UIFont.systemFont(ofSize: pointSize, weight: weight)
    }
}
