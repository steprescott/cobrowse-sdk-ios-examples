//
//  Cobrowse.swift
//  Cobrowse
//

import SwiftUI
import CobrowseSDK

let cobrowseSession = CobrowseSession()
let account = Account()

@main
struct Cobrowse: App {
    
    @UIApplicationDelegateAdaptor var delegate: AppDelegate

    var body: some Scene {
        WindowGroup {
            RootView()
                .onAppear {
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
                    
                    cobrowse.start()
                }
                .environmentObject(cobrowseSession)
                .environmentObject(account)
        }
    }
}
