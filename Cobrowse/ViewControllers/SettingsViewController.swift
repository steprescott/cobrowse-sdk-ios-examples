//
//  SettingsViewController.swift
//  Cobrowse
//

import UIKit
import Combine

import CobrowseSDK

class SettingsViewController: UIViewController {
    
    @IBOutlet weak var sessionButton: UIBarButtonItem!
    
    @IBOutlet weak var redactionByDefaultSwitch: UISwitch!
    
    private var bag = Set<AnyCancellable>()
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        subscribeToSession()
        
        redactionByDefaultSwitch.isOn = session.isRedactionByDefaultEnabled
    }
    
    @IBAction func sessionButtonWasTapped(_ sender: Any) {
        session.current?.end()
    }
    
    @IBAction func closeButtonWasTapped(_ sender: Any) {
        dismiss(animated: true)
    }
    
    @IBAction func redactionByDefaultSwitchDidChange(_ sender: Any) {
        session.isRedactionByDefaultEnabled = redactionByDefaultSwitch.isOn
    }
}

// MARK: - Subscriptions

extension SettingsViewController {
    
    private func subscribeToSession() {
        session.$current.sink { [weak self] session in
            guard let self = self else { return }
            
            sessionButton.isHidden = !(session?.isActive() ?? false)
        }
        .store(in: &bag)
    }
}
