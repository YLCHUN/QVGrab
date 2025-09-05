//
//  M3U8TSDownloader.swift
//  QVGrab
//
//  Created by Cityu on 2025/4/3.
//

import Foundation
import UIKit
import CommonCrypto
import TSFdn

/// 移动文件
/// - Parameters:
///   - sourceFile: 源文件路径
///   - destinationPath: 目标路径
///   - error: 错误信息输出参数
/// - Returns: 是否成功

@discardableResult
private func moveFile(_ sourceFile: String, toPath destinationPath: String, err: inout Error?) -> Bool {
    // 确保源文件存在
    guard FileManager.default.fileExists(atPath: sourceFile) else {
        err = NSError(domain: NSCocoaErrorDomain, code: NSFileNoSuchFileError, userInfo: [NSLocalizedDescriptionKey: "Source file does not exist: \(sourceFile)"])
        return false
    }
    
    let sourceURL = URL(fileURLWithPath: sourceFile)
    let destinationURL = URL(fileURLWithPath: destinationPath)
    
    // 确保目标目录存在
    let directoryURL = destinationURL.deletingLastPathComponent()
    if !FileManager.default.fileExists(atPath: directoryURL.path) {
        do {
            try FileManager.default.createDirectory(at: directoryURL, withIntermediateDirectories: true, attributes: nil)
        } catch {
            err = error
            return false
        }
    } else {
        // 如果目标文件存在，先删除它
        if FileManager.default.fileExists(atPath: destinationPath) {
            do {
                try FileManager.default.removeItem(atPath: destinationPath)
            } catch {
                err = error
                return false
            }
        }
    }
    
    // 移动文件
    do {
        try FileManager.default.moveItem(at: sourceURL, to: destinationURL)
    } catch {
        err = error
        return false
    }
    
    return true
}

/// 删除文件
/// - Parameter file: 文件路径
/// - Returns: 错误信息
@discardableResult
private func removeFile(_ file: String) -> Error? {
    do {
        if FileManager.default.fileExists(atPath: file) {
            try FileManager.default.removeItem(atPath: file)
        }
    } catch {
        return error
    }
    return nil
}


/// M3U8 TS下载器
class M3U8TSDownloader {
    
    // MARK: - Properties
    
    /// M3U8模型
    private var m3u8Model: M3U8?
    
    /// 进度回调
    private var progressBlock: ((Float) -> Void)?
    
    /// 完成回调
    private var completionBlock: ((M3U8?, [String: String]?, Error?) -> Void)?
    
    /// 密钥下载器
    private var keyDownloader: M3U8DownloaderProtocol?
    
    /// 当前TS下载器
    private var currentTsDownloader: M3U8DownloaderProtocol?
    
    /// TS文件路径映射
    private var tsFilePaths: [String: String] = [:]
    
    /// 是否正在下载
    private var isDownloading: Bool = false
    
    /// 是否已完成
    private var isCompleted: Bool = false
    
    /// 解密器字典
    private var decryptors: [String: TSDecryptor] = [:]
    
    /// 总下载速度
    private var totalSpeed: UInt = 0
    
    /// 请求头
    var headers: [String: String] = [:]
    
    /// 下载目录
    var dir: String?
    
    // MARK: - Public Properties
    
    /// M3U8模型
    var model: M3U8? {
        return m3u8Model
    }
    
    /// 当前下载速度
    var speed: UInt {
        var totalSpeed: UInt = 0
        
        // 获取密钥下载器的速度
        if let keyDownloader = keyDownloader {
            totalSpeed += keyDownloader.speed
        }
        
        // 获取当前 TS 下载器的速度
        if let currentTsDownloader = currentTsDownloader {
            totalSpeed += currentTsDownloader.speed
        }
        
        if keyDownloader == nil && currentTsDownloader == nil {
            totalSpeed = self.totalSpeed
        } else {
            self.totalSpeed = totalSpeed
        }
        
        return totalSpeed
    }
    
    /// 下载URL
    var url: String {
        return m3u8Model?.segments.first?.url ?? ""
    }
    
    // MARK: - Initialization
    

    /// 创建下载器实例
    /// - Parameters:
    ///   - model: M3U8模型
    ///   - progress: 进度回调
    ///   - completion: 完成回调
    /// - Returns: 下载器实例
    static func downloaderWithModel(_ model: M3U8, progress: @escaping (Float) -> Void, completion: @escaping (M3U8?, [String: String]?, Error?) -> Void) -> M3U8TSDownloader {
        let downloader = M3U8TSDownloader()
        downloader.m3u8Model = model
        downloader.progressBlock = progress
        downloader.completionBlock = completion
        downloader.tsFilePaths = [:]
        downloader.isDownloading = false
        downloader.isCompleted = false
        return downloader
    }
    
    // MARK: - Public Methods
    
    /// 开始下载
    func start() {
        guard !isDownloading else { return }
        
        resetState()
        
        isDownloading = true
        isCompleted = false
        
        downloadTsFiles()
    }
    
    /// 停止下载
    func stop() {
        isDownloading = false
        isCompleted = false
        
        resetState()
    }
    
