//
//  WebServiceViewController.swift
//  iOS
//
//  Created by Cityu on 2025/6/3.
//  Copyright © 2025 Cityu. All rights reserved.
//

import UIKit

import GCDWebServer

class WebServiceViewController: UIViewController {
    
    private var webServer: GCDWebServer!
    private var webDAVServer: GCDWebDAVServer!
    private var webUploader: GCDWebUploader!
    
    private var scrollView: UIScrollView!
    private var contentView: UIView!
    
    private var webServerView: WebServiceIView!
    private var webDAVServerView: WebServiceIView!
    private var webUploaderView: WebServiceIView!
    
    // 添加认证配置属性
    private var authOptions: [String: Any] = [:]
    
    override func viewDidLoad() {
        super.viewDidLoad()
        title = "WebS"
        
        if #available(iOS 13.0, *) {
            view.backgroundColor = UIColor.systemBackground
        } else {
            view.backgroundColor = UIColor.white
        }
        
        // 初始化认证配置
        setupAuthOptions()
        
        setupUI()
        initializeServers()
    }
    
    private func setupUI() {
        // 创建滚动视图
        scrollView = UIScrollView(frame: view.bounds)
        scrollView.autoresizingMask = [.flexibleWidth, .flexibleHeight]
        view.addSubview(scrollView)
        
        // 创建内容视图
        contentView = UIView()
        scrollView.addSubview(contentView)
        
        // 设置Web Server UI
        setupWebServerUI()
        
        // 设置WebDAV Server UI
        setupWebDAVServerUI()
        
        // 设置Web Uploader UI
        setupWebUploaderUI()
        
        // 更新内容视图大小
        let contentHeight = webUploaderView.frame.maxY + 20
        contentView.frame = CGRect(x: 0, y: 0, width: view.bounds.size.width, height: contentHeight)
        scrollView.contentSize = contentView.frame.size
    }
    
    private func setupWebServerUI() {
        webServerView = WebServiceIView(frame: CGRect(x: 20, y: 20, width: view.bounds.size.width - 40, height: 120))
        webServerView.delegate = self
        webServerView.title = "Web服务器"
        contentView.addSubview(webServerView)
    }
    
    private func setupWebDAVServerUI() {
        webDAVServerView = WebServiceIView(frame: CGRect(x: 20, y: webServerView.frame.maxY + 20, width: view.bounds.size.width - 40, height: 120))
        webDAVServerView.delegate = self
        webDAVServerView.title = "WebDAV服务器"
        contentView.addSubview(webDAVServerView)
    }
    
    private func setupWebUploaderUI() {
        webUploaderView = WebServiceIView(frame: CGRect(x: 20, y: webDAVServerView.frame.maxY + 20, width: view.bounds.size.width - 40, height: 120))
        webUploaderView.delegate = self
        webUploaderView.title = "文件上传服务器"
        contentView.addSubview(webUploaderView)
    }
    
    // MARK: - Server Control Methods
    
    private func initializeServers() {
        // 初始化Web服务器
        webServer = GCDWebServer()
        
        webServer.addDefaultHandler(forMethod: "GET", request: GCDWebServerRequest.self) { request in
            let html = "<html><body><h1>欢迎访问Web服务器</h1><p>这是一个由GCDWebServer提供支持的简单Web服务器。</p></body></html>"
            return GCDWebServerDataResponse(html: html)
        }
        
        // 初始化WebDAV服务器
        let documentsPath = "\(NSHomeDirectory())/Documents"
        webDAVServer = GCDWebDAVServer(uploadDirectory: documentsPath)
        
        // 初始化Web上传服务器
        webUploader = GCDWebUploader(uploadDirectory: documentsPath)
    }
    
    // 添加认证配置方法
    private func setupAuthOptions() {
        authOptions = [
            GCDWebServerOption_AuthenticationMethod: GCDWebServerAuthenticationMethod_Basic,
            GCDWebServerOption_AuthenticationRealm: "Web Server",
            GCDWebServerOption_AuthenticationAccounts: [
                "admin": "123456"  // 用户名:密码
            ]
        ]
    }
    
    deinit {
        webServer?.stop()
        webDAVServer?.stop()
        webUploader?.stop()
    }
}

// MARK: - WebServiceIViewDelegate

extension WebServiceViewController: WebServiceIViewDelegate {
    func webServiceIView(_ view: WebServiceIView, openSwitch open: Bool) {
        if view == webServerView {
            if open {
                var options: [String: Any] = [
                    GCDWebServerOption_Port: 8080,
                    GCDWebServerOption_BonjourName: "Web Server",
                    GCDWebServerOption_BindToLocalhost: false,  // 允许外部访问
                    GCDWebServerOption_MaxPendingConnections: 16,  // 最大等待连接数
                    GCDWebServerOption_ServerName: "Web Server"  // 服务器名称
                ]
                
                // 添加认证配置
                options.merge(authOptions) { _, new in new }
                
                do {
                    try webServer.start(options: options)
                    webServerView.url = webServer.serverURL?.absoluteString ?? ""
                } catch {
                    print("Failed to start web server: \(error)")
                    // 显示错误提示
                    let alert = UIAlertController(title: "错误", message: "启动Web服务器失败", preferredStyle: .alert)
                    alert.addAction(UIAlertAction(title: "确定", style: .default))
                    present(alert, animated: true)
                    return
                }
            } else {
                webServer.stop()
            }
            webServerView.open = open
        } else if view == webDAVServerView {
            if open {
                var options: [String: Any] = [
                    GCDWebServerOption_Port: 8081,
                    GCDWebServerOption_BonjourName: "WebDAV Server",
                    GCDWebServerOption_BindToLocalhost: false,
                    GCDWebServerOption_MaxPendingConnections: 16,
                    GCDWebServerOption_ServerName: "WebDAV Server"
                ]
                
                // 添加认证配置
                options.merge(authOptions) { _, new in new }
                
                do {
                    try webDAVServer.start(options: options)
                    webDAVServerView.url = webDAVServer.serverURL?.absoluteString ?? ""
                } catch {
                    print("Failed to start WebDAV server: \(error)")
                    let alert = UIAlertController(title: "错误", message: "启动WebDAV服务器失败", preferredStyle: .alert)
                    alert.addAction(UIAlertAction(title: "确定", style: .default))
                    present(alert, animated: true)
                    return
                }
            } else {
                webDAVServer.stop()
            }
            webDAVServerView.open = open
        } else if view == webUploaderView {
            if open {
                var options: [String: Any] = [
                    GCDWebServerOption_Port: 8082,
                    GCDWebServerOption_BonjourName: "Web Uploader",
                    GCDWebServerOption_BindToLocalhost: false,
                    GCDWebServerOption_MaxPendingConnections: 16,
                    GCDWebServerOption_ServerName: "Web Uploader"
                ]
                
                // 添加认证配置
                options.merge(authOptions) { _, new in new }
                
                do {
                    try webUploader.start(options: options)
                    webUploaderView.url = webUploader.serverURL?.absoluteString ?? ""
                } catch {
                    print("Failed to start Web Uploader: \(error)")
                    let alert = UIAlertController(title: "错误", message: "启动文件上传服务器失败", preferredStyle: .alert)
                    alert.addAction(UIAlertAction(title: "确定", style: .default))
                    present(alert, animated: true)
                    return
                }
            } else {
                webUploader.stop()
            }
            webUploaderView.open = open
        }
    }
}
