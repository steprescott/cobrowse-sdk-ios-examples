//
//  DeepLiker.swift
//  Cobrowse
//

import CobrowseIO

enum DeepLinker {
    
    static func handle(_ url: URL) -> Bool {
        
        guard let components = URLComponents(url: url, resolvingAgainstBaseURL: true)
            else { return false }
        
        #if APPCLIP
        
        return setupForAppClip(using: components)
        
        #else
        
        guard components.path.isEmpty, let id = components.fragment
            else { return handleAction(with: components) }
        
        return startSession(with: id)
        
        #endif
    }
    
    private static func handleAction(with components: URLComponents) -> Bool {
        
        let action = components.path.split(separator: "/").first
        
        switch action {
            case "api": return updateAPI(using: components)
            case "license": return updateLicense(using: components)
            case "data": return updateCustomData(using: components)
            case "s": return startSession(using: components)
            case "code": return startSession(using: components)
            case "demo": return setupForDemo(using: components)
            default: return false
        }
    }
}

extension DeepLinker {
    
    @discardableResult
    private static func updateAPI(using components: URLComponents) -> Bool {
        
        let api = components.path.trimmingPrefix("/api/")
        
        let cobrowse = CobrowseIO.instance()
        
        cobrowse.stop()
        cobrowse.api = String(api)
        cobrowse.start()
        
        return true
    }
    
    @discardableResult
    private static func updateLicense(using components: URLComponents) -> Bool {
        
        guard let license = components.path.split(separator: "/").last
            else { return false }
        
        let cobrowse = CobrowseIO.instance()
        
        cobrowse.stop()
        cobrowse.license = String(license)
        cobrowse.start()
        
        return true
    }
    
    @discardableResult
    private static func updateCustomData(using components: URLComponents) -> Bool {
        
        guard let data = components.queryItems?.reduce(into: [String : NSObject](), { partialResult, item in
            guard let value = item.value
                else { return }
            
            partialResult[item.name] = value as NSObject
        })
        else { return false }
        
        CobrowseIO.instance().customData = data
        
        return true
    }
    
    @discardableResult
    private static func startSession(using components: URLComponents) -> Bool {
        
        if let id = components.queryItems?.first(where: { $0.name == "id" })?.value {
            return startSession(with: id)
        } else if let code = components.path.split(separator: "/").last {
            return startSession(with: String(code))
        }
            
        return false
    }
    
    @discardableResult
    private static func startSession(with id: String) -> Bool {
        
        let cobrowse = CobrowseIO.instance()
        
        cobrowse.stop()
        cobrowse.start()
        cobrowse.getSession(id)
        
        return true
    }
    
    @discardableResult
    private static func setupForDemo(using components: URLComponents) -> Bool {
        
        let cobrowse = CobrowseIO.instance()
        
        let demoID = components.path.trimmingPrefix("/demo/")
        cobrowse.customData = ["demo_id" : String(demoID)] as [String : NSObject]
        
        if var queryItems = components.queryItems {
            
            cobrowse.stop()
            
            if let api = queryItems.pop("api") {
                cobrowse.api = api
            }
            
            if let license = queryItems.pop("license") {
                cobrowse.license = license
            }

            var components = components
            components.queryItems = queryItems
            
            updateCustomData(using: components)
            
            cobrowse.start()
        }

        if !account.isSignedIn {
            account.isSignedIn = true
        }
        
        return true
    }
    
    
    #if APPCLIP
    @discardableResult
    private static func setupForAppClip(using components: URLComponents) -> Bool {
        let cobrowse = CobrowseIO.instance()
        
        cobrowse.stop()
        cobrowse.license = "rE6HC6EDX6g2_w"
        cobrowse.start()
        
        account.isSignedIn = true
        
        return true
    }
    #endif
}
