//
//  InputButton.swift
//  QVGrab
//
//  Created by Cityu on 2025/4/4.
//

import UIKit


class InputButton: UIView {
    
    private(set) var coreInput: UIView & UITextInput
    private let overlayView = UIView()
    private let singleTapGesture: UITapGestureRecognizer
    private let doubleTapGesture: UITapGestureRecognizer
    private weak var target: AnyObject?
    private var action: Selector?
    
    init(coreInput: UIView & UITextInput) {
        self.coreInput = coreInput
        singleTapGesture = UITapGestureRecognizer()
        doubleTapGesture = UITapGestureRecognizer()
        
        super.init(frame: coreInput.frame)
        setupUI()
        setupGestures()
        setupNotifications()
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    override func sizeThatFits(_ size: CGSize) -> CGSize {
        var size = size
        size.height = coreInput.sizeThatFits(size).height
        return size
    }
    
    private func setupUI() {
        // 设置自身大小与coreInput一致
        frame = coreInput.frame
        
        // 添加coreInput
        addSubview(coreInput)
        coreInput.frame = bounds
        
        // 创建并添加透明覆盖层
        overlayView.backgroundColor = UIColor.clear
        addSubview(overlayView)
    }
    
    override func layoutSubviews() {
        super.layoutSubviews()
        coreInput.frame = bounds
        overlayView.frame = bounds
    }
    
    private func setupGestures() {
        // 添加单击手势
        singleTapGesture.addTarget(self, action: #selector(handleSingleTap))
        overlayView.addGestureRecognizer(singleTapGesture)
        
        // 添加双击手势
        doubleTapGesture.numberOfTapsRequired = 2
        doubleTapGesture.addTarget(self, action: #selector(handleDoubleTap))
        overlayView.addGestureRecognizer(doubleTapGesture)
        
        // 设置手势优先级
        singleTapGesture.require(toFail: doubleTapGesture)
    }
    
    private func setupNotifications() {
        // 根据coreInput类型添加不同的通知监听
        if coreInput is UITextField {
            // UITextField 的通知
            NotificationCenter.default.addObserver(
                self,
                selector: #selector(keyboardDidHide(_:)),
                name: UITextField.textDidEndEditingNotification,
                object: coreInput
            )
        } else if coreInput is UITextView {
            // UITextView 的通知
            NotificationCenter.default.addObserver(
                self,
                selector: #selector(keyboardDidHide(_:)),
                name: UITextView.textDidEndEditingNotification,
                object: coreInput
            )
        }
    }
    
    @objc private func handleSingleTap() {
        // 隐藏覆盖层
        overlayView.isHidden = true
        
        // 让coreInput成为第一响应者
        coreInput.becomeFirstResponder()
    }
    
    @objc private func handleDoubleTap() {
        // 如果有设置target和action，则调用
        if let target = target, let action = action, target.responds(to: action) {
            _ = target.perform(action, with: self)
        }
    }
    
    @objc private func keyboardDidHide(_ notification: Notification) {
        // 恢复覆盖层可见
        overlayView.isHidden = false
    }
    
    func setTarget(_ target: AnyObject?, action: Selector?) {
        self.target = target
        self.action = action
    }
    
    deinit {
        NotificationCenter.default.removeObserver(self)
    }
}
