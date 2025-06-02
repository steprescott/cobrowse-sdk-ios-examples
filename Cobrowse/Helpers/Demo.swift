//
//  Demo.swift
//

import Foundation

import SwiftUI
import CobrowseSDK

struct Demo {
    
    @AppStorage("demo_id")
    var id: String = ""
    
    @AppStorage("license")
    var license = "trial"
    
    @AppStorage("api")
    var api = "https://cobrowse.io"
    
    @AppStorage("device_name")
    var deviceName = "Trial iOS Device"
    
    private static let demo = Demo()
    private init() { }
    
    @discardableResult
    static func setup() -> Bool {
        
        guard !demo.id.isEmpty
            else { return false }
        
        let cobrowse = CobrowseIO.instance()
        
        cobrowse.license = demo.license
        cobrowse.api = demo.api
        cobrowse.capabilities = ["drawing", "keypress", "laser", "pointer"]
        
        cobrowse.customData = [
            CBIODeviceNameKey: demo.deviceName,
            "demo_id": demo.id
        ]
        
        account.isSignedIn = true
        
        return true
    }
}
