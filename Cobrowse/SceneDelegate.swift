
import UIKit
import Combine

class SceneDelegate: UIResponder, UIWindowSceneDelegate {

    var window: UIWindow?

    private var sessionControlView = SessionControlView()
    private var bag = Set<AnyCancellable>()

    func scene(_ scene: UIScene, willConnectTo session: UISceneSession, options connectionOptions: UIScene.ConnectionOptions) {

        if let window = window {
            window.subscribe(to: cobrowseSession, using: &bag, for: sessionControlView)
        }
    }
    
    func scene(_ scene: UIScene, continue userActivity: NSUserActivity) {
        guard let url = userActivity.webpageURL
            else { return }
        
        DeepLinker.handle(url)
    }
}
