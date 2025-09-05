//
//  VideoDownloader.swift
//  QVGrab
//
//  Created by Cityu on 2025/4/27.
//

import Foundation

/// 下载状态枚举
enum M3U8DownloadState: Int {
    case idle = 0
    case downloading = 1
    case paused = 2
    case merging = 3
    case completed = 4
    case failed = 5
}

/// 视频下载器
public class VideoDownloader: M3U8DownloaderProtocol {
    
    
    // MARK: - Properties
    
    /// M3U8下载器
    private var m3u8Downloader: M3U8Downloader?
    
    /// TS下载器
    private var tsDownloader: M3U8TSDownloader?
    
    /// 合并器
    private var merger: M3U8TSMerger?
    
    /// 下载URL
    private var downloadUrl: String = ""
    
    /// 当前进度
    private var currentProgress: Float = 0
    
    /// 进度回调
    private var progressBlock: ((Float) -> Void)?
    
    /// 完成回调
    private var completionBlock: ((String?, Error?) -> Void)?
    
    /// 下载状态
    private var state: M3U8DownloadState = .idle
    
    /// 最后的错误
    private var lastError: Error?
    
    /// 会话ID
    private var sessionId: String = ""
    
    /// 请求头
    public var headers: [String: String] = [:]
    
    // MARK: - Public Properties
    
    /// 下载URL
    public var url: String {
        return downloadUrl
    }
    
    /// 当前进度
    public var progress: Float {
        return currentProgress
    }
    
    /// 是否正在下载
    public var isDownloading: Bool {
        return state == .downloading || state == .merging
    }
    
    /// 当前下载速度
    public var speed: UInt {
        var totalSpeed: UInt = 0
        
        // 获取 m3u8 下载器的速度
        if let m3u8Downloader = m3u8Downloader {
            totalSpeed += m3u8Downloader.speed
        }
        
        // 获取 ts 下载器的速度
        if let tsDownloader = tsDownloader {
            totalSpeed += tsDownloader.speed
        }
        
        return totalSpeed
    }
    
    /// 创建下载器实例
    /// - Parameters:
    ///   - url: 下载URL
    ///   - progress: 进度回调
    ///   - completion: 完成回调
    /// - Returns: 下载器实例
    public init?(_ url: String, progress: @escaping (Float) -> Void, completion: @escaping (String?, Error?) -> Void) {
        guard !url.isEmpty else {
            let error = NSError(domain: "M3U8VDownloader", code: -1, userInfo: [NSLocalizedDescriptionKey: "下载地址不能为空"])
            completion(nil, error)
            return
        }
        state = .idle
        headers = [:]
        sessionId = getSessionId()
        downloadUrl = url
        progressBlock = progress
        completionBlock = completion
    }
    deinit {
        stop()
        m3u8Downloader = nil
        tsDownloader = nil
        merger = nil
    }
    
    /// 获取会话ID
    /// - Returns: 会话ID
    private func getSessionId() -> String {
        let uuid = UUID()
        return uuid.uuidString
    }
    
    /// 获取请求头
    /// - Returns: 请求头字典
    private func getHeaders() -> [String: String] {
        var headers = self.headers
        headers["x-playback-session-id"] = sessionId
        return headers
    }
    
    // MARK: - M3U8DownloaderProtocol
    /// 开始下载（支持强制下载）
    /// - Parameter forceDownload: 是否强制下载
    public func start(_ forceDownload: Bool = false) {
        // 检查当前状态
        if state == .downloading || state == .merging {
            return
        }
        
        // 重置状态
        reset()
        
        // 检查文件是否存在
        if !forceDownload && checkTargetFileExists() {
            print("文件已存在，直接返回路径")
            let path = getTargetFilePath()
            state = .completed
            if let completionBlock = completionBlock {
                DispatchQueue.main.async {
                    completionBlock(path, nil)
                }
            }
            return
        }
        
        if forceDownload {
            cleanupTemporaryFiles()
        }
        
        // 开始下载
        startDownloadProcess()
    }
    
