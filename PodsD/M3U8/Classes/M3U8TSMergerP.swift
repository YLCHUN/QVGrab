//
//  M3U8TSMergerP.swift
//  QVGrab
//
//  Created by Cityu on 2025/4/4.
//

import Foundation
import TSFdn

class M3U8TSMergerP: M3U8TSMerger {
    private var tsMerger: TSMerger

    var dir: String? {
        get {
            tsMerger.dir
        }
        set {
            tsMerger.dir = newValue
        }
    }
    
    init(_ tsFiles: [String], progress: @escaping (Float) -> Void, completion: @escaping (String?, Error?) -> Void) {
        tsMerger = TSMerger(tsFiles: tsFiles, progress: progress, completion: completion)
    }
    deinit {
        stop()
    }
    
    // MARK: - M3U8TSMerger Protocol
    
    func start() {
        tsMerger.start()
    }
    
    func stop() {
        tsMerger.stop()
    }
    
    func pause() {
        tsMerger.pause()
    }
    
    func resume() {
        tsMerger.resume()
    }
    
    func clearCache() {
        tsMerger.clearCache()
    }
}
