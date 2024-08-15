//
//  Session+UIKit.swift
//  Cobrowse
//

import UIKit
import CobrowseIO

extension Session {

    func cobrowseRedactedViews(for vc: UIViewController) -> [UIView] {
        
        guard isRedactionByDefaultEnabled,
              let keyWindow = UIWindow.keyWindow
            else { return [] }
        
        return keyWindow.rootViews
    }
}

// MARK: - Custom consent prompts

extension Session {
    
    func cobrowseHandleSessionRequest(_ session: CBIOSession) {
        
        typealias ConsentPrompt = ConsentPromptViewController
        
        guard let consentPrompt: ConsentPrompt = UIStoryboard.main.viewControllerWith(id: .consentPrompt)
            else { return }
        
        consentPrompt.onDeny = { session in session?.end() }
        consentPrompt.onAllow = { session in session?.activate() }
        
        consentPrompt.configureSheet()
        
        UIWindow.present(consentPrompt)
    }
    
    func cobrowseHandleRemoteControlRequest(_ session: CBIOSession) {
        
        typealias ConsentPrompt = ConsentPromptViewController
        
        guard let consentPrompt: ConsentPrompt = UIStoryboard.main.viewControllerWith(id: .consentPrompt)
            else { return }
        
        consentPrompt.heading = "Remote Control"
        consentPrompt.body = .init(string:
            """
            By activating the remote control feature, you authorize your agent to perform actions on your behalf on your device. This includes navigating apps, changing settings, and entering information as directed by you. Please ensure you only request actions you're comfortable with.
            
            Your acceptance confirms your consent to these terms and the permissions granted for remote actions.
            """)
        
        consentPrompt.onDeny = { session in session?.setRemoteControl(kCBIORemoteControlStateRejected) }
        consentPrompt.onAllow = { session in session?.setRemoteControl(kCBIORemoteControlStateOn) }
        
        consentPrompt.configureSheet()
        
        UIWindow.present(consentPrompt)
    }
    
    func cobrowseHandleFullDeviceRequest(_ session: CBIOSession) {
        
        typealias ConsentPrompt = FullDeviceConsentPromptViewController
        
        guard let consentPrompt: ConsentPrompt = UIStoryboard.main.viewControllerWith(id: .fullDevicePrompt)
            else { return }
        
        consentPrompt.configureSheet()
        
        UIWindow.present(consentPrompt)
    }
}
