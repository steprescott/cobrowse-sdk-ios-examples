//
//  WebView.swift
//  Cobrowse - SwiftUI
//

import SwiftUI
import WebKit

struct WebView: UIViewRepresentable {
    
    let url: URL
    var onNavigation: ((URL) -> Void) = { _ in }
    
    private let webView = WKWebView()
    
    func makeUIView(context: Context) -> WKWebView {
        
        webView.load(URLRequest(url: url))
        
        return webView
    }
    
    func updateUIView(_ uiView: WKWebView, context: Context) {
        let delegate = context.coordinator
        delegate.onNavigation = onNavigation
        
        webView.navigationDelegate = delegate
    }
    
    func makeCoordinator() -> Delegate {
         Delegate()
    }
}

extension WebView {
    
    class Delegate: NSObject, WKNavigationDelegate {
        
        var onNavigation: ((URL) -> Void) = { _ in }
        
        func webView(_ webView: WKWebView, decidePolicyFor navigationAction: WKNavigationAction) async -> WKNavigationActionPolicy {
            
            guard let url = navigationAction.request.url,
                  let scheme = url.scheme
            else { return .allow }

            switch scheme {
                case "tel", "sms", "facetime", "mailto":
                    DispatchQueue.main.async {
                        UIApplication.shared.open(url)
                    }
                
                    return .cancel
                
                default: break
            }

            if navigationAction.navigationType != .other {
                DispatchQueue.main.async {
                    self.onNavigation(url)
                }
                
                return .cancel
            }

            return .allow
        }
    }
}

extension WebView {
    
    func onNavigation(perform action: @escaping (URL) -> Void) -> WebView {
        var webView = self
        webView.onNavigation = action
        return webView
    }
}
