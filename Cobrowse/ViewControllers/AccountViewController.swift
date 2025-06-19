//
//  AccountViewController.swift
//  Cobrowse
//

import UIKit
import Combine

import CobrowseSDK

class AccountViewController: UIViewController {

    @IBOutlet weak var sessionButton: UIBarButtonItem!
    
    @IBOutlet weak var profileImageView: UIImageView!
    
    @IBOutlet var redactedLabels: [UILabel]!
    
    @IBOutlet weak var codeStackView: UIStackView!
    @IBOutlet weak var codeLabel: UILabel!
    
    private var bag = Set<AnyCancellable>()
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        let tap = UITapGestureRecognizer(target: self, action: #selector(profileImageWasTapped))
        profileImageView.addGestureRecognizer(tap)
        
        subscribeToSession()
        subscribeToProfileImage()
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        
        profileImageView.layer.cornerRadius = profileImageView.bounds.width * 0.5
    }
    
    @objc func profileImageWasTapped() {
        performSegue(to: .showCamera)
    }
    
    @IBAction func sessionButtonWasTapped(_ sender: Any) {
        cobrowseSession.current?.end()
    }
    
    @IBAction func closeButtonWasTapped(_ sender: Any) {
        dismiss(animated: true)
    }
    
    @IBAction func codeButtonWasTapped(_ sender: Any) {
        CobrowseIO.instance().createSession { [weak self] error, session in
            guard
                let self = self,
                let session = session,
                let code = session.code()
            else { return }
            
            
            codeLabel.text = "\(code.prefix(3)) - \(code.suffix(3))"
        }
    }
    
    @IBAction func logoutButtonWasTapped(_ sender: Any) {
        dismiss(animated: true) {
            account.isSignedIn = false
        }
    }
}

// MARK: - CobrowseIORedacted

extension AccountViewController: CobrowseIORedacted {
    
    func redactedViews() -> [UIView] {
        redactedLabels
    }
}

// MARK: - Subscriptions

extension AccountViewController {
    
    private func subscribeToSession() {
        cobrowseSession.$current.sink { [weak self] session in
            guard let self = self else { return }
            
            codeStackView.isHidden = session?.isActive() ?? false
            sessionButton.isHidden = !codeStackView.isHidden
            
            if session == nil {
                codeLabel.text = nil
            }
        }
        .store(in: &bag)
    }
    
    private func subscribeToProfileImage() {
        account.$profileImage.sink { [weak self] image in
            guard let self = self, let image
                else { return }
            
            profileImageView.image = image
        }
        .store(in: &bag)
    }
}
