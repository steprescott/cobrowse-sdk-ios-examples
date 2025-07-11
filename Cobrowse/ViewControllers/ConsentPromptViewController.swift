//
//  ConsentPromptViewController.swift
//  Cobrowse
//

import UIKit
import Combine

import CobrowseSDK

class ConsentPromptViewController: UIViewController {
    
    @IBOutlet private weak var headingLabel: UILabel!
    @IBOutlet private weak var bodyLable: UILabel!
    @IBOutlet private weak var denyButton: UIButton!
    @IBOutlet private weak var allowButton: UIButton!
    
    private var bag = Set<AnyCancellable>()
    
    var heading: String?
    var body: NSAttributedString?
    
    var onUpdate: ((_ session: CBIOSession?) -> ())?
    var onDeny: ((_ session: CBIOSession?) -> ())?
    var onAllow: ((_ session: CBIOSession?) -> ())?
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        if let heading = heading {
            headingLabel.text = heading
        }
        
        if let body = body {
            bodyLable.attributedText = body
        }
        
        denyButton.isHidden = onDeny == nil
        allowButton.isHidden = onAllow == nil
        
        subscribeToSession()
    }
    
    @IBAction func didTapDenyButton(_ sender: Any) {
        onDeny?(cobrowseSession.current)
        dismiss(animated: true)
    }
    
    @IBAction func didTapAllowButton(_ sender: Any) {
        onAllow?(cobrowseSession.current)
        dismiss(animated: true)
    }
}

// MARK: - Subscriptions

extension ConsentPromptViewController {
    
    private func subscribeToSession() {
        
        cobrowseSession.$current.sink { [weak self] session in
            guard let self
                else { return }
            
            self.onUpdate?(session)
        }
        .store(in: &bag)
    }
}
