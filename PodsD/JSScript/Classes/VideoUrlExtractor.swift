//
//  VideoUrlExtractor.swift
//  JSScript
//
//  Created by Cityu on 2024/12/13.
//

import Foundation
import WebKit


public class VideoUrlExtractor: NSObject {
    
    // MARK: - Properties
    
    private(set) var webView: WKWebView
    private var completionHandler: (([Any]) -> Void)?
    
    // MARK: - Initialization
    private var extractFunc: String!
    /**
     初始化视频URL提取器
     @param webView 用于加载网页的WKWebView实例
     @param completion 回调block，返回视频信息数组，每个元素包含url和title
     */
    public init(webView: WKWebView, callback: @escaping ([Any]) -> Void) {
        self.webView = webView
        self.completionHandler = callback
        super.init()
        setupWebView()
    }
    
    // MARK: - Private Methods
    
    private func loadJSCode(_ ejs:Bool = true)->(script:String, messageFunc:String, extractFunc:String)? {
        guard let path = JSScriptBundle.resourceBundle.path(forResource: "extractVideoUrl", ofType: ejs ? "ejs" : "js"),
              let script = try? String(contentsOfFile: path, encoding: .utf8) else {
            print("Failed to load extractVideoUrl")
            return nil
        }
        let messageFunc = "videoExtractor"
        let extractFunc = "extractVideoUrl"
        let scriptCode = script
        return (scriptCode, messageFunc, extractFunc)
    }

    
    private func setupWebView() {
        // 配置 WKWebView
        let config = webView.configuration
        // 注入 JavaScript 代码
        
        guard let js = loadJSCode() else {
            return
        }
        
        self.extractFunc = js.extractFunc
        
        let userScript = WKUserScript(
            source: js.script,
            injectionTime: .atDocumentEnd,
            forMainFrameOnly: false
        )
        
        config.userContentController.setScriptMessage(js.messageFunc, webView: webView) { [unowned self] message in
            
            guard let messageBody = message.body as? [String: Any] else { return }
            
            let error = messageBody["error"]
            let type = messageBody["type"]
            print("videoExtractor type: \(String(describing: type)), error: \(String(describing: error))")
            
            if let videos = messageBody["videos"] as? [Any], !videos.isEmpty {
                self.completionHandler?(videos)
            }
        }
        

        config.userContentController.setUserScript(userScript, forKey: "extractVideoUrl")
    }
    
    // MARK: - Public Methods
    
    /**
     开始提取视频URL
     */
    public func extract() {
        webView.evaluateJavaScript(extractFunc + "();") { result, error in
            if let error = error {
                print("Error executing script: \(error)")
            }
        }
    }
}