    public func stop() {
        if state == .idle || state == .completed { return }
        
        m3u8Downloader?.stop()
        tsDownloader?.stop()
        merger?.stop()
        reset()
    }
    
    /// 清理缓存
    public func clearCache() {
        cleanupTemporaryFiles()
    }
    
    // MARK: - Private Methods
    
    /// 设置状态
    /// - Parameter newState: 新状态
    private func setState(_ newState: M3U8DownloadState) {
        guard state != newState else { return }
        
        state = newState
        if state == .failed {
            // 清理临时文件
        } else if state == .completed {
            currentProgress = 1.0
            if let progressBlock = progressBlock {
                DispatchQueue.main.async {
                    progressBlock(1.0)
                }
            }
        }
    }
    
    /// 更新进度
    /// - Parameter progress: 进度值
    private func updateProgress(_ progress: Float) {
        guard state == .downloading || state == .merging else { return }
        
        currentProgress = progress
        if let progressBlock = progressBlock {
            DispatchQueue.main.async {
                progressBlock(progress)
            }
        }
    }
    
    /// 开始下载过程
    private func startDownloadProcess() {
        startM3U8DownloadWithUrl(downloadUrl)
    }
    
    /// 开始M3U8下载
    /// - Parameter url: 下载URL
    private func startM3U8DownloadWithUrl(_ url: String) {
        setState(.downloading)
        
        m3u8Downloader = M3U8Downloader(url, progress: { [weak self] progress in
            self?.updateProgress(progress * 0.01)
        }) { [weak self] m3u8, url, file, error in
            guard let self = self else { return }
            
            if let error = error {
                self.handleError(error)
                return
            }
            
            guard let m3u8 = m3u8 else {
                self.handleError(NSError(domain: "M3U8VDownloader", code: -1, userInfo: [NSLocalizedDescriptionKey: "M3U8解析失败"]))
                return
            }
            
            let cleanM3u8 = m3u8.removeAdvertisements()
            // M3U8下载完成后，开始下载TS文件
            self.startTsDownloadWithM3U8(cleanM3u8)
        }
        
        m3u8Downloader?.dir = getCacheDir()
        // 设置请求头
        m3u8Downloader?.headers = getHeaders()
        
        m3u8Downloader?.start()
    }
    
    /// 开始TS下载
    /// - Parameter m3u8: M3U8模型
    private func startTsDownloadWithM3U8(_ m3u8: M3U8) {
        tsDownloader = M3U8TSDownloader.downloaderWithModel(m3u8, progress: { [unowned self] progress in
            self.updateProgress(0.01 + progress * 0.94)
        }) { [unowned self] model, tsFiles, error in
            
            if let error = error {
                self.handleError(error)
                return
            }
            
            guard let model = model, let tsFiles = tsFiles else {
                self.handleError(NSError(domain: "M3U8VDownloader", code: -1, userInfo: [NSLocalizedDescriptionKey: "TS文件下载失败"]))
                return
            }
            
            // 开始合并
            self.startMergingWithM3U8(model, tsFiles: tsFiles)
        }
        
        tsDownloader?.dir = getCacheDir()
        // 设置请求头
        tsDownloader?.headers = getHeaders()
        
        tsDownloader?.start()
    }
    
    /// 开始合并
    /// - Parameters:
    ///   - m3u8: M3U8模型
    ///   - tsFiles: TS文件映射
    private func startMergingWithM3U8(_ m3u8: M3U8, tsFiles: [String: String]) {
        setState(.merging)
        
        // 准备TS文件路径数组
        var tsFilePaths: [String] = []
        for ts in m3u8.segments {
            if let tsPath = tsFiles[ts.url] {
                tsFilePaths.append(tsPath)
            }
        }
        
        merger = M3U8TSMergerP(tsFilePaths) { [unowned self] p in
            self.updateProgress(0.95 + p * 0.05)
        } completion: { [unowned self] file, error  in
            if let error = error {
                self.handleError(error)
                return
            }
            
            self.handleMergeCompletionWithFile(file)
        }
        merger?.start()
    }
    
