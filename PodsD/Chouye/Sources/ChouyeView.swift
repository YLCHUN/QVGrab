//
//  ChouyeView.swift
//  Chouye
//
//  Created by Cityu on 2025/7/18.
//

import UIKit
import ObjectiveC

private class ChouyeBlock : NSObject {
    let block: (UIView) -> Void
    private init(block: @escaping (UIView) -> Void) {
        self.block = block
    }
    static func block(_ block: ((UIView) -> Void)?)->ChouyeBlock? {
        guard let block = block else {
            return nil
        }
        return ChouyeBlock(block: block)
    }
}

public extension UIView {
    private static var cBlockKey: UInt8 = 0
    
    var chouyeBlock: ((UIView) -> Void)? {
        get {
            return objc_getAssociatedObject(self, &UIView.cBlockKey) as? (UIView) -> Void
        }
        set {
            objc_setAssociatedObject(self, &UIView.cBlockKey, newValue, .OBJC_ASSOCIATION_COPY_NONATOMIC)
            newValue?(self)
            
            _ = UIView.lazySwizzle
        }
    }
    
    private static var lazySwizzle:() = {
        swizzleMethods()
    }()
    
    private static func swizzleMethods() {
        let cls = UIView.self

        let originalSelector = #selector(UIView.traitCollectionDidChange(_:))
        let swizzledSelector = #selector(UIView.cb_traitCollectionDidChange(_:))
        
        guard let originalMethod = class_getInstanceMethod(cls, originalSelector),
              let swizzledMethod = class_getInstanceMethod(cls, swizzledSelector) else {
            return
        }
        
        let didAddMethod = class_addMethod(cls, originalSelector, method_getImplementation(swizzledMethod), method_getTypeEncoding(swizzledMethod))
        
        if didAddMethod {
            class_replaceMethod(cls, swizzledSelector, method_getImplementation(originalMethod), method_getTypeEncoding(originalMethod))
        } else {
            method_exchangeImplementations(originalMethod, swizzledMethod)
        }
    }
    
    @objc private func cb_traitCollectionDidChange(_ previousTraitCollection: UITraitCollection?) {
        cb_traitCollectionDidChange(previousTraitCollection)
        
        if #available(iOS 13.0, *) {
            if let chouyeBlock = chouyeBlock, traitCollection.hasDifferentColorAppearance(comparedTo: previousTraitCollection) {
                chouyeBlock(self)
            }
        }
    }
}

