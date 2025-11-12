
import UIKit

class SceneDelegate: UIResponder, UIWindowSceneDelegate {

    var window: UIWindow?
    var sessionControlWindow: SessionControlWindow?

    func scene(_ scene: UIScene, willConnectTo session: UISceneSession, options connectionOptions: UIScene.ConnectionOptions) {
        
        guard let windowScene = scene as? UIWindowScene
            else { return }

        sessionControlWindow = SessionControlWindow(for: windowScene, session: cobrowseSession)
    }
    
    func scene(_ scene: UIScene, continue userActivity: NSUserActivity) {
        guard let url = userActivity.webpageURL
            else { return }
        
        DeepLinker.handle(url)
    }
}
