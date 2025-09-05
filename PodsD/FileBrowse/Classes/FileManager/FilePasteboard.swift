//
//  FilePasteboard.swift
//  FileBrowse
//
//  Created by Cityu on 2025/5/12.
//  Copyright © 2025 Cityu. All rights reserved.
//

import Foundation

public class FilePasteboard: NSObject {
    public var dirPath: String?
    public var files: [FileModel] = []
    
    public override init() {
        super.init()
    }
}
