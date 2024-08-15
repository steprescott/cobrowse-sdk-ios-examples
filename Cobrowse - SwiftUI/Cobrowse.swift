//
//  Cobrowse.swift
//  Cobrowse
//

import SwiftUI
import CobrowseIO

let session = Session()
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
                    
                    cobrowse.start()
                }
                .environmentObject(session)
                .environmentObject(account)
        }
    }
}
