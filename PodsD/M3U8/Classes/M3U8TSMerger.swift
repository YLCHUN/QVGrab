//
//  M3U8TSMerger.swift
//  M3U8
//
//  Created by Cityu on 2025/6/23.
//

import Foundation

/// M3U8 TS合并器协议
protocol M3U8TSMerger {
    
    /// 输出目录
    var dir: String? { get set }
    
    /// 开始合并
    func start()
    
    /// 停止合并
    func stop()
    
    /// 暂停合并
    func pause()
    
    /// 恢复合并
    func resume()
    
    /// 清理缓存
    func clearCache()
}
