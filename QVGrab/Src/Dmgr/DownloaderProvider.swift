//
//  DownloaderProvider.swift
//  iOS
//
//  Created by Cityu on 2025/6/6.
//  Copyright © 2025 Cityu. All rights reserved.
//

import Foundation
import M3U8

typealias DownloaderT = DownloaderProtocol

/// 下载器提供者，支持注册任何符合协议的类型
class DownloaderProvider {
    
    /// 存储注册的下载器类型
    static private var dt: DownloaderT.Type?
    
    /// 注册下载器类型并设置到 M3U8Provider
    /// - Parameter t: 具体的下载器类型，必须符合 DownloaderT
    static func register<T: DownloaderT>(_ t: T.Type) {
        dt = t
        
        guard let t = t as? any (DownloaderProtocol & M3U8DownloaderProtocol).Type  else {
            return
        }
        M3U8Provider.downloaderProvider = { url, headers, progress, completion in
            return create(with: t, url: url, headers: headers, progress: progress, completion: completion)
        }
    }
    
    static func create(with url: String, headers: [String: String]? = nil, progress: @escaping (Float) -> Void, completion: @escaping (String?, Error?) -> Void) -> DownloaderT {
        
        guard let dt = dt else {
            fatalError("DownloaderProvider 需要先调用 register")
        }
        return create(with: dt, url: url, headers: headers, progress: progress, completion: completion)
    }
    
    private static func create<T: DownloaderT>(with t:T.Type, url: String, headers: [String: String]? = nil, progress: @escaping (Float) -> Void, completion: @escaping (String?, Error?) -> Void) -> T {
        var downloader = t.init(url, progress: progress, completion: completion)
        downloader.headers = headers
        return downloader
    }
}
