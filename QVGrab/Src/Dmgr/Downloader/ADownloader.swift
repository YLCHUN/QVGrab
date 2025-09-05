////
////  ADownloader.swift
////  QVGrab
////
////  Created by Cityu on 2025/1/27.
////  Copyright © 2025 Cityu. All rights reserved.
////
//
//import Foundation
//import Alamofire
//
//class ADownloader: DownloaderProtocol {
//    
//    // MARK: - Properties
//    
//    var headers: [String: String]? = [:]
//    
//    private var session: Session!
//    private var downloadRequest: DownloadRequest?
//    private var url: String = ""
//    private var progressBlock: ((Float) -> Void)?
//    private var completionBlock: ((String?, Error?) -> Void)?
//    private var isDownloadingFlag = false
//    private var _resumeDataPath: String?
//    private var retryCount = 0
//    private var maxRetryCount = 3
//    private var speedMeter: SpeedMeter!
//    
//    // MARK: - Initialization
//    
//    required init(_ url: String, progress: @escaping (Float) -> Void, completion: @escaping (String?, Error?) -> Void) {
//        self.url = url
//        self.progressBlock = progress
//        self.completionBlock = completion
//        
//        setupSession()
//        isDownloadingFlag = false
//        speedMeter = SpeedMeter()
//        headers = [:]
//        retryCount = 0
//        maxRetryCount = 3
//    }
//    
//    private func setupSession() {
//        let configuration = URLSessionConfiguration.default
//        configuration.timeoutIntervalForRequest = 30
//        configuration.timeoutIntervalForResource = 300
//        
//        // 创建服务器信任管理器，配置为允许所有主机
//        // 使用 DisabledTrustEvaluator 来跳过证书验证，适用于自签名证书或证书链问题
//        let serverTrustManager = ServerTrustManager(evaluators: [
//            "*": DisabledTrustEvaluator() // 允许所有主机，不生效
//        ])
//        
//        // 创建会话
//        session = Session(
//            configuration: configuration,
//            serverTrustManager: serverTrustManager
//        )
//    }
//    
//    // MARK: - Public Methods
//    
//    func clearCache() {
//        // 删除断点续传数据
//        clearResumeData()
//        let cacheFilePath = cacheFilePath()
//        try? FileManager.default.removeItem(atPath: cacheFilePath)
//    }
//    
//    // MARK: - DownloaderProtocol & M3U8DownloaderProtocol
//    
//    var speed: UInt {
//        return UInt(speedMeter.speed)
//    }
//    
//    var isDownloading: Bool {
//        return isDownloadingFlag
//    }
//    
//    func start() {
//        guard !isDownloadingFlag && !url.isEmpty else { return }
//        
//        isDownloadingFlag = true
//        speedMeter.reset()
//        retryCount = 0
//        startDownload()
//    }
//    
//    func stop() {
//        // 无论状态如何，都要清理 downloadRequest
//        NSObject.cancelPreviousPerformRequests(withTarget: self)
//        
//        // 清理旧的 downloadRequest
//        let oldRequest = downloadRequest
//        downloadRequest = nil
//        
//        if let oldRequest = oldRequest {
//            oldRequest.cancel { [weak self] resumeData in
//                if let resumeData = resumeData {
//                    self?.saveResumeData(resumeData)
//                }
//                self?.isDownloadingFlag = false
//            }
//        } else {
//            // 如果没有 request，直接设置状态
//            isDownloadingFlag = false
//        }
//    }
//    
//    // MARK: - Private Methods
//    
//    private func startDownload() {
//        // 清理旧的 downloadRequest
//        if let oldRequest = downloadRequest {
//            oldRequest.cancel()
//            downloadRequest = nil
//        }
//        
//        guard let downloadURL = URL(string: url) else {
//            // URL 无效时设置错误状态
//            isDownloadingFlag = false
//            completionBlock?(nil, NSError(domain: "ADownloader", code: -1, userInfo: [NSLocalizedDescriptionKey: "Invalid URL"]))
//            return
//        }
//        
//        let destination: DownloadRequest.Destination = { [weak self] _, _ in
//            let fileURL = URL(fileURLWithPath: self?.cacheFilePath() ?? "")
//            return (fileURL, [.removePreviousFile, .createIntermediateDirectories])
//        }
//        
//        // 检查是否有断点续传数据
//        let resumeData = loadResumeData()
//        
//        if let resumeData = resumeData {
//            // 使用断点续传
//            downloadRequest = session.download(resumingWith: resumeData, to: destination)
//        } else {
//            // 新建下载
//            downloadRequest = session.download(downloadURL, headers: HTTPHeaders(headers ?? [:]), to: destination)
//        }
//        
//        // 确保 downloadRequest 创建成功后再设置回调
//        guard let downloadRequest = downloadRequest else {
//            isDownloadingFlag = false
//            completionBlock?(nil, NSError(domain: "ADownloader", code: -2, userInfo: [NSLocalizedDescriptionKey: "Failed to create download request"]))
//            return
//        }
//        
//        // 设置进度回调
//        downloadRequest.downloadProgress { [weak self] progress in
//            self?.handleProgress(progress)
//        }
//        
//        // 设置完成回调
//        downloadRequest.response { [weak self] response in
//            self?.handleCompletion(response.request, response.response, response.error)
//        }
//    }
//    
//    private func handleProgress(_ progress: Progress) {
//        speedMeter.meterCompletedBytes(Double(progress.completedUnitCount))
//        if let progressBlock = progressBlock {
//            let p = Float(progress.fractionCompleted)
//            progressBlock(p)
//        }
//    }
//    
//    private func handleCompletion(_ request: URLRequest?, _ response: HTTPURLResponse?, _ error: Error?) {
//        DispatchQueue.main.async { [weak self] in
//            guard let self = self else { return }
//            
//            // 清理当前的 downloadRequest
//            self.downloadRequest = nil
//            
//            if let error = error, self.retryCount < self.maxRetryCount {
//                self.retryCount += 1
//                DispatchQueue.main.asyncAfter(deadline: .now() + 1){ [weak self] in
//                    self?.retryDownloadIfNeeded()
//                }
//                return
//            }
//            
//            self.isDownloadingFlag = false
//            self.clearResumeData()
//            
//            if let completionBlock = self.completionBlock {
//                let filePath = self.cacheFilePath()
//                let fileExists = FileManager.default.fileExists(atPath: filePath)
//                completionBlock(fileExists ? filePath : nil, error)
//            }
//        }
//    }
//    
//    @objc private func retryDownloadIfNeeded() {
//        // 确保状态正确后再重试，并且没有活跃的 request
//        guard isDownloadingFlag && downloadRequest == nil else { return }
//        startDownload()
//    }
//    
//    // MARK: - Resume Data Management
//    
//    private func resumeDataPath() -> String {
//        if _resumeDataPath == nil && !url.isEmpty {
//            let cacheDir = NSSearchPathForDirectoriesInDomains(.cachesDirectory, .userDomainMask, true).first!
//            let fileName = "alamofire_downloader_\(url.hashValue).resume"
//            _resumeDataPath = cacheDir + "/" + fileName
//        }
//        return _resumeDataPath ?? ""
//    }
//    
//    private func loadResumeData() -> Data? {
//        let path = resumeDataPath()
//        if FileManager.default.fileExists(atPath: path) {
//            return try? Data(contentsOf: URL(fileURLWithPath: path))
//        }
//        return nil
//    }
//    
//    private func saveResumeData(_ data: Data) {
//        guard !data.isEmpty else { return }
//        try? data.write(to: URL(fileURLWithPath: resumeDataPath()))
//    }
//    
//    private func clearResumeData() {
//        let path = resumeDataPath()
//        if FileManager.default.fileExists(atPath: path) {
//            try? FileManager.default.removeItem(atPath: path)
//        }
//    }
//    
//    // MARK: - Cache Management
//    
//    private func cacheFilePath() -> String {
//        let fileName = URL(string: url)?.lastPathComponent ?? ""
//        let hashedFileName = "\(url.hashValue)_\(fileName)"
//        let cacheDir = cacheDir()
//        return cacheDir + "/" + hashedFileName
//    }
//    
//    private func cacheDir() -> String {
//        struct Static {
//            static var cacheDir: String?
//            static var onceToken: Int = 0
//        }
//        
//        if Static.cacheDir == nil {
//            let dir = NSSearchPathForDirectoriesInDomains(.cachesDirectory, .userDomainMask, true).first!
//            Static.cacheDir = dir + "/" + "dCache"
//            try? FileManager.default.createDirectory(atPath: Static.cacheDir!, withIntermediateDirectories: true, attributes: nil)
//        }
//        return Static.cacheDir!
//    }
//}
//
//
//import M3U8
//extension ADownloader : M3U8DownloaderProtocol {
//    
//}
