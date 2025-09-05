//
//  FileModel.swift
//  FileBrowse
//
//  Created by Cityu on 2025/4/25.
//

import Foundation

public class FileModel {
    // MARK: - Properties
    public var filePath: String = ""
    public var fileUrl: String = ""
    public var name: String = ""
    public var fileSize: String = ""
    public var fileSizefloat: Float = 0.0
    public var modTime: String = ""
    public var creatTime: String = ""
    public var fileType: FileExtensionType = .unknown
    public var fileExtension: FileExtension = .unknown
    public var attributes: [FileAttributeKey: Any] = [:]
    public var dirConf: FileDirConf?
    
    public var isDir: Bool {
        return fileExtension == .directory
    }
    
    private let fileManager = FileManager.default
    
    
    public init(filePath: String) {
        self.filePath = filePath
        setupFileInfo()
    }
    
    // MARK: - Private Methods
    private func setupFileInfo() {
        name = (filePath as NSString).lastPathComponent
        fileType = .unknown
        fileExtension = .unknown
        
        var isDirectory: ObjCBool = false
        let exists = fileManager.fileExists(atPath: filePath, isDirectory: &isDirectory)
        
        if exists && isDirectory.boolValue {
            fileType = .directory
            fileExtension = .directory
            // 加载目录配置
            dirConf = FileDirConf.loadFromPath(filePath)
            if dirConf == nil {
                dirConf = FileDirConf()
                dirConf?.sortMode = .byName
                dirConf?.saveToPath(filePath)
            }
        } else {
            fileExtension = judgeExtensionFromContent(filePath)
            fileType = FileExtensionType(fileExtension)
        }
        
        do {
            attributes = try fileManager.attributesOfItem(atPath: filePath)
            
            // 修改时间
            if let fileModDate = attributes[.modificationDate] as? Date {
                let dateFormatter = DateFormatter()
                dateFormatter.dateFormat = "MM-dd HH:mm:ss"
                modTime = dateFormatter.string(from: fileModDate)
            }
            
            // 创建时间
            if let fileCreateDate = attributes[.creationDate] as? Date {
                let dateFormatter = DateFormatter()
                dateFormatter.dateFormat = "MM-dd HH:mm:ss"
                creatTime = dateFormatter.string(from: fileCreateDate)
            }
            
            // 计算大小
            fileSizefloat = calculateSize()
            
            // 大小的字符表示
            if fileSizefloat > 0 {
                let sizeString = String(format: "%.0f", fileSizefloat)
                if sizeString.count <= 3 {
                    fileSize = String(format: "%.1f B", fileSizefloat)
                } else if sizeString.count > 3 && sizeString.count < 7 {
                    fileSize = String(format: "%.1f KB", fileSizefloat / 1000.0)
                } else {
                    fileSize = String(format: "%.1f M", fileSizefloat / (1000.0 * 1000))
                }
            } else {
                fileSize = "0 B"
            }
        } catch {
            print("Error getting file attributes: \(error)")
        }
    }
    
    private func calculateSize() -> Float {
        if fileType != .unknown { // 文件
            if let fileSize = attributes[.size] as? NSNumber {
                return fileSize.floatValue
            }
        } else { // 文件夹
            do {
                let subpaths = try fileManager.subpathsOfDirectory(atPath: filePath)
                var totalByteSize: Float = 0
                for subpath in subpaths {
                    let fullSubPath = (filePath as NSString).appendingPathComponent(subpath)
                    var isDir: ObjCBool = false
                    if fileManager.fileExists(atPath: fullSubPath, isDirectory: &isDir) && !isDir.boolValue {
                        do {
                            let attr = try fileManager.attributesOfItem(atPath: fullSubPath)
                            if let size = attr[.size] as? NSNumber {
                                totalByteSize += size.floatValue
                            }
                        } catch {
                            // 忽略单个文件的错误
                        }
                    }
                }
                return totalByteSize
            } catch {
                return 0
            }
        }
        return 0
    }
    
    // MARK: - Public Methods
    public func fileExtensionString() -> String {
        return fileExtension.rawValue
    }
    
    public func fileModelDesc() -> String {
        let type = FileExtensionType(fileExtension)
        let typeDesc: String
        
        switch type {
        case .directory: typeDesc = "文件夹"
        case .image: typeDesc = "图片"
        case .video: typeDesc = "视频"
        case .audio: typeDesc = "音频"
        case .plainText: typeDesc = "文本"
        case .formattedText: typeDesc = "文档"
        case .archive: typeDesc = "压缩包"
        case .font: typeDesc = "字体"
        case .package: typeDesc = "软件包"
        case .database: typeDesc = "数据库"
        case .executable: typeDesc = "可执行文件"
        case .sourceCode: typeDesc = "源代码"
        case .config: typeDesc = "配置文件"
        default: typeDesc = "未知类型"
        }
        
        return "\(typeDesc): \(creatTime) \(fileSize)"
    }
}
