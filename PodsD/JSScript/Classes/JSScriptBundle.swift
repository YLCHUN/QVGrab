//
//  JSScriptBundle.swift
//  JSScript
//
//  Created by Cityu on 2025/6/6.
//

import Foundation

class JSScriptBundle: NSObject {
    
    private static var _frameworkBundle: Bundle?
    private static var _resourceBundle: Bundle?
    
    @objc class var frameworkBundle: Bundle {
        if _frameworkBundle == nil {
            _frameworkBundle = Bundle(for: self)
        }
        return _frameworkBundle!
    }
    
    @objc class var resourceBundle: Bundle {
        if _resourceBundle == nil {
            let resourceBundlePath = frameworkBundle.path(forResource: "JSScript", ofType: "bundle")
            _resourceBundle = Bundle(path: resourceBundlePath ?? "")
        }
        return _resourceBundle!
    }
}
