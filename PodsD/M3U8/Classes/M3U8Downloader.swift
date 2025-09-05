//
//  M3U8Downloader.swift
//  QVGrab
//
//  Created by Cityu on 2025/4/30.
//

import Foundation
import UIKit

/// M3U8下载器
class M3U8Downloader {
    
    // MARK: - Properties
    
    /// 下载URL
    private var downloadUrl: String = ""
    
    /// 进度回调
    private var progressBlock: ((Float) -> Void)?
    
    /// 完成回调
    private var completionBlock: ((M3U8?, String, String?, Error?) -> Void)?
    
    /// M3U8下载器
    private var m3u8Downloader: M3U8DownloaderProtocol?
    
    /// 是否正在下载
    private var isDownloading: Bool = false
    
    /// 是否已完成
    private var isCompleted: Bool = false
    
    /// 请求头
    var headers: [String: String] = [:]
    
    /// 下载目录
    var dir: String?
    
    // MARK: - Public Properties
    
    /// 下载URL
    var url: String {
        return downloadUrl
    }
    
    /// 当前下载速度
    var speed: UInt {
        return m3u8Downloader?.speed ?? 0
    }
    
    /// 是否正在下载
    var isDownloadingState: Bool {
        return isDownloading
    }
    
    /// 是否已完成
    var isCompletedState: Bool {
        return isCompleted
    }
    
    // MARK: - Initialization
    
    /// 创建下载器实例
    /// - Parameters:
    ///   - url: 下载URL
    ///   - progress: 进度回调
    ///   - completion: 完成回调
    /// - Returns: 下载器实例
    init(_ url: String, progress: @escaping (Float) -> Void, completion: @escaping (M3U8?, String, String?, Error?) -> Void) {
        downloadUrl = url
        progressBlock = progress
        completionBlock = completion
        isDownloading = false
        isCompleted = false
    }
    // MARK: - Public Methods
    
    /// 开始下载
    func start() {
        guard !isDownloading else { return }
        
        resetState()
        
        isDownloading = true
        isCompleted = false
        
        downloadM3U8WithUrl(downloadUrl)
    }
    
    /// 停止下载
    func stop() {
        isDownloading = false
        isCompleted = false
        
        // 停止m3u8下载
        m3u8Downloader?.stop()
        
        resetState()
    }
    
    // MARK: - Private Methods
    
    /// 处理进度更新
    /// - Parameter progress: 进度值
    private func handlerProgress(_ progress: CGFloat) {
        progressBlock?(Float(progress))
    }
    
    /// 处理完成回调
    /// - Parameters:
    ///   - m3u8: M3U8对象
    ///   - url: URL
    ///   - file: 文件路径
    ///   - error: 错误信息
    private func handleCompletionWithM3U8(_ m3u8: M3U8?, url: String, file: String?, error: Error?) {
        // 设置状态
        isDownloading = false
        isCompleted = true
        
        // 调用完成回调
        completionBlock?(m3u8, url, file, error)
    }
    
    /// 重置状态
    private func resetState() {
        m3u8Downloader?.stop()
        m3u8Downloader = nil
    }
    
    /// 获取文件路径
    /// - Parameter url: URL
    /// - Returns: 文件路径
    private func filePath(_ url: String) -> String {
        let hashId = url.hashId
        let directory = dir ?? {
            let rootPath = NSSearchPathForDirectoriesInDomains(.cachesDirectory, .userDomainMask, true).first!
            let dir = rootPath + "/" + "M3U8Downloader"
            try? FileManager.default.createDirectory(atPath: dir, withIntermediateDirectories: true, attributes: nil)
            return dir
        }()
        return directory + "/" + "\(hashId).m3u8"
    }
    
    /// 加载M3U8模型
    /// - Parameter file: 文件路径
    /// - Returns: M3U8模型
    private func loadM3U8Model(_ file: String) -> M3U8? {
        guard FileManager.default.fileExists(atPath: file) else {
            return nil
        }
        
        do {
            let m3u8Content = try String(contentsOfFile: file, encoding: .utf8)
            return M3U8.m3u8(m3u8Content)
        } catch {
            return nil
        }
    }
    
    /// 获取流URL
    /// - Parameter m3u8Model: M3U8模型
    /// - Returns: 流URL
    private func streamUrl(_ m3u8Model: M3U8) -> String? {
        guard m3u8Model.isMultiVariant else {
            return nil
        }
        
        var highestQualityStream: VariantStream?
        var highestBandwidth: Int = 0
        
        for stream in m3u8Model.variantStreams ?? [] {
            if stream.streamAttributes.bandwidth > highestBandwidth {
                highestBandwidth = stream.streamAttributes.bandwidth
                highestQualityStream = stream
            }
        }
        
        return highestQualityStream?.url
    }
    
    /// 下载M3U8文件
    /// - Parameter url: 下载URL
    private func downloadM3U8WithUrl(_ url: String) {
        var loadUrl: String?
        let m3u8FilePath = filePath(url)
        var m3u8Model = loadM3U8Model(m3u8FilePath)
        
        if let model = m3u8Model {
            m3u8Model = model.convertRelativeURLsToAbsoluteURLs(url)
            if let streamUrl = streamUrl(m3u8Model!) {
                let newUrl = streamUrl
                let newM3u8FilePath = filePath(newUrl)
                if let model = loadM3U8Model(newM3u8FilePath) {
                    m3u8Model = model.convertRelativeURLsToAbsoluteURLs(newUrl)
                } else {
                    loadUrl = newUrl
                }
            }
        } else {
            loadUrl = url
        }
        
        if let loadUrl = loadUrl {
            m3u8Downloader = M3U8Provider.downloader(url: loadUrl, headers: headers(loadUrl), progress: { [weak self] progress in
                self?.handlerProgress(CGFloat(progress))
            }, completion: { [unowned self] file, error in
                
                if let file = file {
                    if FileManager.default.fileExists(atPath: m3u8FilePath) {
                        try? FileManager.default.removeItem(atPath: m3u8FilePath)
                    }
                    try? FileManager.default.moveItem(atPath: file, toPath: m3u8FilePath)
                    if error == nil {
                        self.downloadM3U8WithUrl(loadUrl)
                    }
                }
                if let error = error {
                    self.handleCompletionWithM3U8(nil, url: loadUrl, file: nil, error: error)
                }
            })
            m3u8Downloader?.start()
        } else {
            handlerProgress(1.0)
            handleCompletionWithM3U8(m3u8Model, url: url, file: m3u8FilePath, error: nil)
        }
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
