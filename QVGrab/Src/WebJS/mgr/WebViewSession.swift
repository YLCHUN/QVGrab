//
//  WebViewSession.swift
//  QVGrab
//
//  Created by Cityu on 2024/12/13.
//

import Foundation
import WebKit
import UIKit
import JSScript

protocol WebViewSessionDelegate: AnyObject {
    func webViewSession(_ session: WebViewSession, didStartNavigation url: String)
    func webViewSession(_ session: WebViewSession, didFinishNavigation url: String)
    func webViewSession(_ session: WebViewSession, didSnifferVideo videoInfo: VideoInfo)
    func webViewSession(_ session: WebViewSession, newSessionWithConf conf: WKWebViewConfiguration) -> WebViewSession
    
    // Optional
    func webViewSession(_ session: WebViewSession, shouldOpenNewSession url: String) -> Bool
}

extension WebViewSessionDelegate {
    func webViewSession(_ session: WebViewSession, shouldOpenNewSession url: String) -> Bool {
        return true
    }
}

protocol WebViewSessionPreviewDelegate: AnyObject {
    func webViewSession(_ session: WebViewSession, didFinishNavigation url: String)
}

class WebViewSession: NSObject {
    
    private(set) var webView: WKWebView!
    
    weak var delegate: WebViewSessionDelegate?
    weak var previewDelegate: WebViewSessionPreviewDelegate?
    
    private(set) var currentURL: String = ""
    private(set) var title: String = ""
    private(set) var favicon: String?
    private(set) var previewImage: UIImage?
    
    private var needPreview = false
//    private var adBlocker: ADBlocker?
    private var extractor: VideoUrlExtractor?
    private var videoTitle: String?
    private var videoUrl: String?
    private(set) var videoInfos: [VideoInfo] = []
    
//    var adBlockerEnabled: Bool {
//        get { return adBlocker?.enabled ?? false }
//        set { adBlocker?.enabled = newValue }
//    }
    
    init(configuration: WKWebViewConfiguration) {
        super.init()
        
        webView = WKWebView(frame: .zero, configuration: configuration)
        webView.navigationDelegate = self
        webView.uiDelegate = self
        if #available(iOS 16.4, *) {
            webView.isInspectable = true
        } else {
            // Fallback on earlier versions
        }
        webView.allowsBackForwardNavigationGestures = true
        
        setupExtractor()
//        setupAdBlocker()
    }
    
    // MARK: - Public Methods
    
    func loadTarget(_ target: Any) {
        var request: URLRequest?
        
        if let urlString = target as? String {
            if let url = URL(string: urlString) {
                request = URLRequest(url: url)
            }
        } else if let url = target as? URL {
            request = URLRequest(url: url)
        } else if let urlRequest = target as? URLRequest {
            request = urlRequest
        }
        
        if let request = request {
            webView.load(request)
        }
    }
    
    func reload() {
        webView.reload()
    }
    
    func goBack() {
        webView.goBack()
    }
    
    var canGoBack: Bool {
        return webView.canGoBack
    }
    
    func getTitle(_ callback: @escaping (String) -> Void) {
        title = webView.title ?? ""
        if !title.isEmpty {
            callback(title)
        } else {
            webView.evaluateJavaScript("document.title") { [weak self] result, error in
                self?.title = result as? String ?? ""
                callback(self?.title ?? "")
            }
        }
    }
    
    func getFavicon(_ callback: @escaping (String?) -> Void) {
        // 如果已经有缓存的favicon，直接返回
        if let favicon = favicon {
            callback(favicon)
            return
        }
        
        // 从文件读取JavaScript代码
        guard let jsPath = Bundle.main.path(forResource: "getFavicon", ofType: "js"),
              let jsCode = try? String(contentsOfFile: jsPath, encoding: .utf8) else {
            print("无法读取getFavicon.js文件")
            callback(nil)
            return
        }
        
        webView.evaluateJavaScript(jsCode) { [weak self] result, error in
            if let error = error {
                print("JavaScript执行错误: \(error.localizedDescription)")
                callback(nil)
                return
            }
            
            guard let result = result as? String, !result.isEmpty else {
                print("JavaScript返回结果为空或类型错误")
                callback(nil)
                return
            }
            
            print("获取到favicon URL: \(result)")
            
            // 缓存favicon URL
            self?.favicon = result
            callback(result)
        }
    }
    
    func getPreviewImage(_ callback: @escaping (UIImage?) -> Void) {
        // 截图
        if !needPreview || webView.isLoading {
            callback(previewImage)
            return
        }
        needPreview = false
        
        // 使用 WKWebView 的截图方法
        webView.takeSnapshot(with: nil) { [weak self] snapshotImage, error in
            self?.previewImage = snapshotImage
            callback(self?.previewImage)
        }
    }
    
    func setNeedPreview() {
        needPreview = true
    }
    
    // MARK: - Video Methods
    
    var videoInfosArray: [VideoInfo] {
        return videoInfos
    }
    
    func extractVideo() {
        extractor?.extract()
    }
    
    // MARK: - Private Methods
    
