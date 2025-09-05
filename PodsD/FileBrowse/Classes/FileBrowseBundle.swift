//
//  FileBrowseBundle.swift
//  FileBrowse
//
//  Created by Cityu on 2025/6/5.
//

import Foundation

public class FileBrowseBundle: NSObject {
    public static var frameworkBundle: Bundle {
        return Bundle(for: self)
    }
    
    public static var resourceBundle: Bundle? {
        guard let resourceBundlePath = frameworkBundle.path(forResource: "FileBrowse", ofType: "bundle") else {
            return nil
        }
        return Bundle(path: resourceBundlePath)
    }
}
