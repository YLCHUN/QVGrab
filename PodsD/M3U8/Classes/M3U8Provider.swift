//
//  M3U8Provider.swift
//  M3U8
//
//  Created by Cityu on 2025/6/5.
//

import Foundation

/// M3U8下载器提供者类型
public typealias M3U8DownloaderProvider = (String, [String: String], @escaping (Float) -> Void, @escaping (String?, Error?) -> Void) -> M3U8DownloaderProtocol

/// M3U8下载器提供者
public class M3U8Provider {
    
    /// 下载器提供者
    public static var downloaderProvider: M3U8DownloaderProvider?
    
    /// 创建下载器
    /// - Parameters:
    ///   - url: 下载URL
    ///   - headers: 请求头
    ///   - progress: 进度回调
    ///   - completion: 完成回调
    /// - Returns: 下载器实例
    static func downloader(url: String, headers: [String: String], progress: @escaping (Float) -> Void, completion: @escaping (String?, Error?) -> Void) -> M3U8DownloaderProtocol? {
        return downloaderProvider?(url, headers, progress, completion)
    }
}
