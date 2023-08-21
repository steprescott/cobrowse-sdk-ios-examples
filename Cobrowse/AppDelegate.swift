//
//  AppDelegate.swift
//  Cobrowse
//

import UIKit
import CobrowseIO

let session = Session()

@main
class AppDelegate: UIResponder, UIApplicationDelegate {
    
    var window: UIWindow?
    
    func application(_ application: UIApplication, didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?) -> Bool {
        
        let cobrowse = CobrowseIO.instance()
        
        cobrowse.license = "trial"
        
        cobrowse.customData = [
            kCBIOUserEmailKey: "ios@demo.com",
            kCBIODeviceNameKey: "iOS Demo"
        ] as [String : NSObject]
        
        cobrowse.webviewRedactedViews = [
            "#title",
            "#amount",
            "#subtitle",
            "#map"
        ]
        
        cobrowse.delegate = session
        
        cobrowse.start()
        
        return true
    }
    
    func application(_ application: UIApplication, continue userActivity: NSUserActivity, restorationHandler: @escaping ([UIUserActivityRestoring]?) -> Void) -> Bool {
        guard let url = userActivity.webpageURL
            else { return false }
        
        return DeepLinker.handle(url)
    }
}
