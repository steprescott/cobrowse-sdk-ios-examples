//
//  SceneDelegate.swift
//  Cobrowse
//

import UIKit
import SwiftUI
import Combine

class SceneDelegate: UIResponder, UIWindowSceneDelegate, ObservableObject {
    
    var controlWindow: UIWindow?
    weak var windowScene: UIWindowScene?
    
    func scene(_ scene: UIScene, willConnectTo session: UISceneSession, options connectionOptions: UIScene.ConnectionOptions) {
        windowScene = scene as? UIWindowScene
        setupControlWindow()
    }
    
    private func setupControlWindow() {
        guard let windowScene = windowScene
            else { return }

        let controlView = Session.Control.View()
            .environmentObject(session)
        
        let controlViewController = UIHostingController(rootView: controlView)
        controlViewController.view.backgroundColor = .clear
        
        let controlWindow = PassThroughWindow(windowScene: windowScene)
        controlWindow.rootViewController = controlViewController
        controlWindow.isHidden = false
        
        self.controlWindow = controlWindow
    }
}
