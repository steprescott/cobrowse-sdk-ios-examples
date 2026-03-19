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
        
        #if APPCLIP
        demo.license = "rE6HC6EDX6g2_w"
        demo.id = Int.random(in: 1000..<9999).description
        demo.deviceName = "AppClip iOS Device (\(demo.id))"
        #endif
        
        let cobrowse = CobrowseIO.instance()
        
        cobrowse.license = demo.license
        cobrowse.api = demo.api
        cobrowse.customData = [ CBIODeviceNameKey: demo.deviceName ]
        
        guard !demo.id.isEmpty
            else { return true }
        
        cobrowse.customData = [ "demo_id": demo.id ]
        cobrowse.capabilities = ["arrows", "disappearing_ink", "drawing", "keypress", "laser", "pointer", "rectangles"]
        
        account.isSignedIn = true
        
        return true
    }
}
