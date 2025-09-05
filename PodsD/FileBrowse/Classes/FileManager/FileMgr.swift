//
//  FileMgr.swift
//  FileBrowse
//
//  Created by Cityu on 2025/4/25.
//

import Foundation

public class FileMgr: NSObject {
    public static let shared = FileMgr()
    
    public var pasteboard: FilePasteboard?
    private let fileManager = FileManager.default
    
    private override init() {
        super.init()
    }
    
    // 为了保持与Objective-C版本的兼容性，添加shareManager方法
    public static var shareManager: FileMgr {
        return shared
    }
    
    // MARK: - File Operations
    public func getFileWithPath(_ path: String) -> FileModel {
        return FileModel(filePath: path)
    }
    
    public func getAllFileWithPath(_ path: String) -> [FileModel] {
        var files: [FileModel] = []
        do {
            let subPathsArray = try fileManager.contentsOfDirectory(atPath: path)
            for str in subPathsArray {
                if str == FileDirConf.configFileName {
                    continue
                }
                let file = FileModel(filePath: path.appending(pathComponent: str))
                files.append(file)
            }
        } catch {
            print("Error reading directory: \(error)")
        }
        return files
    }
    
    public func getAllFileInPathWithSurfaceSearch(_ path: String) -> [FileModel] {
        var files: [FileModel] = []
        do {
            let subPathsArray = try fileManager.contentsOfDirectory(atPath: path)
            for str in subPathsArray {
                let file = FileModel(filePath: path.appending(pathComponent: str))
                if !file.isDir {
                    files.append(file)
                }
            }
        } catch {
            print("Error reading directory: \(error)")
        }
        return files
    }
    
    public func getAllFileInPathWithDeepSearch(_ path: String) -> [FileModel] {
        var files: [FileModel] = []
        do {
            let subPathsArray = try fileManager.contentsOfDirectory(atPath: path)
            for str in subPathsArray {
                let file = FileModel(filePath: path.appending(pathComponent: str))
                if file.isDir {
                    files.append(contentsOf: getAllFileInPathWithDeepSearch(file.filePath))
                } else {
                    files.append(file)
                }
            }
        } catch {
            print("Error reading directory: \(error)")
        }
        return files
    }
    
    public func fileExistsAtPath(_ path: String) -> Bool {
        return fileManager.fileExists(atPath: path)
    }
    
    public func createFolderToPath(_ path: String, folderName: String) -> Bool {
        let fullPath = path.appending(pathComponent: folderName)
        return createFolderToFullPath(fullPath)
    }
    
    @discardableResult
    public func createFolderToFullPath(_ fullPath: String) -> Bool {
        do {
            try fileManager.createDirectory(atPath: fullPath, withIntermediateDirectories: true, attributes: nil)
            return true
        } catch {
            print("Error creating directory: \(error)")
            return false
        }
    }
    
    @discardableResult
    public func createFileToPath(_ path: String, fileName: String) -> Bool {
        let fullPath = path.appending(pathComponent: fileName)
        return createFileToFullPath(fullPath)
    }
    
    public func createFileToFullPath(_ fullPath: String) -> Bool {
        return fileManager.createFile(atPath: fullPath, contents: nil, attributes: nil)
    }
    
    public func addFile(_ file: Any, toPath path: String, fileName: String) -> Bool {
        let fullPath = path.appending(pathComponent: fileName)
        do {
            if let data = file as? Data {
                let url = URL(fileURLWithPath: fullPath)
                try data.write(to: url, options: .atomic)
                return true
            } else if let string = file as? String {
                
                try string.write(toFile: fullPath, atomically: true, encoding: .utf8)
                return true
            } else if let dict = file as? [String: Any] {
                let data = try JSONSerialization.data(withJSONObject: dict, options: [])
                try data.write(to: URL(fileURLWithPath: fullPath), options: .atomic)
                return true
            } else {
                return false
            }
        } catch {
            return false
        }
    }
    
    public func deleteFileWithPath(_ path: String) -> Bool {
        do {
            try fileManager.removeItem(atPath: path)
            return true
        } catch {
            print("Error deleting file: \(error)")
            return false
        }
    }
    
