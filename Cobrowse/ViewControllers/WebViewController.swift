//
//  WebViewController.swift
//  Cobrowse
//

import UIKit
import Combine
import WebKit

import CobrowseSDK

class WebViewController: UIViewController {
    
    @IBOutlet weak var sessionButton: UIBarButtonItem!
    @IBOutlet weak var webView: WKWebView!

    var url: URL?
    private var bag = Set<AnyCancellable>()
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        SheetPresentationDelegate.subscribe(for: sessionButton, store: &bag)
        
        webView.navigationDelegate = self
        
        guard let url = url
            else { return }
        
        webView.load(URLRequest(url: url))
    }

    @IBAction func sessionButtonWasTapped(_ sender: Any) {
        session.current?.end()
    }
}

// MARK: - WKNavigationDelegate

extension WebViewController: WKNavigationDelegate {
    
    func webView(_ webView: WKWebView, decidePolicyFor navigationAction: WKNavigationAction) async -> WKNavigationActionPolicy {
        
        guard let url = navigationAction.request.url,
              let scheme = url.scheme
        else { return .allow }

        switch scheme {
            case "tel", "sms", "facetime", "mailto":
                await UIApplication.shared.open(url)
                return .cancel
            default: break
        }

        if navigationAction.navigationType != .other {
            navigateTo(url)
            return .cancel
        }

        return .allow
    }
    
    private func navigateTo(_ url: URL) {
        let storyboard = UIStoryboard.main
        
        guard
            let navigationController = navigationController,
            let webViewController: WebViewController = storyboard.viewControllerWith(id: .webViewController)
        else { return }

        webViewController.url = url

        navigationController.show(webViewController, sender: self)
    }
}

extension WebViewController: CobrowseIOUnredacted {
    func unredactedViews() -> [Any] {
        
        guard session.isRedactionByDefaultEnabled
            else { return [] }
        
        return [
            view!
        ]
    }
}
