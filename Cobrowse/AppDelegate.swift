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
        cobrowse.start()
        cobrowse.delegate = session
        
        cobrowse.customData = [
            kCBIOUserEmailKey: "ios@demo.com",
            kCBIODeviceNameKey: "iOS Demo"
        ] as [String : NSObject]
        
        return true
    }
}