    // MARK: - Private Methods
    
    /// 获取缓存目录
    /// - Returns: 缓存目录路径
    private func getCacheDir() -> String? {
        // 获取文档目录
        guard let rootPath = NSSearchPathForDirectoriesInDomains(.cachesDirectory, .userDomainMask, true).first else {
            return nil
        }
        
        // 创建基础目录
        let dir = rootPath + "/" + "TSDownloader"
        do {
            try FileManager.default.createDirectory(atPath: dir, withIntermediateDirectories: true, attributes: nil)
        } catch {
            return nil
        }
        
        // 创建m3u8特定目录
        let m3u8Name = url.hashId
        let tsDirectory = dir + "/" + m3u8Name
        do {
            try FileManager.default.createDirectory(atPath: tsDirectory, withIntermediateDirectories: true, attributes: nil)
        } catch {
            return nil
        }
        
        return tsDirectory
    }
    
    /// 获取下载目录
    /// - Returns: 下载目录路径
    private func getDir() -> String {
        if dir == nil {
            let rootPath = NSSearchPathForDirectoriesInDomains(.cachesDirectory, .userDomainMask, true).first!
            let dir = rootPath + "/" + "TSDownloader"
            try? FileManager.default.createDirectory(atPath: dir, withIntermediateDirectories: true, attributes: nil)
            self.dir = dir
        }
        return dir!
    }
    
    /// 获取TS文件路径
    /// - Parameter index: 索引
    /// - Returns: 文件路径
    private func tsFilePath(_ index: Int) -> String {
        let tsFileName = String(format: "%08d.ts", index)
        return getDir() + "/" + tsFileName
    }
    
    /// 移除解密器
    /// - Parameter encryption: 加密信息
    private func removeDecryptor(_ encryption: TSEncryption?) {
        guard let encryption = encryption else { return }
        decryptors[encryption.eid] = nil
        let keyFilePath = keyFilePath(encryption)
        _ = removeFile(keyFilePath)
    }
    
    func createDownloader(url:String, filePath:String, progress: @escaping (Float) -> Void, machine: ((String) -> (String?, Error?))? = nil, completion: @escaping (Error?) -> Void) -> M3U8DownloaderProtocol? {
        if FileManager.default.fileExists(atPath: filePath) {
            progress(1)
            completion(nil)
            return nil
        }
        let downloader = M3U8Provider.downloader(url: url, headers: headers(url), progress: progress) { file, error in
            if let error = error {
                completion(error)
                return
            }
            guard let file = file else {
                let error = NSError(domain: "TSDownloaderErrorDomain", code: -1, userInfo: [NSLocalizedDescriptionKey: "Download file not found"])
                completion(error)
                return
            }
            
            var err:Error?
            if let machine = machine {
                let machined = machine(file)
                
                if let error = machined.1 {
                    completion(error)
                    return
                }
                guard let file = machined.0 else {
                    let error = NSError(domain: "TSDownloaderErrorDomain", code: -1, userInfo: [NSLocalizedDescriptionKey: "Download machined file not found"])
                    completion(error)
                    return
                }
                moveFile(file, toPath: filePath, err: &err)
            }
            else {
                moveFile(file, toPath: filePath, err: &err)
            }
            completion(err)
        }
        return downloader
    }
    
    /// 下载解密器
    /// - Parameters:
    ///   - encryption: 加密信息
    ///   - progress: 进度回调
    ///   - completion: 完成回调
    private func downloadDecryptor(_ encryption: TSEncryption?, progress: @escaping (Float) -> Void, completion: @escaping (TSDecryptor?, Error?) -> Void) {
        guard let encryption = encryption, let keyUrl = encryption.key else {
            progress(1.0)
            completion(nil, nil)
            return
        }
        
        if let decryptor = decryptors[encryption.eid] {
            progress(1.0)
            completion(decryptor, nil)
            return
        }
        let keyFilePath = keyFilePath(encryption)

        keyDownloader = createDownloader(url: keyUrl, filePath: keyFilePath, progress: progress) { [weak self] error in
            guard let self = self else { return }
            self.keyDownloader = nil
            
            if let error = error {
                completion(nil, error)
                return
            }
            
            guard let keyData = loadFileData(keyFilePath) else {
                let error = NSError(domain: "TSDownloaderErrorDomain", code: -1, userInfo: [NSLocalizedDescriptionKey: "Download decryptor key error"])
                completion(nil, error)
                return
            }
            
            let ivData = TSDecryptor.iv2Data(iv: encryption.iv)
            let decryptor = TSDecryptor(key: keyData, iv: ivData, method: encryption.method)
            decryptors[encryption.eid] = decryptor
            completion(decryptor, nil)
        }
        keyDownloader?.start()
    }
    