//    private func setupAdBlocker() {
//        adBlocker = ADBlocker(webView: webView)
//        adBlocker?.enabled = false
//    }
    
    private func setupExtractor() {
        extractor = VideoUrlExtractor(webView: webView) { [weak self] videos in
            guard let info = videos.first as? [String: Any] else { return }
            self?.onVideoExtract(info)
            
            let url = info["url"] as? String ?? ""
            let source = info["source"] as? String ?? ""
            let origin = info["origin"] as? String
            
            var log = "\n【视频嗅探】\(source)"
            log += "\n\t\(url)"
            if let origin = origin, origin != url {
                log += "\n\torigin: \(origin)"
            }
            LogLine.shared.info(log)
        }
        videoInfos = []
    }
    
    private func onVideoExtract(_ videoInfo: [String: Any]) {
        guard let url = videoInfo["url"] as? String, !url.isEmpty else { return }
        
        // 检查是否已存在相同的URL
        for vi in videoInfos {
            if vi.url == url {
                return
            }
        }
        
        let title = videoInfo["title"] as? String
        let processedTitle = title == "未知视频" ? nil : title
        
        let block: (String, String?) -> Void = { [unowned self] url, title in

            let processedTitle = parseVideoTitle(title ?? "")?
                .replacingOccurrences(of: " ", with: "")
            
            let vi = VideoInfo()
            vi.url = url
            vi.title = (processedTitle?.isEmpty ?? true) ? nil : processedTitle
            vi.src = self.currentURL
            
            self.didSnifferVideo(vi)
        }
        
        if let title = processedTitle, !title.isEmpty {
            block(url, title)
        } else {
            getTitle { title in
                block(url, title)
            }
        }
    }
    
    private func didSnifferVideo(_ videoInfo: VideoInfo) {
        videoInfos.append(videoInfo)
        delegate?.webViewSession(self, didSnifferVideo: videoInfo)
    }
}

// MARK: - WKNavigationDelegate

extension WebViewSession: WKNavigationDelegate {
    func webView(_ webView: WKWebView, didStartProvisionalNavigation navigation: WKNavigation!) {
        needPreview = true
        currentURL = webView.url?.absoluteString ?? ""
        title = ""
        favicon = nil
        videoInfos.removeAll()
        
        delegate?.webViewSession(self, didStartNavigation: currentURL)
    }
    
    func webView(_ webView: WKWebView, didFinish navigation: WKNavigation!) {
        getTitle { [weak self] title in
            guard let self = self else { return }
            
            self.delegate?.webViewSession(self, didFinishNavigation: self.currentURL)
            self.previewDelegate?.webViewSession(self, didFinishNavigation: self.currentURL)
        }
    }
    
    func webView(_ webView: WKWebView, decidePolicyFor navigationAction: WKNavigationAction, decisionHandler: @escaping (WKNavigationActionPolicy) -> Void) {
        guard let url = navigationAction.request.url else {
            decisionHandler(.allow)
            return
        }
        
        decisionHandler(.allow)
    }
}

// MARK: - WKUIDelegate

extension WebViewSession: WKUIDelegate {
    func webView(_ webView: WKWebView, createWebViewWith configuration: WKWebViewConfiguration, for navigationAction: WKNavigationAction, windowFeatures: WKWindowFeatures) -> WKWebView? {
        // 检查是否是新窗口请求（如 target="_blank" 或 window.open()）
        if let targetFrame = navigationAction.targetFrame, targetFrame.isMainFrame {
            // 如果是主框架的请求，直接在当前 WebView 中加载
            webView.load(navigationAction.request)
            return nil
        }
        
        let should = delegate?.webViewSession(self, shouldOpenNewSession: navigationAction.request.url?.absoluteString ?? "") ?? true
        
        if should {
            if let newSession = delegate?.webViewSession(self, newSessionWithConf: configuration) {
                newSession.loadTarget(navigationAction.request)
                return newSession.webView
            } else {
                webView.load(navigationAction.request)
                return nil
            }
        } else {
            return nil
        }
    }
}
