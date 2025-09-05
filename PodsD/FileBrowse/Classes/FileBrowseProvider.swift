//
//  FileBrowseProvider.swift
//  FileBrowse
//
//  Created by Cityu on 2025/6/5.
//

import Foundation
import UIKit

public typealias FileBrowseDetailProvider = (FileModel) -> FileBrowseDetailProtocol?
public typealias FileBrowseProgressProvider = (FileModel) -> CGFloat

public class FileBrowseProvider: NSObject {
    public static var detailProvider: FileBrowseDetailProvider?
    public static var progressProvider: FileBrowseProgressProvider?
    
    public static func detail(_ file: FileModel) -> FileBrowseDetailProtocol? {
        return detailProvider?(file)
    }
    
    public static func progress(_ file: FileModel) -> CGFloat {
        return progressProvider?(file) ?? 0
    }
}
