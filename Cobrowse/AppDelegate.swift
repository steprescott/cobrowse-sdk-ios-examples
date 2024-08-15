//
//  AppDelegate.swift
//  Cobrowse
//

import UIKit
import Combine
import CobrowseIO

let account = Account()
let session = Session()

@main
class AppDelegate: UIResponder, UIApplicationDelegate {
    
    var window: UIWindow?
    
    private var sessionControlView = SessionControlView()
    private var bag = Set<AnyCancellable>()
    
    func application(_ application: UIApplication, didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?) -> Bool {
        
        let cobrowse = CobrowseIO.instance()
        
        cobrowse.license = "trial"
        
        cobrowse.customData = [
            kCBIOUserEmailKey: "ios@example.com",
            kCBIODeviceNameKey: "iOS Demo"
        ] as [String : NSObject]
        
        cobrowse.webviewRedactedViews = [
            "#title",
            "#amount",
            "#subtitle",
            "#map"
        ]
        
        cobrowse.delegate = session
        
        Demo.setup() // Check if launching from https://cobrowse.io/demo
        
        cobrowse.start()
        
        if let window = window {
            window.subscribe(to: session, using: &bag, for: sessionControlView)
        }
        
        return true
    }
    
    func application(_ application: UIApplication, continue userActivity: NSUserActivity, restorationHandler: @escaping ([UIUserActivityRestoring]?) -> Void) -> Bool {
        guard let url = userActivity.webpageURL
            else { return false }
        
        return DeepLinker.handle(url)
    }
}
