//
//  SettingsViewController.swift
//  Cobrowse
//

import UIKit
import Combine
import SafariServices

import CobrowseSDK

class SettingsViewController: UIViewController {
    
    @IBOutlet weak var sessionButton: UIBarButtonItem!
    
    @IBOutlet weak var privateByDefaultSwitch: UISwitch!
    
    private var bag = Set<AnyCancellable>()
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        subscribeToSession()
        
        privateByDefaultSwitch.isOn = cobrowseSession.privateByDefault
    }
    
    @IBAction func sessionButtonWasTapped(_ sender: Any) {
        cobrowseSession.current?.end()
    }
    
    @IBAction func closeButtonWasTapped(_ sender: Any) {
        dismiss(animated: true)
    }
    
    @IBAction func privateByDefaultSwitchDidChange(_ sender: Any) {
        cobrowseSession.privateByDefault = privateByDefaultSwitch.isOn
    }
    
    @IBAction func privacyPolicyButtonWasTapped(_ sender: Any) {
        let url = URL(string: "https://cobrowse.io/privacy")!
        let vc = SFSafariViewController(url: url)
        vc.preferredControlTintColor = UIColor.cbPrimary
        vc.modalPresentationStyle = .formSheet
        present(vc, animated: true)
    }
}

// MARK: - Subscriptions

extension SettingsViewController {
    
    private func subscribeToSession() {
        cobrowseSession.$current.sink { [weak self] session in
            guard let self = self else { return }
            
            sessionButton.isHidden = !(session?.isActive() ?? false)
        }
        .store(in: &bag)
    }
}

// MARK: - SessionMetrics Segue (Popover)

extension SettingsViewController: UIPopoverPresentationControllerDelegate {
    
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        
        guard let presentationController = segue.destination.popoverPresentationController,
              let identifier = segue.identifier,
              identifier == .sessionMetrics
        else { return }
        
        presentationController.delegate = self
        segue.destination.preferredContentSize = CGSize(width: .zero, height: 100)
    }
    
    func adaptivePresentationStyle(for controller: UIPresentationController,
                                   traitCollection: UITraitCollection) -> UIModalPresentationStyle {
        return .none
    }
}


