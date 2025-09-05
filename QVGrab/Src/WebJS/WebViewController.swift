//
//  WebViewController.swift
//  QVGrab
//
//  Created by Cityu on 2024/12/13.
//

import UIKit
import LithUI
import WebKit
import SnapKit

class WebViewController: UIViewController {
    
    private var wrappingView: WrappingView!
    private var coreInput: UrlInputView!
    private var sessionManager: WebViewSessionManager!
    private var historyManager: HistoryManager!
    private var bookmarkManager: BookmarkManager!
    private var homeUrl: String = "https://cn.bing.com/"
    private var snifferView: UIButton!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        if #available(iOS 13.0, *) {
            view.backgroundColor = UIColor.systemBackground
        } else {
            view.backgroundColor = UIColor.white
        }
        
        homeUrl = "https://cn.bing.com/"
        setupWrappingView()
        
        sessionManager = WebViewSessionManager()
        sessionManager.delegate = self
        historyManager = HistoryManager.sharedManager
        bookmarkManager = BookmarkManager.sharedManager
        
        setupNavBar()
        updateWebViewDisplay()
        setupSnifferView()
        
        // 默认新建一个 session
        openNewSession(homeUrl, current: true)
        
        // 初始化时更新tabbar角标
        updateTabBarBadge()
    }
    
    // MARK: - Setup Methods
    
    private func setupWrappingView() {
        wrappingView = WrappingView()
        view.addSubview(wrappingView)
        wrappingView.snp.makeConstraints { make in
            make.edges.equalTo(view)
        }
    }
    
    private func setupSnifferView() {
        snifferView = UIButton(type: .system)
        snifferView.setImage(UIImage(named: "down"), for: .normal)
        
        snifferView.addTarget(self, action: #selector(snifferViewAction), for: .touchUpInside)
        
        view.addSubview(snifferView)
        snifferView.snp.makeConstraints { make in
            make.right.equalTo(view).offset(0)
            make.width.height.equalTo(40)
            make.bottom.equalTo(view).offset(-80)
        }
    }
    
    @objc private func snifferViewAction() {
        let alert = UIAlertController(title: "发现视频地址", message: nil, preferredStyle: .actionSheet)
        guard let current = sessionManager.current else { return }
        for videoInfo in current.videoInfos {
            let actionTitle = videoInfo.title != nil ? "\(videoInfo.title!)\n\(videoInfo.url)" : videoInfo.url
            let action = UIAlertAction(title: actionTitle, style: .default) { _ in
                DownloadMgr.shared.addDownloadWithURL(videoInfo.url, title: videoInfo.title ?? "", src: videoInfo.src)
            }
            alert.addAction(action)
        }
        
        alert.addAction(UIAlertAction(title: "取消", style: .cancel))
        present(alert, animated: true)
    }
    
    // MARK: - NavBar
    
    private func setupNavBar() {
        navigationController?.navigationBar.isTranslucent = false
        
        coreInput = UrlInputView(frame: CGRect(x: 0, y: 0, width: UIScreen.main.bounds.size.width, height: 30))
        
        coreInput.onInput = { [unowned self] url in
            self.navBarInputAction(url)
        }
        
        coreInput.onReload = { [unowned self] in
            self.navBarReloadAction()
        }
        
        coreInput.onLeft = {
            // 处理左侧按钮点击
        }
        
        let btn = UIButton(type: .system)
        btn.setImage(UIImage(named: "nav_back"), for: .normal)
        btn.addTarget(self, action: #selector(navBarBackAction), for: .touchUpInside)
        let leftBarButton = UIBarButtonItem(customView: btn)
        
        coreInput.onRespond = { [weak self] editing in
            self?.navigationItem.leftBarButtonItem = editing ? nil : leftBarButton
            self?.coreInput.frame = CGRect(x: 0, y: 0, width: UIScreen.main.bounds.size.width, height: 30)
            self?.navigationItem.titleView = self?.coreInput
        }
        
        navigationItem.leftBarButtonItem = leftBarButton
        
        let rightBarButton = UIBarButtonItem(title: "更多", style: .plain, target: self, action: #selector(navBarMoreAction))
        navigationItem.rightBarButtonItem = rightBarButton
        navigationItem.titleView = coreInput
    }
    
    private func navBarInputAction(_ url: String) {
        guard !url.isEmpty else { return }
        
        guard let session = sessionManager.current else { return }
        session.loadTarget(url)
    }
    
    private func navBarReloadAction() {
        guard let session = sessionManager.current else { return }
        session.reload()
    }
    
    @objc private func navBarBackAction() {
        guard let session = sessionManager.current else { return }
        if session.canGoBack {
            session.goBack()
        }
    }
    
    @objc private func navBarMoreAction() {
        guard let rightBarButtonItem = navigationItem.rightBarButtonItem else { return }
        var items: [PopoverCItem] = []
        
        // 刷新页面
        let refreshItem = PopoverCItem()
        refreshItem.title = "刷新页面"
        refreshItem.handler = { [weak self] _ in
            let session = self?.sessionManager.current
            session?.reload()
        }
        items.append(refreshItem)
        
        // 视频嗅探
        let sniffItem = PopoverCItem()
        sniffItem.title = "视频嗅探"
        sniffItem.handler = { [weak self] _ in
            let session = self?.sessionManager.current
            session?.extractVideo()
        }
        items.append(sniffItem)
        
        if let session = sessionManager.current {
            // 书签
            let bookmarkItem = PopoverCItem()
            let hasBookmark = bookmarkManager.hasBookmarkWithURL(session.currentURL)
            bookmarkItem.title = hasBookmark ? "删除书签" : "加入书签"
            bookmarkItem.handler = { [weak self] _ in
                guard let self = self else { return }
                if let session = self.sessionManager.current {
                    if hasBookmark {
                        self.bookmarkManager.removeBookmarkWithURL(session.currentURL)
                    } else {
                        self.bookmarkManager.addBookmarkWithURL(session.currentURL, title: session.title)
                    }
                }
            }
            items.append(bookmarkItem)
        }
        
        
        // 历史/书签
        let historyItem = PopoverCItem()
        historyItem.title = "历史/书签"
        historyItem.handler = { [weak self] _ in
            guard let self = self else { return }
            let historyVC = WRouterPageViewController()
            historyVC.setSelectedCallback { [weak self] url, bgFlag in
                if bgFlag {
                    self?.openNewSession(url, current: false)
                } else {
                    let session = self?.sessionManager.current
                    session?.loadTarget(url)
                }
                self?.navigationController?.popViewController(animated: false)
            }
            self.navigationController?.pushViewController(historyVC, animated: true)
        }
        items.append(historyItem)
        
        // 新建窗口
        let newWindowItem = PopoverCItem()
        newWindowItem.title = "新建窗口"
        newWindowItem.handler = { [weak self] _ in
            self?.openNewSession(self?.homeUrl ?? "", current: true)
        }
        items.append(newWindowItem)
        
        // 窗口管理
        let windowManageItem = PopoverCItem()
        windowManageItem.title = "窗口(\(sessionManager.sessionCount))"
        windowManageItem.afterDismis = true
        windowManageItem.handler = { [weak self] _ in
            self?.openSessionMgrCtrl()
        }
        items.append(windowManageItem)
        
        let popover = PopoverController()
        popover.modalPresentationStyle = .popover
        popover.items = items
        popover.present(rightBarButtonItem)
    }
    
    // MARK: - Actions
    
    private func openSessionMgrCtrl() {
        let vc = SessionViewMgrController()
        vc.sessions = sessionManager.sessions
        vc.currentSessionIndex = sessionManager.currentIndex
        
        vc.onSelectSession = { [unowned self] index in
            self.switchToSessionAtIndex(index)
        }
        
        vc.onCloseSession = { [unowned self] index in
            self.removeSessionAtIndex(index)
            vc.sessions = self.sessionManager.sessions
            vc.currentSessionIndex = self.sessionManager.currentIndex
            vc.reload()
        }
        
        vc.onAddNewSession = { [unowned self] in
            self.openNewSession(self.homeUrl, current: true)
            vc.sessions = self.sessionManager.sessions
            vc.currentSessionIndex = self.sessionManager.currentIndex
            vc.reload()
        }
        
        sessionManager.current?.setNeedPreview()
        let nav = UINavigationController(rootViewController: vc)
        nav.navigationBar.isTranslucent = false
        
        if #available(iOS 13.0, *) {
            nav.view.backgroundColor = UIColor.systemBackground
        } else {
            nav.view.backgroundColor = UIColor.white
        }
        
        present(nav, animated: true)
    }
    
    private func openNewSession(_ target: Any, current: Bool) {
        let conf = WKWebViewConfiguration()
        conf.allowsInlineMediaPlayback = true
        conf.mediaTypesRequiringUserActionForPlayback = []
        conf.preferences.javaScriptEnabled = true
        conf.preferences.setValue(true, forKey: "developerExtrasEnabled")
        
        let session = sessionManager.insertSessionWithConfig(conf, indexType: current ? .current : .normal)
        session.delegate = self
        session.loadTarget(target)
    }
    
    private func switchToSessionAtIndex(_ index: Int) {
        sessionManager.currentIndex = index
    }
    
    private func removeSessionAtIndex(_ index: Int) {
        sessionManager.delSession(index)
    }
    
    private func displaySession(_ session: WebViewSession) -> Bool {
//        guard let session = session else { return false }
        
        let index = sessionManager.sessionIndex(session)
        guard index != NSNotFound else { return false }
        
        sessionManager.currentIndex = index
        updateWebViewDisplay()
        return true
    }
    
    private func updateWebViewDisplay() {
        guard let session = sessionManager.current else { return }
        wrappingView.view = session.webView
        
        coreInput.url = session.currentURL
        coreInput.title = session.title
        
        snifferView.isHidden = session.videoInfos.isEmpty
    }
    
    // MARK: - TabBar Badge
    
    private func updateTabBarBadge() {
        let sessionCount = sessionManager.sessionCount
        var title = navigationController?.tabBarItem.title ?? ""
        title = title.components(separatedBy: " ").first ?? ""
        
        if sessionCount > 1 {
            title = "\(title) \(sessionCount)"
        }
        navigationController?.tabBarItem.title = title
    }
}

// MARK: - WebViewSessionDelegate

extension WebViewController: WebViewSessionDelegate {
    func webViewSession(_ session: WebViewSession, didStartNavigation url: String) {
        guard sessionManager.current == session else { return }
        coreInput.url = session.currentURL
        coreInput.title = session.title
        snifferView.isHidden = true
    }
    
    func webViewSession(_ session: WebViewSession, didFinishNavigation url: String) {
        guard sessionManager.current == session else { return }
        coreInput.url = session.currentURL
        coreInput.title = session.title
        historyManager.addHistoryWithURL(session.currentURL, title: session.title)
    }
    
    func webViewSession(_ session: WebViewSession, didSnifferVideo videoInfo: VideoInfo) {
        guard sessionManager.current == session else { return }
        snifferView.isHidden = false
    }
    
    func webViewSession(_ session: WebViewSession, newSessionWithConf conf: WKWebViewConfiguration) -> WebViewSession {
        let newSession = sessionManager.insertSessionWithConfig(conf, indexType: sessionManager.current == session ? .current : .nearby)
        newSession.delegate = self
        return newSession
    }
}

// MARK: - TabViewControllerAction

extension WebViewController: TabViewControllerAction {
    func tabBarSingleAction() {
        openSessionMgrCtrl()
    }
    
    func tabBarDoubleAction() {
        openNewSession(homeUrl, current: true)
    }
}

// MARK: - WebViewSessionManagerDelegate

extension WebViewController: WebViewSessionManagerDelegate {
    func sessionMgr(_ sessionMgr: WebViewSessionManager, changeType: WebViewSessionChangeType) {
        if changeType.contains(.current) {
            // 当前会话发生变化，更新UI
            updateWebViewDisplay()
        }
        
        if changeType.contains(.sessions) {
            // 会话列表发生变化，可能需要更新相关UI
            // 例如窗口管理项的标题等
            updateTabBarBadge()
        }
    }
}
