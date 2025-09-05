//
//  LogLViewController.swift
//  iOS
//
//  Created by Cityu on 2025/7/14.
//  Copyright © 2025 Cityu. All rights reserved.
//

import UIKit
import LithUI


class LogLViewController: UIViewController {
    
    /// 日志输出视图，不可编辑
    private(set) var textView: UITextView!
    
    private var navigationBar: UINavigationBar!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        title = "LogL"
        
        if #available(iOS 13.0, *) {
            view.backgroundColor = UIColor.systemBackground
        } else {
            view.backgroundColor = UIColor.white
        }
        
        setupSubview()
        
        // 设置 LogLine 的 delegate
        LogLine.shared.delegate = self
        
        // 显示已有日志
        displayExistingLogs()
        
        // 设置导航栏标题
        navigationBar.items = [navigationItem]
    }
    
    private func setupSubview() {
        navigationBar = UINavigationBar()
        navigationBar.isTranslucent = false
        view.addSubview(navigationBar)
        navigationBar.snp.makeConstraints { make in
            make.left.right.equalTo(view)
            if #available(iOS 11.0, *) {
                make.top.equalTo(view.safeAreaLayoutGuide.snp.top)
            } else {
                make.top.equalTo(view)
            }
            make.height.equalTo(44) // UINavigationBar 标准高度
        }
        
        view.addSubview(textView)
        textView.snp.makeConstraints { make in
            make.left.right.bottom.equalTo(view)
            make.top.equalTo(navigationBar.snp.bottom).offset(8)
        }
    }
    
    deinit {
        NotificationCenter.default.removeObserver(self)
    }
    
    // MARK: - 日志显示
    
    private func displayExistingLogs() {
        let logs = LogLine.shared.allLogs
        if !logs.isEmpty {
            let allLogs = logs.joined(separator: "\n")
            textView.text = allLogs
            
            // 滚动到底部
            let range = NSRange(location: textView.text.count, length: 0)
            textView.scrollRangeToVisible(range)
        }
    }
    
    // MARK: - Getter
    
    private func createTextView() -> UITextView {
        let textView = UITextView()
        textView.isEditable = false
        textView.isSelectable = true
        textView.textColor = UIColor.color(lightHex: "#000000", darkHex: "#FFFFFF")
        textView.font = UIFont.systemFont(ofSize: 14)
        textView.showsVerticalScrollIndicator = true
        textView.showsHorizontalScrollIndicator = false
        textView.alwaysBounceVertical = true
        textView.textContainerInset = UIEdgeInsets(top: 8, left: 8, bottom: 8, right: 8)
        textView.layer.cornerRadius = 8
        textView.layer.masksToBounds = true
        return textView
    }
    
    override func loadView() {
        super.loadView()
        textView = createTextView()
    }
}

// MARK: - LogLineDelegate

extension LogLViewController: LogLineDelegate {
    func logLineDidReceiveLog(_ logMessage: String, level: LogLevel) {
        DispatchQueue.main.async {
            guard let tv = self.textView else { return }
            // 判断是否在底部
            var isAtBottom = false
            let contentHeight = tv.contentSize.height
            let visibleHeight = tv.bounds.size.height
            let offsetY = tv.contentOffset.y
            // 允许2像素误差
            if contentHeight > visibleHeight && offsetY + visibleHeight >= contentHeight - 2 {
                isAtBottom = true
            }
            
            // 追加日志到textView末尾
            let oldText = tv.text ?? ""
            let newText = oldText + "\(logMessage)\n"
            tv.text = newText
            
            // 仅在原本就在底部时才滚动到底部
            if isAtBottom {
                let range = NSRange(location: tv.text.count, length: 0)
                tv.scrollRangeToVisible(range)
            }
        }
    }
    
    func logLineDidClearAllLogs() {
        DispatchQueue.main.async {
            self.textView.text = ""
        }
    }
}
