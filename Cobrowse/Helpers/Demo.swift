//
//  Demo.swift
//

import Foundation

import CobrowseSDK

struct Demo {
    
    @UserDefault(key: "demo_id", defaultValue: nil)
    var id: String?
    
    @UserDefault(key: "license", defaultValue: "trial")
    var license: String
    
    @UserDefault(key: "api", defaultValue: "https://cobrowse.io")
    var api: String
    
    @UserDefault(key: "device_name", defaultValue: "Trial iOS Device")
    var deviceName: String
    
    private static let demo = Demo()
    private init() { }
    
    @discardableResult
    static func setup() -> Bool {
        
        guard let demoID = demo.id
            else { return false }
        
        let cobrowse = CobrowseIO.instance()
        
        cobrowse.license = demo.license
        cobrowse.api = demo.api
        cobrowse.capabilities = ["drawing", "keypress", "laser", "pointer"]
        
        cobrowse.customData = [
            CBIODeviceNameKey: demo.deviceName,
            "demo_id": demoID
        ]
        
        account.isSignedIn = true
        
        return true
    }
}