    /// 处理错误
    /// - Parameter error: 错误信息
    private func handleError(_ error: Error) {
        lastError = error
        setState(.failed)
        
        if let completionBlock = completionBlock {
            DispatchQueue.main.async {
                completionBlock(nil, error)
            }
        }
    }
    
    /// 重置状态
    private func reset() {
        setState(.idle)
        currentProgress = 0
        lastError = nil
    }
    
    /// 处理合并完成
    /// - Parameter file: 合并后的文件路径
    private func handleMergeCompletionWithFile(_ file: String?) {
        guard let file = file else {
            handleError(NSError(domain: "M3U8VDownloader", code: -1, userInfo: [NSLocalizedDescriptionKey: "合并失败"]))
            return
        }
        
        let targetPath = getTargetFilePath()
        
        // 确保目标目录存在
        let targetDir = (targetPath as NSString).deletingLastPathComponent
        do {
            try FileManager.default.createDirectory(atPath: targetDir, withIntermediateDirectories: true, attributes: nil)
        } catch {
            handleError(error)
            return
        }
        
        // 移动文件到最终位置
        if FileManager.default.fileExists(atPath: targetPath) {
            try? FileManager.default.removeItem(atPath: targetPath)
        }
        
        do {
            try FileManager.default.moveItem(atPath: file, toPath: targetPath)
        } catch {
            handleError(error)
            return
        }
        
        // 清理并完成
        setState(.completed)
        
        if let completionBlock = completionBlock {
            DispatchQueue.main.async {
                completionBlock(targetPath, nil)
            }
        }
    }
    
    /// 获取缓存目录
    /// - Returns: 缓存目录路径
    private func getCacheDir() -> String? {
        // 获取文档目录
        guard let rootPath = NSSearchPathForDirectoriesInDomains(.cachesDirectory, .userDomainMask, true).first else {
            return nil
        }
        
        // 创建基础目录
        let dir = rootPath + "/" + "M3U8D"
        do {
            try FileManager.default.createDirectory(atPath: dir, withIntermediateDirectories: true, attributes: nil)
        } catch {
            return nil
        }
        
        // 创建m3u8特定目录
        let dirName = url.hashId
        let finalDir = dir + "/" + dirName
        do {
            try FileManager.default.createDirectory(atPath: finalDir, withIntermediateDirectories: true, attributes: nil)
        } catch {
            return nil
        }
        
        return finalDir
    }
    
    /// 获取目标文件路径
    /// - Returns: 目标文件路径
    private func getTargetFilePath() -> String {
        return (getCacheDir() ?? "") + "/video.mp4"
    }
    
    /// 检查目标文件是否存在
    /// - Returns: 文件是否存在
    private func checkTargetFileExists() -> Bool {
        let targetPath = getTargetFilePath()
        let exists = FileManager.default.fileExists(atPath: targetPath)
        
        if exists {
            // 检查文件是否可读且大小大于0
            do {
                let attributes = try FileManager.default.attributesOfItem(atPath: targetPath)
                if let fileSize = attributes[.size] as? Int64, fileSize > 0 {
                    return true
                }
            } catch {
                // 如果文件存在但大小为0或不可读，删除它
                try? FileManager.default.removeItem(atPath: targetPath)
            }
        }
        
        return false
    }
    
    /// 清理临时文件
    private func cleanupTemporaryFiles() {
        // 清理M3U8下载器的缓存
        m3u8Downloader = nil
        
        // 清理TS下载器的缓存
        tsDownloader = nil
        
        // 清理合并器的缓存
        merger?.clearCache()
        merger = nil
        
        if let cacheDir = getCacheDir() {
            try? FileManager.default.removeItem(atPath: cacheDir)
        }
    }
}
