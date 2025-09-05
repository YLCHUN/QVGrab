//
//  PathString.swift
//  FileBrowse
//
//  Created by YLCHUN on 2025/9/5.
//

import Foundation

 extension String {
    func appending(pathComponent:String)->String {
        return (self as NSString).appendingPathComponent(pathComponent)
    }
    var lastPathComponent :String {
        return (self as NSString).lastPathComponent
    }
    var deletingLastPathComponent :String {
        return (self as NSString).deletingLastPathComponent
    }
    var pathExtension:String {
        return (self as NSString).pathExtension
    }
    var deletingPathExtension:String {
        return (self as NSString).deletingPathExtension
    }
}
