//
//  WebViewSessionManager.swift
//  iOS
//
//  Created by Cityu on 2025/7/24.
//  Copyright © 2025 Cityu. All rights reserved.
//

import Foundation
import WebKit

enum WebViewSessionInsertPos: Int {
    case normal = 0    // 在末尾添加
    case current = 1   // 在当前会话位置添加
    case nearby = 2    // 在当前会话附近添加
}

struct WebViewSessionChangeType: OptionSet {
    let rawValue: Int
    
    static let normal = WebViewSessionChangeType(rawValue: 0)
    static let sessions = WebViewSessionChangeType(rawValue: 1 << 0) // sessions 发生变化
    static let current = WebViewSessionChangeType(rawValue: 1 << 1)  // current 发生变化
}

protocol WebViewSessionManagerDelegate: AnyObject {
    func sessionMgr(_ sessionMgr: WebViewSessionManager, changeType: WebViewSessionChangeType)
}

class WebViewSessionManager {
    weak var delegate: WebViewSessionManagerDelegate?
    private var _currentIndex: Int = NSNotFound
    var currentIndex: Int {
        get {
           return _currentIndex
        }
        set {
            guard newValue < sessions.count else { return }
            
            if _currentIndex != newValue {
                _currentIndex = newValue
                notifyDelegateWithChangeType(.current)
            }
        }
    }
    private(set) var sessions: [WebViewSession] = []
    
    var current: WebViewSession? {
        guard _currentIndex < sessions.count else { return nil }
        return sessions[_currentIndex]
    }
    
    var sessionsArray: [WebViewSession] {
        return sessions
    }
    
    init() {
        _currentIndex = NSNotFound
    }
    
    // MARK: - Public Methods
    
    func insertSessionWithConfig(_ conf: WKWebViewConfiguration?, indexType: WebViewSessionInsertPos) -> WebViewSession {
        // 创建新的 WebView 配置
        var config = conf
        if config == nil {
            config = WKWebViewConfiguration()
            config?.allowsInlineMediaPlayback = true
            config?.mediaTypesRequiringUserActionForPlayback = []
            config?.preferences.javaScriptEnabled = true
            config?.preferences.setValue(true, forKey: "developerExtrasEnabled")
        }
        
        let session = WebViewSession(configuration: config!)
        
        // 根据索引类型决定插入位置
        var insertIndex = 0
        switch indexType {
        case .normal:
            // 添加到末尾
            insertIndex = sessions.count
        case .current:
            // 添加到当前会话之后
            insertIndex = (_currentIndex == NSNotFound) ? 0 : _currentIndex + 1
        case .nearby:
            // 添加到当前会话附近（如果当前会话存在，则在其后；否则添加到开头）
            insertIndex = (_currentIndex == NSNotFound) ? 0 : min(_currentIndex + 1, sessions.count)
        }
        
        // 插入会话
        sessions.insert(session, at: insertIndex)
        
        // 记录是否当前索引发生变化
        var currentIndexChanged = false
        
        // 更新当前索引
        if _currentIndex == NSNotFound {
            _currentIndex = 0
            currentIndexChanged = true
        } else if insertIndex <= _currentIndex {
            // 只有当插入位置在当前会话或之前时，才需要更新当前索引
            _currentIndex += 1
            currentIndexChanged = true
        }
        
        // 通知代理
        var changeType: WebViewSessionChangeType = .sessions
        if currentIndexChanged {
            changeType.insert(.current)
        }
        
        DispatchQueue.main.async {
            self.notifyDelegateWithChangeType(changeType)
        }
        
        return session
    }
    
    func delSession(_ index: Int) {
        guard index < sessions.count else { return }
        
        // 记录是否当前索引发生变化
        var currentIndexChanged = false
        
        // 清理要删除的会话资源
        let sessionToDelete = sessions[index]
        sessionToDelete.webView.stopLoading()
        sessionToDelete.webView.loadHTMLString("", baseURL: nil)
        
        // 移除会话
        sessions.remove(at: index)
        
        // 更新当前索引
        if sessions.isEmpty {
            _currentIndex = NSNotFound
            currentIndexChanged = true
        } else if index < _currentIndex {
            _currentIndex -= 1
            currentIndexChanged = true
        } else if index == _currentIndex {
            // 如果删除的是当前会话，需要选择新的当前会话
            if _currentIndex >= sessions.count {
                _currentIndex = sessions.count - 1
            }
            currentIndexChanged = true
        }
        
        // 通知代理
        var changeType: WebViewSessionChangeType = .sessions
        if currentIndexChanged {
            changeType.insert(.current)
        }
        notifyDelegateWithChangeType(changeType)
    }
    

    func clearAllSessions() {
        clearAllSessionsAndCreateNew(true)
    }
    
    func clearAllSessionsAndCreateNew(_ createNew: Bool) {
        if !sessions.isEmpty {
            // 清理所有会话的资源
            for session in sessions {
                // 清理 WebView 资源
                session.webView.stopLoading()
                session.webView.loadHTMLString("", baseURL: nil)
            }
            
            sessions.removeAll()
            _currentIndex = NSNotFound
            
            notifyDelegateWithChangeType([.sessions, .current])
        }
    }
    
    var sessionCount: Int {
        return sessions.count
    }
    
    var hasSessions: Bool {
        return !sessions.isEmpty
    }
    
    func sessionAtIndex(_ index: Int) -> WebViewSession? {
        guard index < sessions.count else { return nil }
        return sessions[index]
    }
    
    func sessionIndex(_ session: WebViewSession) -> Int {
//        guard let session = session else { return NSNotFound }
        return sessions.firstIndex(of: session) ?? NSNotFound
    }
    
    // MARK: - Private Methods
    
    private func notifyDelegateWithChangeType(_ changeType: WebViewSessionChangeType) {
        delegate?.sessionMgr(self, changeType: changeType)
    }
}