    public func moveFile(_ oldPath: String, toNewPath newPath: String) -> Bool {
        let finalPath = newPath.appending(pathComponent: oldPath.lastPathComponent)
        do {
            try fileManager.moveItem(atPath: oldPath, toPath: finalPath)
            return true
        } catch {
            print("Error moving file: \(error)")
            return false
        }
    }
    
    public func moveFile(_ oldPath: String, toNewPath newPath: String, rename: String, isOverwrite: Bool) -> String? {
        var isDir: ObjCBool = false
        guard fileManager.fileExists(atPath: oldPath, isDirectory: &isDir) else {
            return nil
        }
        
        // 1. 目标目录
        let directory = newPath
        if !fileManager.fileExists(atPath: directory) {
            do {
                try fileManager.createDirectory(atPath: directory, withIntermediateDirectories: true, attributes: nil)
            } catch {
                print("Error creating directory: \(error)")
            }
        }
        
        // 2. 目标名称
        let targetName = rename.isEmpty ? oldPath.lastPathComponent : rename
        var finalPath = directory.appending(pathComponent: targetName)
        
        // 3. 自动递增文件/目录名
        if !isOverwrite {
            var index = 1
            if isDir.boolValue {
                // 目录：直接在名称后加 _1, _2
                let baseName = targetName
                while fileManager.fileExists(atPath: finalPath) {
                    let newName = "\(baseName)_\(index)"
                    finalPath = directory.appending(pathComponent: newName)
                    index += 1
                }
            } else {
                // 文件：主文件名后加 _1, _2，保留扩展名
                let baseName = targetName.deletingPathExtension
                let ext = targetName.pathExtension
                while fileManager.fileExists(atPath: finalPath) {
                    let newName = ext.isEmpty ? "\(baseName)_\(index)" : "\(baseName)_\(index).\(ext)"
                    finalPath = directory.appending(pathComponent: newName)
                    index += 1
                }
            }
        } else {
            _ = deleteFileWithPath(finalPath)
        }
        
        do {
            try fileManager.moveItem(atPath: oldPath, toPath: finalPath)
            return finalPath
        } catch {
            print("Error moving file: \(error)")
            return nil
        }
    }
    
    public func copyFile(_ oldPath: String, toNewPath newPath: String) -> Bool {
        let finalPath = newPath.appending(pathComponent: oldPath.lastPathComponent)
        do {
            try fileManager.copyItem(atPath: oldPath, toPath: finalPath)
            return true
        } catch {
            print("Error copying file: \(error)")
            return false
        }
    }
    
    public func renameFileWithPath(_ path: String, oldName: String, newName: String) -> Bool {
        let oldPath = path.appending(pathComponent: oldName)
        let newPath = path.appending(pathComponent: newName)
        do {
            try fileManager.moveItem(atPath: oldPath, toPath: newPath)
            return true
        } catch {
            print("Error renaming file: \(error)")
            return false
        }
    }
    
    public func searchSurfaceFile(_ searchText: String, folderPath: String) -> [FileModel] {
        let files = getAllFileWithPath(folderPath)
        return files.filter { $0.name.contains(searchText) }
    }
    
    public func searchDeepFile(_ searchText: String, folderPath: String) -> [FileModel] {
        let files = getAllFileWithPath(folderPath)
        var result: [FileModel] = []
        
        for file in files {
            if file.name.contains(searchText) {
                if file.isDir {
                    result.append(contentsOf: searchDeepFile(searchText, folderPath: file.filePath))
                }
                result.append(file)
            }
        }
        return result
    }
    
    public func readDataFromFilePath(_ filePath: String) -> Data? {
        guard let fileHandle = FileHandle(forReadingAtPath: filePath) else {
            return nil
        }
        let data = fileHandle.readDataToEndOfFile()
        fileHandle.closeFile()
        return data
    }
    
    public func seriesWriteContent(_ contentData: Data, intoHandleFile filePath: String) {
        guard let fileHandle = FileHandle(forUpdatingAtPath: filePath) else {
            return
        }
        fileHandle.seekToEndOfFile()
        fileHandle.write(contentData)
        fileHandle.closeFile()
    }
}

