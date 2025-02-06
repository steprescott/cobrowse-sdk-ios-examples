//
//  AgentPresentViewController.swift
//  Cobrowse
//

import UIKit
import Combine

import CobrowseSDK

class AgentPresentViewController: UIViewController {
    
    @IBOutlet weak var label: UILabel!
    @IBOutlet weak var imageView: UIImageView!
    
    @IBOutlet weak var codeStackView: UIStackView!
    @IBOutlet var codeTextFields: [CodeTextField]!
    
    @IBOutlet weak var sessionButton: UIBarButtonItem!
    
    private var bag = Set<AnyCancellable>()
    
    override func viewDidLoad() {
        
        super.viewDidLoad()
        
        imageView.isHidden = true
        sessionButton.isHidden = true
        
        setupCodeInput()
    }
    
    override func viewDidAppear(_ animated: Bool) {
        
        super.viewDidAppear(animated)

        subscribeToSession()
    }
    
    @IBAction func sessionButtonWasTapped(_ sender: Any) {
        session.current?.end()
    }
    
    @IBAction func closeButtonWasTapped(_ sender: Any) {
        dismiss(animated: true)
    }
}

// MARK: - CodeTextField

extension AgentPresentViewController {
    
    private func setupCodeInput() {
        
        codeTextFields.forEach { textField in
            
            textField.onDigitInput = { [weak self] textField in
                
                guard let self = self
                    else { return }
                
                advanceIfNecessary(from: textField)
                
                if codeTextFields.hasCompleteCode {
                    submitCode()
                }
            }

            textField.onBackspace = { [weak self] textField in
                self?.handleBackspace(for: textField)
            }
        }
    }

    private func advanceIfNecessary(from textField: CodeTextField) {
        
        guard
            let index = codeTextFields.firstIndex(of: textField),
            index < codeTextFields.count - 1
        else { return }
        
        codeTextFields[index + 1].becomeFirstResponder()
    }

    private func handleBackspace(for textField: CodeTextField) {
        
        guard let index = codeTextFields.firstIndex(of: textField)
            else { return }

        if textField.text?.isEmpty == true, index > 0 {
            let previousField = codeTextFields[index - 1]
            previousField.text = ""
            previousField.becomeFirstResponder()
        } else {
            textField.text = nil
        }
    }

    private func submitCode() {
        
        codeTextFields.disable()

        CobrowseIO.instance().getSession(codeTextFields.code) { [weak self] error, session in
            
            session?.setCapabilities([])
            
            guard
                let self = self,
                let _ = error
            else { return }
            
            codeStackView.shake()
            
            async(after: 1.2) { [weak self] in
                guard let self = self else { return }
                
                codeTextFields.reset()
                codeTextFields.first?.becomeFirstResponder()
            }
        }
    }
}

// MARK: - Subscriptions

extension AgentPresentViewController {
    
    private func subscribeToSession() {
        
        session.$current.sink { [weak self] session in
            
            guard let self = self else { return }

            let isActive = session?.isActive() ?? false
            sessionButton.isHidden = !isActive
            codeStackView.isHidden = isActive

            if session == nil || isActive {
                codeTextFields.reset()
            }
                
            if session == nil || !isActive {
                codeTextFields.first?.becomeFirstResponder()
            }

            label.text = isActive ? "You are now presenting" : "Please enter your present code"
            imageView.isHidden = !isActive
        }
        .store(in: &bag)
    }
}
