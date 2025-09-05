//
//  AFDownloader.swift
//  iOS
//
//  Created by Cityu on 2025/6/6.
//  Copyright © 2025 Cityu. All rights reserved.
//

import Foundation
import AFNetworking

class AFDownloader: DownloaderProtocol {
    
    var headers: [String: String]? = [:]
    
    private var manager: AFURLSessionManager!
    private var downloadTask: URLSessionDownloadTask?
    private var url: String
    private var progressBlock: ((Float) -> Void)?
    private var completionBlock: ((String?, Error?) -> Void)?
    private var isDownloadingFlag = false
    private var _resumeDataPath: String?
    private var securityPolicy: AFSecurityPolicy!
    private var retryCount = 0
    private var maxRetryCount = 3
    private var speedMeter: SpeedMeter!
    
    required init(_ url: String, progress: @escaping (Float) -> Void, completion: @escaping (String?, Error?) -> Void) {
        self.url = url
        self.progressBlock = progress
        self.completionBlock = completion
        
        let config = URLSessionConfiguration.default
        manager = AFURLSessionManager(sessionConfiguration: config)
        isDownloadingFlag = false
        speedMeter = SpeedMeter()
        headers = [:]
        retryCount = 0
        maxRetryCount = 3
        
        // 最宽松 https 策略
        let securityPolicy = AFSecurityPolicy(pinningMode: .none)
        securityPolicy.allowInvalidCertificates = true
        securityPolicy.validatesDomainName = false
        self.securityPolicy = securityPolicy
    }

    func clearCache() {
        // 删除断点续传数据
        clearResumeData()
        let cacheFilePath = cacheFilePath()
        try? FileManager.default.removeItem(atPath: cacheFilePath)
    }
    

    
    private func resumeDataPath() -> String {
        if _resumeDataPath == nil && !url.isEmpty {
            let cacheDir = NSSearchPathForDirectoriesInDomains(.cachesDirectory, .userDomainMask, true).first!
            let fileName = "downloader_\(url.hashValue).resume"
            _resumeDataPath = cacheDir + "/" + fileName
        }
        return _resumeDataPath ?? ""
    }
    
    private func loadResumeData() -> Data? {
        let path = resumeDataPath()
        if FileManager.default.fileExists(atPath: path) {
            return try? Data(contentsOf: URL(fileURLWithPath: path))
        }
        return nil
    }
    
    private func saveResumeData(_ data: Data) {
        guard !data.isEmpty else { return }
        try? data.write(to: URL(fileURLWithPath: resumeDataPath()))
    }
    
    private func clearResumeData() {
        let path = resumeDataPath()
        if FileManager.default.fileExists(atPath: path) {
            try? FileManager.default.removeItem(atPath: path)
        }
    }
    
    func start() {
        guard !isDownloadingFlag && !url.isEmpty else { return }

        isDownloadingFlag = true
        speedMeter.reset()
        retryCount = 0
        startDownload()
    }

    
    private func startDownload() {
        // 清理旧的 downloadTask
        if let oldTask = downloadTask {
            oldTask.cancel()
            downloadTask = nil
        }
        
        manager.securityPolicy = securityPolicy
        guard let downloadURL = URL(string: url) else { 
            // URL 无效时设置错误状态
            isDownloadingFlag = false
            completionBlock?(nil, NSError(domain: "AFDownloader", code: -1, userInfo: [NSLocalizedDescriptionKey: "Invalid URL"]))
            return 
        }
        
        let request = NSMutableURLRequest(url: downloadURL)
        // 设置 headers
        if let headers = headers {
            for (key, value) in headers {
                request.setValue(value, forHTTPHeaderField: key)
            }
        }
        
        let resumeData = loadResumeData()
        if let resumeData = resumeData {
            downloadTask = manager.downloadTask(withResumeData: resumeData, progress: { [weak self] downloadProgress in
                self?.handlerProgress(downloadProgress)
            }, destination: { [weak self] targetPath, response in
                return self?.handlerDestination(targetPath, response: response) ?? targetPath
            }, completionHandler: { [weak self] response, filePath, error in
                self?.handlerCompletion(response: response, url: filePath, error: error)
            })
        } else {
            downloadTask = manager.downloadTask(with: request as URLRequest, progress: { [weak self] downloadProgress in
                self?.handlerProgress(downloadProgress)
            }, destination: { [weak self] targetPath, response in
                return self?.handlerDestination(targetPath, response: response) ?? targetPath
            }, completionHandler: { [weak self] response, filePath, error in
                self?.handlerCompletion(response: response, url: filePath, error: error)
            })
        }
        downloadTask?.resume()
    }
    
    private func handlerProgress(_ progress: Progress) {
        speedMeter.meterCompletedBytes(Double(progress.completedUnitCount))
        if let progressBlock = progressBlock {
            let p = Float(progress.fractionCompleted)
            progressBlock(p)
        }
    }
    
    private func handlerDestination(_ targetPath: URL, response: URLResponse) -> URL {
        return URL(fileURLWithPath: cacheFilePath())
    }
    
    private func cacheFilePath() -> String {
        let fileName = URL(string: url)?.lastPathComponent ?? ""
        let hashedFileName = "\(url.hashValue)_\(fileName)"
        let cacheDir = cacheDir()
        return cacheDir + "/" + hashedFileName
    }
    
    private func cacheDir() -> String {
        struct Static {
            static var cacheDir: String?
            static var onceToken: Int = 0
        }
        
        if Static.cacheDir == nil {
            let dir = NSSearchPathForDirectoriesInDomains(.cachesDirectory, .userDomainMask, true).first!
            Static.cacheDir = dir + "/" + "dCache"
            try? FileManager.default.createDirectory(atPath: Static.cacheDir!, withIntermediateDirectories: true, attributes: nil)
        }
        return Static.cacheDir!
    }
    
    private func handlerCompletion(response: URLResponse?, url: URL?, error: Error?) {
        DispatchQueue.main.async { [weak self] in
            guard let self = self else { return }
            
            // 清理当前的 downloadTask
            self.downloadTask = nil
            
            if let _ = error, self.retryCount < self.maxRetryCount {
                self.retryCount += 1
                DispatchQueue.main.asyncAfter(deadline: .now() + 1) { [weak self] in
                    self?.retryDownloadIfNeeded()
                }
                return
            }
            
            self.isDownloadingFlag = false
            self.clearResumeData()
            
            if let completionBlock = self.completionBlock {
                completionBlock(url?.path, error)
            }
        }
    }
    
    @objc private func retryDownloadIfNeeded() {
        // 确保状态正确后再重试，并且没有活跃的 task
        guard isDownloadingFlag && downloadTask == nil else { return }
        startDownload()
    }
    
    func stop() {
        // 无论状态如何，都要清理 downloadTask
        NSObject.cancelPreviousPerformRequests(withTarget: self)
        
        // 清理旧的 downloadTask
        let oldTask = downloadTask
        downloadTask = nil
        
        if let oldTask = oldTask {
            oldTask.cancel { [weak self] resumeData in
                if let resumeData = resumeData {
                    self?.saveResumeData(resumeData)
                }
                self?.isDownloadingFlag = false
            }
        } else {
            // 如果没有 task，直接设置状态
            isDownloadingFlag = false
        }
    }
    
    // MARK: - DownloaderProtocol
    
    var speed: UInt {
        return UInt(speedMeter.speed)
    }
    
    var isDownloading: Bool {
        return isDownloadingFlag
    }
}


import M3U8
extension AFDownloader : M3U8DownloaderProtocol {
    
}
