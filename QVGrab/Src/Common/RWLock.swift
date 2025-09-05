//
//  RWLock.swift
//  iOS
//
//  Created by Cityu on 2025/8/6.
//  Copyright © 2025 Cityu. All rights reserved.
//

import Foundation

class RWLock {
    private let condition = NSCondition()
    private var isWriting = false
    private var readingCount = 0
    
    func readingLock() {
        condition.lock()
        while isWriting {
            condition.wait()
        }
        readingCount += 1
        condition.unlock()
    }
    
    func readingUnlock() {
        condition.lock()
        readingCount -= 1
        if readingCount == 0 {
            condition.broadcast()
        }
        condition.unlock()
    }
    
    func writingLock() {
        condition.lock()
        while isWriting || readingCount > 0 {
            condition.wait()
        }
        isWriting = true
        condition.unlock()
    }
    
    func writingUnlock() {
        condition.lock()
        isWriting = false
        condition.broadcast()
        condition.unlock()
    }
}
