//
//  SpeedMeter.swift
//  iOS
//
//  Created by Cityu on 2025/7/23.
//  Copyright © 2025 Cityu. All rights reserved.
//

import Foundation

class SpeedMeter {
    private var currentSpeed: Double = -1
    private var lastCompletedBytes: Int64 = 0
    private var lastTimestamp: TimeInterval = 0
    
    var speed: Double {
        return max(currentSpeed, 0)
    }
    
    init() {
        reset()
    }
    
    func reset() {
        currentSpeed = -1
        lastCompletedBytes = 0
        lastTimestamp = Date.timeIntervalSinceReferenceDate
    }
    
    func meterCompletedBytes(_ bytes: Double) {
        let currentTime = Date.timeIntervalSinceReferenceDate
        let timeDiff = currentTime - lastTimestamp
        
        if timeDiff >= 0.5 || currentSpeed < 0 {
            let bytesDiff = Int64(bytes) - lastCompletedBytes
            if bytesDiff > 0 && timeDiff > 0 {
                let speed = Double(bytesDiff) / timeDiff
                lastCompletedBytes = Int64(bytes)
                lastTimestamp = currentTime
                currentSpeed = speed
            }
        }
    }
}
