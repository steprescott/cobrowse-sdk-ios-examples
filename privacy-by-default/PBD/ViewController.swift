import UIKit
import SwiftUI

/// The example list, the only screen that is not itself an example.
class ViewController: UIViewController {
    private lazy var router: SwiftUIRouter? = {
        guard let navigationController else { return nil }
        return SwiftUIRouter(navigationController: navigationController)
    }()

    override func viewDidLoad() {
        super.viewDidLoad()

        title = "Examples"
        view.backgroundColor = .systemGroupedBackground
        addViewDetails()

        let subtitleLabel = UILabel()
        subtitleLabel.text = "Every screen is hidden from the agent until Approvals.swift names it. The eye on each screen shows which it is."
        subtitleLabel.font = .systemFont(ofSize: 15, weight: .regular)
        subtitleLabel.textColor = .secondaryLabel
        subtitleLabel.textAlignment = .center
        subtitleLabel.numberOfLines = 0

        let journeyAButton = makeButton(title: "Journey A", style: .filled)
        journeyAButton.addTarget(self, action: #selector(journeyATapped), for: .touchUpInside)

        let journeyBButton = makeButton(title: "Journey B", style: .filled)
        journeyBButton.addTarget(self, action: #selector(journeyBTapped), for: .touchUpInside)

        let paymentButton = makeButton(title: "Make Payment", style: .tinted)
        paymentButton.addTarget(self, action: #selector(paymentTapped), for: .touchUpInside)

        let pathNavButton = makeButton(title: "Make Payment (path)", style: .tinted)
        pathNavButton.addTarget(self, action: #selector(pathNavTapped), for: .touchUpInside)

        let uiKitPaymentButton = makeButton(title: "Make Payment (UIKit)", style: .tinted)
        uiKitPaymentButton.addTarget(self, action: #selector(uiKitPaymentTapped), for: .touchUpInside)

        let playgroundButton = makeButton(title: "Presentations (SwiftUI)", style: .tinted)
        playgroundButton.addTarget(self, action: #selector(playgroundTapped), for: .touchUpInside)

        let tabsButton = makeButton(title: "Tabs (SwiftUI)", style: .tinted)
        tabsButton.addTarget(self, action: #selector(tabsTapped), for: .touchUpInside)

        let uiKitTabsButton = makeButton(title: "Tabs (UIKit)", style: .tinted)
        uiKitTabsButton.addTarget(self, action: #selector(uiKitTabsTapped), for: .touchUpInside)

        let swapButton = makeButton(title: "Swapping root (SwiftUI)", style: .tinted)
        swapButton.addTarget(self, action: #selector(swapTapped), for: .touchUpInside)

        let shapesButton = makeButton(title: "Conditional approval (SwiftUI)", style: .tinted)
        shapesButton.addTarget(self, action: #selector(shapesTapped), for: .touchUpInside)

        let alertsButton = makeButton(title: "Alerts (SwiftUI)", style: .tinted)
        alertsButton.addTarget(self, action: #selector(alertsTapped), for: .touchUpInside)

        let uiKitAlertsButton = makeButton(title: "Alerts (UIKit)", style: .tinted)
        uiKitAlertsButton.addTarget(self, action: #selector(uiKitAlertsTapped), for: .touchUpInside)

        let uiKitPlaygroundButton = makeButton(title: "Presentations (UIKit)", style: .tinted)
        uiKitPlaygroundButton.addTarget(self, action: #selector(uiKitPlaygroundTapped), for: .touchUpInside)

        let stack = UIStackView(arrangedSubviews: [
            subtitleLabel,
            spacer(height: 8),
            journeyAButton,
            journeyBButton,
            spacer(height: 4),
            paymentButton,
            pathNavButton,
            uiKitPaymentButton,
            spacer(height: 4),
            playgroundButton,
            uiKitPlaygroundButton,
            spacer(height: 4),
            tabsButton,
            uiKitTabsButton,
            spacer(height: 4),
            swapButton,
            spacer(height: 4),
            alertsButton,
            uiKitAlertsButton,
            spacer(height: 4),
            shapesButton
        ])
        stack.axis = .vertical
        stack.spacing = 12
        stack.alignment = .fill
        stack.setCustomSpacing(24, after: subtitleLabel)
        stack.translatesAutoresizingMaskIntoConstraints = false

        let scrollView = UIScrollView()
        scrollView.translatesAutoresizingMaskIntoConstraints = false
        scrollView.alwaysBounceVertical = true
        scrollView.addSubview(stack)
        view.addSubview(scrollView)

        NSLayoutConstraint.activate([
            scrollView.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor),
            scrollView.bottomAnchor.constraint(equalTo: view.bottomAnchor),
            scrollView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            scrollView.trailingAnchor.constraint(equalTo: view.trailingAnchor),

            stack.topAnchor.constraint(equalTo: scrollView.contentLayoutGuide.topAnchor, constant: 24),
            stack.bottomAnchor.constraint(equalTo: scrollView.contentLayoutGuide.bottomAnchor, constant: -32),
            stack.leadingAnchor.constraint(equalTo: view.layoutMarginsGuide.leadingAnchor, constant: 8),
            stack.trailingAnchor.constraint(equalTo: view.layoutMarginsGuide.trailingAnchor, constant: -8)
        ])
    }

    private func makeButton(title: String, style: UIButton.Configuration.Style) -> UIButton {
        var config: UIButton.Configuration
        switch style {
        case .tinted:
            config = .tinted()
        default:
            config = .filled()
        }
        config.title = title
        config.cornerStyle = .large
        config.buttonSize = .large
        let button = UIButton(configuration: config)
        button.heightAnchor.constraint(equalToConstant: 50).isActive = true
        return button
    }

    private func spacer(height: CGFloat) -> UIView {
        let v = UIView()
        v.heightAnchor.constraint(equalToConstant: height).isActive = true
        return v
    }

    @objc private func journeyATapped() {
        router?.show(JourneyAView())
    }

    @objc private func journeyBTapped() {
        router?.show(JourneyBView())
    }

    @objc private func paymentTapped() {
        router?.present(MakePaymentView())
    }

    @objc private func playgroundTapped() {
        router?.present(ApprovedPresentationView(depth: 0))
    }

    @objc private func tabsTapped() {
        let hosting = UIHostingController(rootView: TabsDemoView())
        hosting.modalPresentationStyle = .fullScreen
        present(hosting, animated: true)
    }

    @objc private func uiKitTabsTapped() {
        let tabs = TabsDemoViewController().closable
        tabs.modalPresentationStyle = .fullScreen
        present(tabs, animated: true)
    }

    @objc private func uiKitPlaygroundTapped() {
        present(ApprovedPresentationViewController(depth: 0).closable, animated: true)
    }

    @objc private func uiKitPaymentTapped() {
        present(MakePaymentViewController().closable, animated: true)
    }

    @objc private func shapesTapped() {
        router?.present(ConditionalApprovalDemoView())
    }

    @objc private func alertsTapped() {
        router?.present(AlertsDemoView())
    }

    @objc private func uiKitAlertsTapped() {
        present(AlertsDemoViewController().closable, animated: true)
    }

    @objc private func swapTapped() {
        present(SwapDemoViewController().closable, animated: true)
    }

    @objc private func pathNavTapped() {
        present(UIHostingController(rootView: MakePaymentPathView()), animated: true)
    }
}

private extension UIButton.Configuration {
    enum Style {
        case filled
        case tinted
    }
}
