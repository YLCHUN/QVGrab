//
//  DownloaderProtocol.swift
//  QVGrab
//
//  Created by Cityu on 2025/5/16.
//  Copyright © 2025 Cityu. All rights reserved.
//

import Foundation
import M3U8

protocol DownloaderProtocol {
    init(_ url: String, progress: @escaping (Float) -> Void, completion: @escaping (String?, Error?) -> Void)
    
    var headers: [String: String]? { get set }
    
    var isDownloading: Bool { get }
    var speed: UInt { get }
    
    func start(_ force: Bool)
    func start()
    func stop()
    
    func clearCache()
}

extension DownloaderProtocol {
    func start(_ force: Bool) {
        if force {
            stop()
            clearCache()
        }
        start()
    }
}
