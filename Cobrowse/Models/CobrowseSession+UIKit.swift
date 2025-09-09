//
//  Session+UIKit.swift
//  Cobrowse
//

import UIKit
import CobrowseSDK

extension CobrowseSession {

    func cobrowseRedactedViews(for vc: UIViewController) -> [UIView] {
        
        guard privateByDefault,
              let keyWindow = UIWindow.keyWindow
            else { return [] }
        
        return keyWindow.rootViews
    }
}

// MARK: - Latency

extension CobrowseSession.Latency {
    
    var color: UIColor {
        switch self {
            case .low: return .systemGreen
            case .medium: return .systemYellow
            case .high: return .systemRed
            case .unknown: return .darkGray
        }
    }
}

// MARK: - Custom consent prompts

extension CobrowseSession {
    
    func cobrowseHandleSessionRequest(_ session: CBIOSession) {
        
        typealias ConsentPrompt = ConsentPromptViewController
        
        guard let consentPrompt: ConsentPrompt = UIStoryboard.main.viewControllerWith(id: .consentPrompt)
            else { return }
        
        consentPrompt.onDeny = { session in session?.end() }
        consentPrompt.onAllow = { session in session?.activate() }
        
        consentPrompt.onUpdate = { session in
            guard session == nil
                else { return }
            
            consentPrompt.dismiss(animated: true)
        }
        
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
        
        consentPrompt.onDeny = { session in session?.setRemoteControl(.rejected) }
        consentPrompt.onAllow = { session in session?.setRemoteControl(.on) }
        
        consentPrompt.onUpdate = { session in
            guard let session, session.remoteControl() != .requested
                    else { return }
            
            consentPrompt.dismiss(animated: true)
        }
        
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
