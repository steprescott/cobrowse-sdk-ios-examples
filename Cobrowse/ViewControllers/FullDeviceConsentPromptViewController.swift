//
//  FullDeviceConsentPromptViewController.swift
//  Cobrowse
//

import UIKit
import Combine
import ReplayKit

import CobrowseSDK

class FullDeviceConsentPromptViewController: UIViewController {
    
    @IBOutlet private weak var pickerView: RPSystemBroadcastPickerView!
    
    private var bag = Set<AnyCancellable>()
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        pickerView.showsMicrophoneButton = false
        pickerView.preferredExtension = "io.cobrowse.demo.broadcast-extension"
        
        subscribeToSession()
    }

    @IBAction func denyButtonWasTapped(_ sender: Any) {
        cobrowseSession.current?.setFullDevice(.rejected)
        dismiss(animated: true)
    }
}

// MARK: - Subscriptions

extension FullDeviceConsentPromptViewController {
    
    private func subscribeToSession() {
        
        cobrowseSession.$current.sink { [weak self] session in
            
            guard
                let self = self,
                let session = session, session.fullDevice() != .requested
            else { return }
            
            dismiss(animated: true)
        }
        .store(in: &bag)
    }
}
