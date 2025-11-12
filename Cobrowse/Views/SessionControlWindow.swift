
import UIKit
import Combine

class SessionControlWindow: UIWindow {
    
    private var sessionControlView = SessionControlView()
    private var bag = Set<AnyCancellable>()
    
    init(for windowScene: UIWindowScene, session: CobrowseSession) {
        super.init(windowScene: windowScene)

        let viewController = UIViewController()
        viewController.view.backgroundColor = .clear
        viewController.view.addSubview(sessionControlView)

        NSLayoutConstraint.activate([
            sessionControlView.topAnchor.constraint(equalTo: viewController.view.topAnchor),
            sessionControlView.leadingAnchor.constraint(equalTo: viewController.view.leadingAnchor),
            sessionControlView.trailingAnchor.constraint(equalTo: viewController.view.trailingAnchor),
            sessionControlView.heightAnchor.constraint(equalToConstant: windowScene.statusBarManager?.statusBarFrame.height ?? 40)
        ])

        self.rootViewController = viewController
        self.windowLevel = .alert + 1
        self.isHidden = false
        self.isUserInteractionEnabled = false

        session.$controlState
            .removeDuplicates()
            .sink { [weak self] controlState in
                self?.sessionControlView.isHidden = controlState == .hidden
            }
            .store(in: &bag)
    }
    
    required init?(coder: NSCoder) {
        super.init(coder: coder)
    }
}
