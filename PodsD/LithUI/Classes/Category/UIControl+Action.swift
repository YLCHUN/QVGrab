//
//  UIControl+Action.swift
//  LithUI
//
//  Created by Cityu on 2025/7/21.
//

import UIKit
import ObjectiveC

public class ControlAction: NSObject {
    private(set) var cmd: String
    private(set) var handler: ((UIControl) -> Void)?
    private(set) var events: UIControl.Event
    
    init(handler: @escaping (UIControl) -> Void, events: UIControl.Event) {
        self.cmd = UUID().uuidString
        self.handler = handler
        self.events = events
        super.init()
    }
    
    var sel: Selector {
        return NSSelectorFromString(cmd)
    }
    
    func hasEvents(_ events: UIControl.Event) -> Bool {
        return (self.events.rawValue & events.rawValue) > 0
    }
    
    func removeEvents(_ events: UIControl.Event) {
        self.events = UIControl.Event(rawValue: self.events.rawValue & ~events.rawValue)
    }
    
    func invoke(with target: UIControl) {
        handler?(target)
    }
}

public extension UIControl {
    
    private static var actionDictKey: UInt8 = 0
    
    private var actionDict: [String: ControlAction] {
        get {
            return objc_getAssociatedObject(self, &UIControl.actionDictKey) as? [String: ControlAction] ?? [:]
        }
        set {
            objc_setAssociatedObject(self, &UIControl.actionDictKey, newValue, .OBJC_ASSOCIATION_RETAIN_NONATOMIC)
        }
    }
    
    @discardableResult
    func addHandler(_ handler: @escaping (UIControl) -> Void, for controlEvents: UIControl.Event) -> ControlAction? {
        
        let ca = ControlAction(handler: handler, events: controlEvents)
        var dict = actionDict
        dict[ca.cmd] = ca
        actionDict = dict
        addTarget(self, action: ca.sel, for: controlEvents)
        
        _ = UIControl.lazySwizzle
        
        return ca
    }
    
    func removeHandler(_ ca: ControlAction, for controlEvents: UIControl.Event) -> Bool {
        var dict = actionDict
        guard let existingCA = dict[ca.cmd], existingCA === ca, ca.hasEvents(controlEvents) else {
            return false
        }
        
        removeTarget(self, action: ca.sel, for: controlEvents)
        ca.removeEvents(controlEvents)
        
        if ca.events.rawValue == 0 {
            dict.removeValue(forKey: ca.cmd)
        }
        actionDict = dict
        return true
    }
    
    @objc private func a_sendAction(_ action: Selector, to target: Any?, for event: UIEvent?) -> Bool {
        var ca: ControlAction?
        if target as? UIControl == self {
            let cmd = NSStringFromSelector(action)
            ca = actionDict[cmd]
        }
        
        if let ca = ca {
            ca.invoke(with: self)
        } else {
            // 调用原始方法
            return self.a_sendAction(action, to: target, for: event)
        }
        
        return ca != nil
    }

    
    private static var lazySwizzle:() = {
        swizzleMethods()
    }()
    
    private static func swizzleMethods() {
        let cls = UIControl.self
        
        let originalSelector = #selector(UIControl.sendAction(_:to:for:))
        let swizzledSelector = #selector(UIControl.a_sendAction(_:to:for:))
        
        guard let originalMethod = class_getInstanceMethod(cls, originalSelector),
              let swizzledMethod = class_getInstanceMethod(cls, swizzledSelector) else {
            return
        }
        
        let didAddMethod = class_addMethod(
            cls,
            originalSelector,
            method_getImplementation(swizzledMethod),
            method_getTypeEncoding(swizzledMethod)
        )
        
        if didAddMethod {
            class_replaceMethod(
                cls,
                swizzledSelector,
                method_getImplementation(originalMethod),
                method_getTypeEncoding(originalMethod)
            )
        } else {
            method_exchangeImplementations(originalMethod, swizzledMethod)
        }
    }
}
