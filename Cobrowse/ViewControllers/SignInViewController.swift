//
//  SignInViewController.swift
//  Cobrowse
//

import UIKit
import Combine

import CobrowseSDK
import Lottie

class SignInViewController: UIViewController {
    
    @IBOutlet weak var sessionButton: UIBarButtonItem!
    
    @IBOutlet weak var scrollView: UIScrollView!
    @IBOutlet weak var imageView: UIImageView!
    @IBOutlet weak var signInButton: UIButton!
    
    @IBOutlet weak var usernameTextField: UITextField!
    @IBOutlet weak var passwordTextField: UITextField!
    
    @IBOutlet weak var lottieView: LottieAnimationView!
    
    @Published var username = ""
    @Published var password = ""
    
    private var bag = Set<AnyCancellable>()
    
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
        
        let tripleTap = UITapGestureRecognizer(target: self, action: #selector(imageViewWasTapped))
        tripleTap.numberOfTapsRequired = 3
        
        imageView.addGestureRecognizer(tripleTap)
        imageView.image = Locale.current.currency?.icon
        
        lottieView.animation = LottieAnimation.named("money")
        lottieView.animationSpeed = 0.7
        
        subscribeToFormUpdates()
        subscribeToSession()
    }
    
    @IBAction func sessionButtonWasTapped(_ sender: Any) {
        cobrowseSession.current?.end()
    }
    
    @IBAction func signInButtonWasTapped(_ sender: Any) {
        account.isSignedIn = true
    }
    
    @objc
    func imageViewWasTapped() {
        lottieView.play()
   }
}

// MARK: - CobrowseIORedacted

extension SignInViewController: CobrowseIORedacted {
    
    func redactedViews() -> [UIView] {
        [
            usernameTextField,
            passwordTextField
        ].compactMap { $0 }
    }
}

// MARK: - UITextFieldDelegate

extension SignInViewController: UITextFieldDelegate {
    
    func textFieldShouldReturn(_ textField: UITextField) -> Bool {
        
        guard let text = textField.text, !text.isEmpty
            else { return false }
        
        switch textField {
            case usernameTextField:
                passwordTextField.becomeFirstResponder()
            
            case passwordTextField:
                guard signInButton.isEnabled
                    else { return false }
            
                account.isSignedIn = true
            
            default: return false
        }
        
        return true
    }
    
    func textFieldDidBeginEditing(_ textField: UITextField) {
        scrollView.scrollRectToVisible(.infinite, animated: true)
    }
}

// MARK: - Subscriptions

extension SignInViewController {
    
    private func subscribeToFormUpdates() {
        usernameTextField.textPublisher
            .sink { [weak self] in self?.username = $0 }
            .store(in: &bag)
        
        passwordTextField.textPublisher
            .sink { [weak self] in self?.password = $0 }
            .store(in: &bag)
        
        isSignInButtonEnabled
            .assign(to: \.isEnabled, on: signInButton)
            .store(in: &bag)
    }
    
    private func subscribeToSession() {
        cobrowseSession.$current.sink { [weak self] session in
            guard let self = self else { return }
            
            sessionButton.isHidden = session?.isActive() != true
        }
        .store(in: &bag)
    }
}
