//
//  AppDelegate.swift
//  Cobrowse
//

import UIKit
import CobrowseSDK

let account = Account()
let cobrowseSession = CobrowseSession()

@main
class AppDelegate: UIResponder, UIApplicationDelegate {
    
    var window: UIWindow?
    
    func application(_ application: UIApplication, didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?) -> Bool {
        
        let cobrowse = CobrowseIO.instance()
        
        cobrowse.license = "trial"
        
        cobrowse.customData = [
            CBIOUserEmailKey: "ios@example.com",
            CBIODeviceNameKey: "iOS Demo"
        ]
        
        cobrowse.webviewRedactedViews = [
            "#title",
            "#amount",
            "#subtitle",
            "#map"
        ]
        
        cobrowse.delegate = cobrowseSession
        
        Demo.setup() // Check if launching from https://cobrowse.io/demo
        
        cobrowse.start()

        return true
    }
}
