//
//  FileSortMode.swift
//  FileBrowse
//
//  Created by Cityu on 2025/6/18.
//

import Foundation

// 排序模式常量定义
public enum FileSortMode: String, CaseIterable {
    case byUnknow = "unknow"
    case byName = "name"
    case byCreateTime = "creatTime"
    case byModTime = "modTime"
    case byFileSizefloat = "fileSizefloat"
    case byType = "fileType"
    case byExtension = "fileExtension"
    case byIsDir = "isDir"
    case byHidden = "isHidden"
}


extension [FileModel] {
    public func sort(_ modes: [FileSortMode], ascendings: [Bool]) -> [FileModel] {
        let files = self
        guard !files.isEmpty && !modes.isEmpty else { return files }
        
        // 获取第一个文件的目录配置
        let firstFile = files.first!
        let dirPath = firstFile.filePath.deletingLastPathComponent
        let dirConf = FileDirConf.loadFromPath(dirPath)
        
        return files.sorted { file1, file2 in
            // 如果有目录配置，优先使用目录配置的排序方式
            if let dirConf = dirConf {
                let result = compareFiles(file1, file2, mode: dirConf.sortMode, ascending: dirConf.isAscending)
                if result != .orderedSame {
                    return result == .orderedAscending
                }
            }
            
            // 添加其他排序条件
            for (index, mode) in modes.enumerated() {
                // 如果这个排序模式已经被目录配置使用，跳过
                if let dirConf = dirConf, mode == dirConf.sortMode {
                    continue
                }
                
                let ascending = index < ascendings.count ? ascendings[index] : true
                let result = compareFiles(file1, file2, mode: mode, ascending: ascending)
                if result != .orderedSame {
                    return result == .orderedAscending
                }
            }
            
            return false
        }
    }
    
    private func compareFiles(_ file1: FileModel, _ file2: FileModel, mode: FileSortMode, ascending: Bool) -> ComparisonResult {
        let result: ComparisonResult
        
        switch mode {
        case .byName:
            result = file1.name.localizedStandardCompare(file2.name)
        case .byFileSizefloat:
            if file1.fileSizefloat < file2.fileSizefloat {
                result = .orderedAscending
            } else if file1.fileSizefloat > file2.fileSizefloat {
                result = .orderedDescending
            } else {
                result = .orderedSame
            }
        case .byType:
            result = file1.fileExtensionString().compare(file2.fileExtensionString())
        case .byExtension:
            result = file1.fileExtensionString().compare(file2.fileExtensionString())
        case .byIsDir:
            if file1.isDir && !file2.isDir {
                result = .orderedAscending
            } else if !file1.isDir && file2.isDir {
                result = .orderedDescending
            } else {
                result = .orderedSame
            }
        case .byHidden:
            let hidden1 = file1.name.hasPrefix(".")
            let hidden2 = file2.name.hasPrefix(".")
            if hidden1 && !hidden2 {
                result = .orderedAscending
            } else if !hidden1 && hidden2 {
                result = .orderedDescending
            } else {
                result = .orderedSame
            }
        case .byModTime:
            result = file1.modTime.compare(file2.modTime)
        case .byCreateTime:
            result = file1.creatTime.compare(file2.creatTime)
        default:
            result = .orderedSame
        }
        
        return ascending ? result : result.reversed
    }
}

extension ComparisonResult {
    var reversed: ComparisonResult {
        switch self {
        case .orderedAscending: return .orderedDescending
        case .orderedDescending: return .orderedAscending
        case .orderedSame: return .orderedSame
        }
    }
}
