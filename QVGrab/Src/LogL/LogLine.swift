//
//  LogLine.swift
//  iOS
//
//  Created by Cityu on 2025/7/14.
//  Copyright © 2025 Cityu. All rights reserved.
//

import Foundation

/// 日志级别枚举
enum LogLevel: Int {
    case debug = 0    // 调试信息
    case info         // 一般信息
    case warning      // 警告信息
    case error        // 错误信息
    case fatal        // 致命错误
}

/// LogLine 代理协议
protocol LogLineDelegate: AnyObject {
    /// 当有新日志时调用
    /// - Parameters:
    ///   - logMessage: 日志消息
    ///   - level: 日志级别
    func logLineDidReceiveLog(_ logMessage: String, level: LogLevel)
    
    /// 当日志被清空时调用
    func logLineDidClearAllLogs()
}

/// 日志记录器
class LogLine {
    
    /// 单例方法
    static let shared = LogLine()
    
    /// 设置日志级别，只显示该级别及以上的日志
    var logLevel: LogLevel = .debug
    
    /// 是否启用日志记录
    var enabled: Bool = true
    
    /// 最大日志条数，超过后自动清理旧日志
    var maxLogCount: Int = 1000
    
    var allLogs:[String] {
        var log:[String]!
        logQueue.sync {
            log = self.logs
        }
        return log
    }
    
    /// 代理对象
    weak var delegate: LogLineDelegate?
    
    private var logs: [String] = []
    private let dateFormatter: DateFormatter
    private let logQueue: DispatchQueue
    
    private init() {
        logs = []
        logLevel = .debug
        enabled = true
        maxLogCount = 1000
        
        dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "yyyy-MM-dd HH:mm:ss.SSS"
        
        logQueue = DispatchQueue(label: "com.qvgrab.logline", qos: .utility)
    }
    
    // MARK: - Public Methods
    /// 清空所有日志
    func clearAllLogs() {
        logQueue.async {
            self.logs.removeAll()
            
            // 通知 delegate 日志已清空
            DispatchQueue.main.async {
                self.delegate?.logLineDidClearAllLogs()
            }
        }
    }
    
    /// 记录调试日志
    func debug(_ message: String) {
        logWithLevel(.debug, message: message)
    }
    
    /// 记录一般信息日志
    func info(_ message: String) {
        logWithLevel(.info, message: message)
    }
    
    /// 记录警告日志
    func warning(_ message: String) {
        logWithLevel(.warning, message: message)
    }
    
    /// 记录错误日志
    func error(_ message: String) {
        logWithLevel(.error, message: message)
    }
    
    /// 记录致命错误日志
    func fatal(_ message: String) {
        logWithLevel(.fatal, message: message)
    }
    
    /// 记录指定级别的日志
    func logWithLevel(_ level: LogLevel, message: String) {
        guard enabled && level.rawValue >= logLevel.rawValue && !message.isEmpty else { return }
        
        logQueue.async {
            let levelString = self.levelStringForLevel(level)
            let timestamp = self.dateFormatter.string(from: Date())
            let logMessage = "\(levelString) [\(timestamp)] \(message) \n"
            
            self.logs.append(logMessage)
            
            // 限制日志数量
            if self.logs.count > self.maxLogCount {
                let removeCount = self.logs.count - self.maxLogCount
                self.logs.removeFirst(removeCount)
            }
            
            // 发送通知到主线程
            DispatchQueue.main.async {
                // 调用 delegate 方法
                self.delegate?.logLineDidReceiveLog(logMessage, level: level)
            }
        }
    }
    
    /// 记录带格式的日志
    func logWithLevel(_ level: LogLevel, format: String, _ arguments: CVarArg...) {
        let message = String(format: format, arguments: arguments)
        logWithLevel(level, message: message)
    }
    
    // MARK: - Private Methods
    
    private func levelStringForLevel(_ level: LogLevel) -> String {
        switch level {
        case .debug:
            return "⚪️DEBUG"
        case .info:
            return "🟢INFO"
        case .warning:
            return "🟡WARN"
        case .error:
            return "🟤ERROR"
        case .fatal:
            return "🔴FATAL"
        }
    }
}
