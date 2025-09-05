//
//  M3U8VideoDownloader.swift
//  iOS
//
//  Created by Cityu on 2025/6/6.
//  Copyright © 2025 Cityu. All rights reserved.
//

import Foundation
import M3U8

class M3U8VideoDownloader: DownloaderProtocol {
    
    private let downloader:VideoDownloader?
    
    var headers:[String:String]? {
        get {
            return downloader?.headers
        }
        set {
            downloader?.headers = newValue ?? [:]
        }
    }
    
    required public init(_ url: String, progress: @escaping (Float) -> Void, completion: @escaping (String?, Error?) -> Void) {
        downloader = VideoDownloader(url, progress: progress, completion: completion)
    }
    
    var isDownloading: Bool {
        return downloader?.isDownloading ?? false
    }
    
    var speed: UInt {
        return downloader?.speed ?? 0
    }
    
    func clearCache() {
        downloader?.clearCache()
    }
    
    func start() {
        downloader?.start()
    }
    
    func stop() {
        downloader?.stop()
    }
    
    
   
}
