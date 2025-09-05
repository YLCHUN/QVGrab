//
//  KeyboardDismisser.swift
//  iOS
//
//  Created by Cityu on 2025/7/18.
//  Copyright © 2025 Cityu. All rights reserved.
//

import Foundation
import UIKit

public class KeyboardDismisser: NSObject {
    
    private var tm: TouchMonitor!
    
    public init(view: UIView) {
        super.init()
        
        tm = TouchMonitor()
        tm.view = view
        tm.enabled = false
        tm.delegate = self
        
        NotificationCenter.default.addObserver(
            self,
            selector: #selector(keyboardWillShow(_:)),
            name: UIResponder.keyboardWillShowNotification,
            object: nil
        )
        
        NotificationCenter.default.addObserver(
            self,
            selector: #selector(keyboardDidHide(_:)),
            name: UIResponder.keyboardDidHideNotification,
            object: nil
        )
    }
    
    deinit {
        NotificationCenter.default.removeObserver(self)
    }
    
    @objc private func keyboardWillShow(_ notification: Notification) {
        tm.enabled = true
    }
    
    @objc private func keyboardDidHide(_ notification: Notification) {
        tm.enabled = false
    }
}

// MARK: - TouchMonitorDelegate
extension KeyboardDismisser: TouchMonitorDelegate {
    
    func touchMonitor(_ monitor: TouchMonitor, touchesEnded touches: Set<UITouch>, with event: UIEvent?) {
        let touch = touches.first
        var view = touch?.view
        
        var inTextInput = false
        for _ in 0..<10 {
            guard let v = view else { break }
            if v.conforms(to: UITextInput.self) {
                inTextInput = true
                break
            }
            view = v.superview
        }
        
        if !inTextInput {
            tm.view?.endEditing(false)
        }
    }
}
