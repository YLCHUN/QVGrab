//
//  DownloadMgr.swift
//  iOS
//
//  Created by Cityu on 2025/7/21.
//  Copyright © 2025 Cityu. All rights reserved.
//

import Foundation
import M3U8
import FileBrowse

protocol DownloadMgrDelegate: AnyObject {
    func downloadMgrDidUpdateProgress(_ model: DProgressModel)
    func downloadMgrDidCompleteDownload(_ model: DProgressModel, withFile filePath: String)
    func downloadMgrDidFailDownload(_ model: DProgressModel, withError error: Error)
    func downloadMgrDidUpdateTaskList()
}

class DownloadMgr {
    weak var delegate: DownloadMgrDelegate?
    
    private let downloadingDBM: DProgressDBM
    private let localDBM: DProgressDBM
    private var taskMap: [String: DownloaderProtocol] = [:]
    
    var downloadingTasks: [DProgressModel] {
        return downloadingDBM.models
    }
    
    var localTasks: [DProgressModel] {
        return localDBM.models
    }
    
    static let shared = DownloadMgr()
    
    private init() {
        downloadingDBM = DProgressDBM.dbmWithTable("downloads")!
        localDBM = DProgressDBM.dbmWithTable("local_files")!
    }
    
    // MARK: - 任务管理
    
    func addDownloadWithURL(_ url: String, title: String?, src: String?) {
        if isDownloadExists(url) { return }
        var title = title ?? ""
        if title.isEmpty {
            let url = URL(string: url)?.deletingPathExtension()
            title = url?.lastPathComponent ?? "未命名"
        }
        let mid = UUID().uuidString
        let model = DProgressModel()
        model.mid = mid
        model.url = url
        model.name = title
        model.progress = 0
        model.src = src
        
        downloadingDBM.add(model)
        delegate?.downloadMgrDidUpdateTaskList()
        checkMIMETypeAndStartDownload(model)
    }
    
    func deleteDownload(_ model: DProgressModel) {
        if let downloader = taskMap[model.mid] {
            downloader.stop()
        }
        
        downloadingDBM.del(model)
        taskMap.removeValue(forKey: model.mid)
        delegate?.downloadMgrDidUpdateTaskList()
    }
    
    func renameDownload(_ model: DProgressModel, withNewName newName: String) {
        if !newName.isEmpty && newName != model.name {
            model.name = newName
            downloadingDBM.update(model)
            delegate?.downloadMgrDidUpdateTaskList()
        }
    }
    
    func isDownloadExists(_ url: String) -> Bool {
        return downloadingDBM.models.contains { $0.url == url }
    }
    
    // MARK: - 下载控制
    
    func startDownload(_ model: DProgressModel) {
        let lowerMimeType = (model.mimeType ?? "").lowercased()
        let pathExtension = URL(string: model.url)?.pathExtension ?? ""
        let isM3U8 = lowerMimeType.contains("mpegurl") || pathExtension.lowercased().hasPrefix("m3u8")
        
        if isM3U8 {
            startM3U8Download(model)
        } else {
            startOtherDownload(model)
        }
    }
    
    func pauseDownload(_ model: DProgressModel) {
        if let downloader = taskMap[model.mid] {
            downloader.stop()
        }
        delegate?.downloadMgrDidUpdateTaskList()
    }
    
    func resumeDownload(_ model: DProgressModel) {
        if let downloader = taskMap[model.mid] {
            downloader.start()
        } else {
            startDownload(model)
        }
        delegate?.downloadMgrDidUpdateTaskList()
    }
    
    func redownload(_ model: DProgressModel) {
        if let downloader = taskMap[model.mid] {
            downloader.stop()
            downloader.clearCache()
        }
        
        model.progress = 0
        model.speed = 0
        downloadingDBM.update(model)
        
        startDownload(model)
        delegate?.downloadMgrDidUpdateTaskList()
    }
    
    func isDownloading(_ model: DProgressModel) -> Bool {
        return taskMap[model.mid]?.isDownloading ?? false
    }
    
    // MARK: - 私有方法
    
    private func checkMIMETypeAndStartDownload(_ model: DProgressModel) {
        MIME.getMimeType(forURL: model.url) { [weak self] mimeType, error in
            DispatchQueue.main.async {
                guard error == nil else { return }
                model.mimeType = mimeType
                self?.downloadingDBM.update(model)
                self?.startDownload(model)
            }
        }
    }
    
    private func mobileUA() -> String {
        let iOSVersion = "17.5" // UIDevice.current.systemVersion
        let formattediOSVersion = iOSVersion.replacingOccurrences(of: ".", with: "_")
        
        // 解析主版本号（如iOS 16.5 -> 16）
        let majorVersion = iOSVersion.components(separatedBy: ".").first ?? "17"
        
        // 生成对应Mobile版本号（如iOS 16.5 -> 16E150）
        let mobileBuild: String
        if Int(majorVersion) ?? 0 >= 17 {
            mobileBuild = "19A346" // iOS 17+ 通用
        } else if Int(majorVersion) ?? 0 >= 16 {
            mobileBuild = "16A366" // iOS 16+ 通用
        } else {
            mobileBuild = "15E148" // iOS 15及以下通用
        }
        
        return "Mozilla/5.0 (iPhone; CPU iPhone OS \(formattediOSVersion) like Mac OS X) AppleWebKit/605.1.15 (KHTML, like Gecko) Version/\(majorVersion) Mobile/\(mobileBuild) Safari/604.1"
    }
    
