//
//  DProgressModel.swift
//  iOS
//
//  Created by Cityu on 2025/5/15.
//  Copyright © 2025 Cityu. All rights reserved.
//

import Foundation

class DProgressModel: NSObject, NSCopying {
    var mid: String = ""
    var url: String = ""
    var name: String = ""
    var progress: Float = 0.0
    var mimeType: String?
    var src: String?
    
    // 内部属性
    var speed: UInt = 0
    
    func copy(with zone: NSZone? = nil) -> Any {
        let obj = DProgressModel()
        obj.mid = self.mid
        obj.name = self.name
        obj.url = self.url
        obj.mimeType = self.mimeType
        obj.progress = self.progress
        obj.src = self.src
        obj.speed = self.speed
        return obj
    }
}
