//
//  SignInViewController.swift
//  Cobrowse
//

import UIKit
import Combine
import CobrowseIO

class SignInViewController: UIViewController {
    
    @IBOutlet weak var sessionButton: UIBarButtonItem!
    
    @IBOutlet weak var imageView: UIImageView!
    @IBOutlet weak var signInButton: UIButton!
    
    @IBOutlet weak var usernameTextField: UITextField!
    @IBOutlet weak var passwordTextField: UITextField!
    
    @Published var username = ""
    @Published var password = ""
    
    var isSignInButtonEnabled: AnyPublisher<Bool, Never> {
        Publishers.CombineLatest(
            .isNotEmpty($username),
            .isNotEmpty($password)
        )
        .map { $0 && $1 }
        .eraseToAnyPublisher()
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        imageView.image = Locale.current.currency?.icon
        
        subscribeToFormUpdates()
        subscribeToSession()
    }
    
    @IBAction func sessionButtonWasTapped(_ sender: Any) {
        session.current?.end()
    }
    
    @IBAction func signInButtonWasTapped(_ sender: Any) {
        account.isSignedIn = true
    }
}

// MARK: - CobrowseIORedacted

extension SignInViewController: CobrowseIORedacted {
    
    func redactedViews() -> [Any] {
        [
            usernameTextField,
            passwordTextField
        ].compactMap { $0 }
    }
}

// MARK: - Subscriptions

extension SignInViewController {
    
    private func subscribeToFormUpdates() {
        usernameTextField.textPublisher
            .sink { [self] in username = $0 }
            .store(in: &bag)
        
        passwordTextField.textPublisher
            .sink { [self] in password = $0 }
            .store(in: &bag)
        
        isSignInButtonEnabled
            .assign(to: \.isEnabled, on: signInButton)
            .store(in: &bag)
    }
    
    private func subscribeToSession() {
        session.$current.sink { [self] session in
            guard let session = session
                else { sessionButton.isHidden = true; return }
            
            sessionButton.isHidden = !session.isActive()
        }
        .store(in: &bag)
    }
}