    private func getHeaders(dest: String, url: String?) -> [String: String] {
        var headers: [String: String] = [:]
        
        headers["accept"] = "*/*"
        headers["accept-language"] = "zh-CN,zh-Hans;q=0.9"
        headers["accept-encoding"] = "gzip, deflate, br" // 支持更多压缩格式
        
        headers["Sec-Fetch-Dest"] = dest.isEmpty ? "document" : dest
        headers["Sec-Fetch-Mode"] = "no-cors"
        headers["Sec-Fetch-Site"] = "same-origin"
        
        headers["user-agent"] = mobileUA()
        headers["connection"] = "Keep-Alive"
        
        if let url = url, !url.isEmpty {
            if let URL = URL(string: url) {
                headers["Host"] = URL.host
                headers["Referer"] = url.components(separatedBy: "?").first
            }
        }
        
        return headers
    }
    
    private func startM3U8Download(_ model: DProgressModel) {
        let downloader = M3U8VideoDownloader(model.url) { [weak self] progress in
            self?.handleDownloadProgress(progress, model: model)
        } completion: { [weak self] file, error in
            self?.handleDownloadCompleteWithFile(file, model: model, error: error)
        }
        
        taskMap[model.mid] = downloader
        downloader.headers = getHeaders(dest: "video", url: nil)
        downloader.start()
    }
    
    private func startOtherDownload(_ model: DProgressModel) {
        let headers = getHeaders(dest: "document", url: model.url)
        let downloader = DownloaderProvider.create(with: model.url, headers: headers) { [weak self] progress in
            DispatchQueue.main.async {
                self?.handleDownloadProgress(progress, model: model)
            }
        } completion: { [weak self] file, error in
            DispatchQueue.main.async {
                self?.handleDownloadCompleteWithFile(file, model: model, error: error)
            }
        }
        
        taskMap[model.mid] = downloader
        downloader.start()
    }
    
    private func handleDownloadProgress(_ progress: Float, model: DProgressModel) {
        model.progress = progress
        model.speed = taskMap[model.mid]?.speed ?? 0
        downloadingDBM.update(model)
        delegate?.downloadMgrDidUpdateProgress(model)
    }
    
    private func handleDownloadCompleteWithFile(_ file: String?, model: DProgressModel, error: Error?) {
        if let error = error {
            downloadingDBM.update(model)
            delegate?.downloadMgrDidFailDownload(model, withError: error)
            logDPModel(model, error: error)
        } else {
            handleDownloadCompleteWithFile(file, model: model)
            taskMap[model.mid] = nil
        }
    }
    
    private func handleDownloadCompleteWithFile(_ file: String?, model: DProgressModel) {
        guard let file = file, !file.isEmpty else {
            downloadingDBM.update(model)
            delegate?.downloadMgrDidUpdateTaskList()
            return
        }
        
        model.progress = 1.0
        
        let documents = NSSearchPathForDirectoriesInDomains(.documentDirectory, .userDomainMask, true).first!
        let downloaderDir = documents + "/" + "Downloader"
        
        let fileModel = FileModel(filePath: file)
        let ext = fileModel.fileExtensionString() as String
        
        let newFileName = "\(model.name).\(ext)"
        let newFilePath = FileMgr.shareManager.moveFile(file, toNewPath: downloaderDir, rename: newFileName, isOverwrite: false) ?? ""
        
        if newFilePath.isEmpty {
            print("文件存储失败")
        }
        
        let localModel:DProgressModel = model.copy() as! DProgressModel
        localModel.progress = 1.0
        
        downloadingDBM.del(model)
        localDBM.add(localModel)
        
        delegate?.downloadMgrDidCompleteDownload(model, withFile: newFilePath)
        delegate?.downloadMgrDidUpdateTaskList()
    }
    
    private func failedWithDPModel(_ model: DProgressModel, error: Error) -> String {
        var str = ""
        str += "\(model.name)🔴\(error.localizedDescription)\n"
        str += "\t❗️\(model.url)\n"
        
        if let url = (error as NSError).userInfo["NSErrorFailingURLKey"] as? URL {
            let ustr = url.absoluteString
            if ustr != model.url {
                str += "\t‼️\(ustr)\n"
            }
        } else if let url = (error as NSError).userInfo["NSErrorFailingURLStringKey"] as? String {
            if url != model.url {
                str += "\t‼️\(url)\n"
            }
        }
        
        if let file = (error as NSError).userInfo[NSFilePathErrorKey] as? String {
            str += "\t‼️\(file)\n"
        }
        
        if let msg = (error as NSError).userInfo[NSUnderlyingErrorKey] {
            str += "\t\(msg)\n"
        }
        
        str += "\n"
        return str
    }
    
    private func logDPModel(_ model: DProgressModel, error: Error) {
        let log = failedWithDPModel(model, error: error)
        LogLine.shared.fatal(log)
    }
    
    // MARK: - 数据获取
    
    func taskAtIndex(_ index: Int) -> DProgressModel? {
        guard index >= 0 && index < downloadingDBM.models.count else { return nil }
        return downloadingDBM.models[index]
    }
    
    var taskCount: Int {
        return downloadingDBM.models.count
    }
}
