//
//  M3U8DownloaderProtocol.swift
//  M3U8
//
//  Created by Cityu on 2025/6/6.
//

import Foundation

/// M3U8下载器协议
public protocol M3U8DownloaderProtocol {
    
    /// 是否正在下载
    var isDownloading: Bool { get }
    
    /// 当前下载速度
    var speed: UInt { get }
    
    /// 开始下载
    func start(_ force: Bool)
    func start()

    /// 停止下载
    func stop()
}

public extension M3U8DownloaderProtocol {
    func start() {
        start(false)
    }
}
