//
//  AppDelegate.swift
//  PBD
//
//  Created by Ste on 29/08/2026.
//

import UIKit
import CobrowseSDK

@main
/// Starts Cobrowse and chooses the policy.
///
/// All three are held here so swapping one in is a single line.
class AppDelegate: UIResponder, UIApplicationDelegate {

    /// Held for the session's lifetime, because `CobrowseIO` does not retain it.
    private let redactionDelegate = RedactByDefaultDelegate()
    
    func application(_ application: UIApplication, didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?) -> Bool {

        let cobrowse = CobrowseIO.instance()
        cobrowse.license = "ste"
        
        cobrowse.delegate = redactionDelegate
        cobrowse.unredactedViews = [
            "UIEditingOverlayGestureView",
            "FloatingBarContainerView",
            "_UIFloatingBarContainerView",
            "_UIRoundedRectShadowView",
            "_UIPopoverDimmingView",
            "_UIPopoverShapeLayerChromeView",
            "_UIParallaxOverlayView",
            "_UITabContainerView"
        ]

        cobrowse.start()

        return true
    }

    // MARK: UISceneSession Lifecycle

    func application(_ application: UIApplication, configurationForConnecting connectingSceneSession: UISceneSession, options: UIScene.ConnectionOptions) -> UISceneConfiguration {
        UISceneConfiguration(name: "Default Configuration", sessionRole: connectingSceneSession.role)
    }
}
