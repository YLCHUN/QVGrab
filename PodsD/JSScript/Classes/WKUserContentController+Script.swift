//
//  WKUserContentController+Script.swift
//  JSScript
//
//  Created by Cityu on 2025/7/17.
//

import WebKit
import ObjectiveC

class Wrapper<T> {
    let raw: T
    init(raw: T) {
        self.raw = raw
    }
}

typealias JSScriptMessageAction = (WKScriptMessage) -> Void

typealias JSScriptMessageActionWrapper = Wrapper<JSScriptMessageAction>


extension WKUserContentController {
    
    // MARK: - Script Message Management
    
    private struct AssociatedKeys {
        static var scriptMessageContent = "scriptMessageContent"
        static var userScriptContent = "userScriptContent"
    }
    
    private var scriptMessageContent: WKScriptMessageContent {
        get {
            return AssociatedKeys.scriptMessageContent.withCString { cStringPtr in
                let rawPtr = UnsafeRawPointer(cStringPtr)
                if let content = objc_getAssociatedObject(self, rawPtr) as? WKScriptMessageContent {
                    return content
                }
                let content = WKScriptMessageContent()
                content.cc = self
                objc_setAssociatedObject(self,rawPtr, content, .OBJC_ASSOCIATION_RETAIN_NONATOMIC)
                return content
            }
        }
    }
    
    private var userScriptContent: WKUserScriptContent {
        get {
            return AssociatedKeys.userScriptContent.withCString { cStringPtr in
                let rawPtr = UnsafeRawPointer(cStringPtr);
                if let content = objc_getAssociatedObject(self, rawPtr) as? WKUserScriptContent {
                    return content
                }
                let content = WKUserScriptContent()
                content.cc = self
                objc_setAssociatedObject(self, rawPtr, content, .OBJC_ASSOCIATION_RETAIN_NONATOMIC)
                return content
            }
            
        }
    }
    
    @objc func setScriptMessage(_ name: String, webView: WKWebView?, handler: JSScriptMessageAction?) {
        scriptMessageContent.setMessageName(name, webView: webView, handler: handler)
    }
    
    @objc func setScriptMessage(_ name: String, handler: JSScriptMessageAction?) {
        scriptMessageContent.setMessageName(name, handler: handler)
    }
    
    @objc func setUserScript(_ userScript: WKUserScript?, forKey key: String) {
        userScriptContent.setUserScript(userScript, forKey: key)
    }
}

// MARK: - WKScriptMessageContent

private class WKScriptMessageContent: NSObject, WKScriptMessageHandler {
    weak var cc: WKUserContentController?
    private var map: NSMapTable<NSString, NSMapTable<AnyObject, JSScriptMessageActionWrapper>>
    private var commonCtx: AnyObject
    
    override init() {
        self.commonCtx = NSObject()
        self.map = NSMapTable<NSString, NSMapTable<AnyObject, JSScriptMessageActionWrapper>>.strongToStrongObjects()
        super.init()
    }
    
    @discardableResult
    private func getMap(for name: String, init: Bool) -> NSMapTable<AnyObject, JSScriptMessageActionWrapper>? {
        guard let nameKey = name as NSString? else { return nil }
        
        var map = self.map.object(forKey: nameKey)
        
        if `init` {
            if map == nil {
                map = NSMapTable<AnyObject, JSScriptMessageActionWrapper>.weakToStrongObjects()
                self.map.setObject(map, forKey: nameKey)
            }
        } else {
            if let map = map, map.count == 0 {
                self.map.removeObject(forKey: nameKey)
                return nil
            }
        }
        
        return map
    }
    
    func setMessageName(_ name: String, ctx: AnyObject?, handler: JSScriptMessageAction?) {
        if let handler = handler {
            let map = getMap(for: name, init: true)
            if map?.count == 0 {
                cc?.add(self, name: name)
            }
            map?.setObject(Wrapper(raw: handler), forKey: ctx ?? commonCtx)
        } else {
            let map = getMap(for: name, init: false)
            if let map = map {
                map.removeObject(forKey: ctx ?? commonCtx)
                getMap(for: name, init: false)
            }
            if getMap(for: name, init: false) == nil {
                cc?.removeScriptMessageHandler(forName: name)
            }
        }
    }
    
    func setMessageName(_ name: String, webView: WKWebView?, handler: JSScriptMessageAction?) {
        setMessageName(name, ctx: webView ?? commonCtx, handler: handler)
    }
    
    func setMessageName(_ name: String, handler: JSScriptMessageAction?) {
        setMessageName(name, ctx: commonCtx, handler: handler)
    }
    
    func userContentController(_ userContentController: WKUserContentController, didReceive message: WKScriptMessage) {
        let map = getMap(for: message.name, init: false)
        
        if let webView = message.webView {
            let handler = map?.object(forKey: webView)
            handler?.raw(message)
        }
        
        let commonHandler = map?.object(forKey: commonCtx)
        commonHandler?.raw(message)
    }
}

// MARK: - WKUserScriptContent

private class WKUserScriptContent: NSObject {
    weak var cc: WKUserContentController?
    private var dict: [String: WKUserScript] = [:]
    
    func setUserScript(_ userScript: WKUserScript?, forKey key: String) {
        if let existingScript = dict[key],
           existingScript.source == userScript?.source {
            return
        }
        
        cc?.removeAllUserScripts()
        dict[key] = userScript
        
        for userScript in dict.values {
            cc?.addUserScript(userScript)
        }
    }
}