    /// 下载TS文件
    /// - Parameters:
    ///   - ts: TS对象
    ///   - tryAgain: 是否重试
    ///   - progress: 进度回调
    ///   - completion: 完成回调
    private func downloadTs(_ ts: TS, tryAgain: Bool, progress: @escaping (Float) -> Void, completion: @escaping (String?, Error?) -> Void) {
        let tsPath = tsFilePath(ts.index)
        
        // 如果文件已存在，直接使用
        if FileManager.default.fileExists(atPath: tsPath) {
            // 文件已存在，进度为1.0
            progress(1.0)
            completion(tsPath, nil)
            return
        }
        
        downloadDecryptor(ts.encryption, progress: { p in
            progress(p * 0.2)
        }) { [weak self] decryptor, error in
            guard let self = self else { return }
            
            if let error = error {
                completion(nil, error)
                return
            }
            
            var tryAgain = tryAgain
            // 下载TS文件
            self.currentTsDownloader = createDownloader(url: ts.url, filePath: tsPath) { p in
                progress(p * 0.8 + 0.2)
            } machine: { file in
                guard let decryptor = decryptor else {// 不需要解密
                    return (file, nil)
                }
                var error: Error?
                guard let file = decryptor.decryptIfNeed(file, error: &error) else {
                    if decryptor.dcs == 0 {
                        self.removeDecryptor(ts.encryption)
                    }
                    removeFile(file)
                    tryAgain = !tryAgain// 揭秘失败，如果是重试的，不再重试，如果不是重试的重试一次
                    return (nil, error)
                }
                
                return (file, nil)
            } completion: { [weak self] error in
                guard let self = self else { return }
                self.currentTsDownloader = nil

                if let error = error  {
                    if tryAgain {
                        self.downloadTs(ts, tryAgain: true, progress: progress, completion: completion)
                    } else {
                        completion(nil, error)
                    }
                    return
                }
                completion(tsPath, nil)
            }
            self.currentTsDownloader?.start()
        }
    }
    
    /// 下载指定索引的TS文件
    /// - Parameters:
    ///   - index: 索引
    ///   - progress: 进度回调
    ///   - completion: 完成回调
    private func downloadTsWithIndex(_ index: Int, progress: @escaping (Float, Int) -> Void, completion: @escaping (Int, Bool, Error?) -> Void) {
        guard let segments = m3u8Model?.segments, index < segments.count else {
            completion(index, true, nil)
            return
        }
        
        // 检查是否已停止
        guard isDownloading else {
            completion(index, false, NSError(domain: "TSDownloaderErrorDomain", code: -1, userInfo: [NSLocalizedDescriptionKey: "Download stopped"]))
            return
        }
        
        let ts = segments[index]
        downloadTs(ts, tryAgain: false, progress: { p in
            progress(p, index)
        }) { [weak self] path, error in
            guard let self = self else { return }
            
            guard let path = path else {
                completion(index, index >= segments.count, error)
                return
            }
            self.tsFilePaths[ts.url] = path
            
            if self.isDownloading {
                DispatchQueue.main.async {
                    self.downloadTsWithIndex(index + 1, progress: progress, completion: completion)
                }
            }
        }
    }
    
    /// 获取密钥文件路径
    /// - Parameter encryption: 加密信息
    /// - Returns: 文件路径
    private func keyFilePath(_ encryption: TSEncryption) -> String {
        return getDir() + "/" + "key_\(encryption.eid).data"
    }
    
    private func loadFileData(_ filePath: String)->Data? {
        if FileManager.default.fileExists(atPath: filePath) {
            let keyData = try? Data(contentsOf: URL(fileURLWithPath: filePath))
            return keyData
        }
        return nil
    }
    
    /// 下载TS文件
    private func downloadTsFiles() {
        guard let segments = m3u8Model?.segments, !segments.isEmpty else { return }
        
        let p: Float = 1.0
        let pUnit = p / Float(segments.count)
        
        downloadTsWithIndex(0, progress: { progress, index in
            let currentProgress = (Float(index) + progress) * pUnit
            self.handleProgress(currentProgress)
        }) { [weak self] index, end, error in
            guard let self = self else { return }
            
            if let error = error {
                self.handleCompletion(error)
            } else if end {
                self.handleCompletion(nil)
            }
        }
    }
    
    /// 处理进度更新
    /// - Parameter progress: 进度值
    private func handleProgress(_ progress: Float) {
        progressBlock?(progress)
    }
    
    /// 处理完成回调
    /// - Parameter error: 错误信息
    private func handleCompletion(_ error: Error?) {
        // 设置状态
        isDownloading = false
        isCompleted = true
        totalSpeed = 0
        
        // 调用完成回调
        completionBlock?(m3u8Model, tsFilePaths, error)
    }
    
  
    
    /// 重置状态
    private func resetState() {
        totalSpeed = 0
        keyDownloader?.stop()
        keyDownloader = nil
        
        currentTsDownloader?.stop()
        currentTsDownloader = nil
        
        tsFilePaths.removeAll()
        decryptors.removeAll()
    }
    
    /// 获取请求头
    /// - Parameter url: URL
    /// - Returns: 请求头字典
    private func headers(_ url: String) -> [String: String] {
        guard let URL = URL(string: url) else {
            return headers
        }
        
        var headers = self.headers
        headers["Host"] = URL.host
        headers["Referer"] = url.components(separatedBy: "?").first
        return headers
    }
}
