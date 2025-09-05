//
//  DownloadingViewController.swift
//  QVGrab
//
//  Created by Cityu on 2025/4/28.
//

import UIKit

class DownloadingViewController: UIViewController {
    
    private var tableView: UITableView!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        title = "Dmgr"
        
        if #available(iOS 13.0, *) {
            view.backgroundColor = UIColor.systemBackground
        } else {
            view.backgroundColor = UIColor.white
        }
        
        DownloadMgr.shared.delegate = self
        setupTableView()
        reloadData()
        
        // 添加右上角按钮
        let addBtn = UIBarButtonItem(barButtonSystemItem: .add, target: self, action: #selector(showAddDownloadDialog))
        navigationItem.rightBarButtonItem = addBtn
        
        // 添加tableView长按手势
        let longPress = UILongPressGestureRecognizer(target: self, action: #selector(handleTableLongPress(_:)))
        tableView.addGestureRecognizer(longPress)
    }
    
    override var supportedInterfaceOrientations: UIInterfaceOrientationMask {
        return .portrait
    }
    
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        // 页面显示，禁止屏幕自动休眠（保持常亮）
        UIApplication.shared.isIdleTimerDisabled = true
    }
    
    override func viewDidDisappear(_ animated: Bool) {
        super.viewDidDisappear(animated)
        // 页面消失，恢复屏幕自动休眠功能
        UIApplication.shared.isIdleTimerDisabled = false
    }
    
    private func setupTableView() {
        tableView = UITableView(frame: view.bounds, style: .plain)
        tableView.backgroundColor = UIColor.clear
        tableView.delegate = self
        tableView.dataSource = self
        tableView.register(DownloadCell.self, forCellReuseIdentifier: "DownloadCell")
        view.addSubview(tableView)
        tableView.autoresizingMask = [.flexibleWidth, .flexibleHeight]
    }
    
    private func reloadData() {
        tableView.reloadData()
    }
    
    // MARK: - 添加新下载任务
    
    @objc private func showAddDownloadDialog() {
        let alert = UIAlertController(title: "新建下载", message: "请输入文件名和下载地址", preferredStyle: .alert)
        
        alert.addTextField { textField in
            textField.placeholder = "文件名（可选）"
        }
        
        alert.addTextField { textField in
            textField.placeholder = "下载地址"
        }
        
        let cancel = UIAlertAction(title: "取消", style: .cancel)
        let ok = UIAlertAction(title: "确认", style: .default) { [weak self] _ in
            guard let self = self else { return }
            let title = alert.textFields?[0].text
            let url = alert.textFields?[1].text ?? ""
            
            if !url.isEmpty {
                let downloadMgr = DownloadMgr.shared
                if downloadMgr.isDownloadExists(url) {
                    let existAlert = UIAlertController(title: "提示", message: "该任务已存在", preferredStyle: .alert)
                    existAlert.addAction(UIAlertAction(title: "确定", style: .default))
                    self.present(existAlert, animated: true)
                    return
                }
                downloadMgr.addDownloadWithURL(url, title: title ?? "", src: nil)
            }
        }
        
        alert.addAction(cancel)
        alert.addAction(ok)
        present(alert, animated: true)
    }
    
    // MARK: - TableView 长按弹出菜单
    
    @objc private func handleTableLongPress(_ gesture: UILongPressGestureRecognizer) {
        guard gesture.state == .began else { return }
        
        let point = gesture.location(in: tableView)
        guard let indexPath = tableView.indexPathForRow(at: point) else { return }
        
        let cell = tableView.cellForRow(at: indexPath)

        guard let model = DownloadMgr.shared.taskAtIndex(indexPath.row) else {
            return
        }
        let downloadMgr = DownloadMgr.shared
        let isDownloading = downloadMgr.isDownloading(model)
        
        // 弹出菜单
        let menu = UIAlertController(title: "操作", message: nil, preferredStyle: .actionSheet)
        
        // 重命名
        let rename = UIAlertAction(title: "重命名", style: .default) { [weak self] _ in
            self?.showRenameDialogForModel(model)
        }
        
        let copyAction = UIAlertAction(title: "复制地址", style: .default) { [weak self] _ in
            if !model.url.isEmpty {
                UIPasteboard.general.string = model.url
                showToast("已复制", in: self?.view)
            }
        }
        
        // 删除
        let deleteAction = UIAlertAction(title: "删除", style: .destructive) { [weak self] _ in
            guard let self = self else { return }
            let confirm = UIAlertController(title: "确认删除？", message: "将停止当前下载并删除任务，是否继续？", preferredStyle: .alert)
            let cancel = UIAlertAction(title: "取消", style: .cancel)
            let ok = UIAlertAction(title: "确认", style: .destructive) { _ in
                DownloadMgr.shared.deleteDownload(model)
            }
            confirm.addAction(cancel)
            confirm.addAction(ok)
            self.present(confirm, animated: true)
        }
        
        // 重新下载
        let redownload = UIAlertAction(title: "重新下载", style: .default) { [weak self] _ in
            guard let self = self else { return }
            let confirm = UIAlertController(title: "确认重新下载？", message: "将停止当前下载并清空缓存，是否继续？", preferredStyle: .alert)
            let cancel = UIAlertAction(title: "取消", style: .cancel)
            let ok = UIAlertAction(title: "确认", style: .destructive) { _ in
                DownloadMgr.shared.redownload(model)
            }
            confirm.addAction(cancel)
            confirm.addAction(ok)
            self.present(confirm, animated: true)
        }
        
        // 开始/暂停
        let toggleTitle = isDownloading ? "暂停" : "开始"
        let toggle = UIAlertAction(title: toggleTitle, style: .default) { _ in
            if isDownloading {
                downloadMgr.pauseDownload(model)
            } else {
                downloadMgr.resumeDownload(model)
            }
        }
        
        let cancel = UIAlertAction(title: "取消", style: .cancel)
        menu.addAction(toggle)
        menu.addAction(copyAction)
        menu.addAction(redownload)
        menu.addAction(rename)
        menu.addAction(deleteAction)
        menu.addAction(cancel)
        
        // iPad 适配
        if let popover = menu.popoverPresentationController {
            popover.sourceView = cell
            popover.sourceRect = cell?.bounds ?? .zero
        }
        
        present(menu, animated: true)
    }
    
    // MARK: - 重命名逻辑
    
    private func showRenameDialogForModel(_ model: DProgressModel) {
        let alert = UIAlertController(title: "重命名", message: "请输入新名称", preferredStyle: .alert)
        
        alert.addTextField { textField in
            textField.placeholder = "新名称"
            textField.text = model.name
        }
        
        let cancel = UIAlertAction(title: "取消", style: .cancel)
        let ok = UIAlertAction(title: "确认", style: .default) { _ in
            let newName = alert.textFields?.first?.text ?? ""
            if !newName.isEmpty && newName != model.name {
                DownloadMgr.shared.renameDownload(model, withNewName: newName)
            }
        }
        
        alert.addAction(cancel)
        alert.addAction(ok)
        present(alert, animated: true)
    }
}

// MARK: - UITableViewDataSource

extension DownloadingViewController: UITableViewDataSource {
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return DownloadMgr.shared.taskCount
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "DownloadCell", for: indexPath) as! DownloadCell
        if let model = DownloadMgr.shared.taskAtIndex(indexPath.row) {
            let isDownloading = DownloadMgr.shared.isDownloading(model)
            cell.configureWithModel(model, isDownloading: isDownloading)
        }
        
        return cell
    }
}

// MARK: - UITableViewDelegate

extension DownloadingViewController: UITableViewDelegate {
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        tableView.deselectRow(at: indexPath, animated: true)
        
        guard let model = DownloadMgr.shared.taskAtIndex(indexPath.row) else { return }
         
        guard model.progress < 1.0 else { return }
        
        let downloadMgr = DownloadMgr.shared
        let isDownloading = downloadMgr.isDownloading(model)
        
        if isDownloading {
            downloadMgr.pauseDownload(model)
        } else {
            downloadMgr.resumeDownload(model)
        }
    }
    
    // 支持左滑删除
    func tableView(_ tableView: UITableView, canEditRowAt indexPath: IndexPath) -> Bool {
        return true
    }
    
    func tableView(_ tableView: UITableView, commit editingStyle: UITableViewCell.EditingStyle, forRowAt indexPath: IndexPath) {
        if editingStyle == .delete {
            guard let model = DownloadMgr.shared.taskAtIndex(indexPath.row) else { return }
            DownloadMgr.shared.deleteDownload(model)
        }
    }
}

// MARK: - DownloadMgrDelegate

extension DownloadingViewController: DownloadMgrDelegate {
    func downloadMgrDidUpdateProgress(_ model: DProgressModel) {
        if let row = DownloadMgr.shared.downloadingTasks.firstIndex(of: model) {
            let indexPath = IndexPath(row: row, section: 0)
            if let cell = tableView.cellForRow(at: indexPath) as? DownloadCell {
                let isDownloading = DownloadMgr.shared.isDownloading(model)
                cell.configureWithModel(model, isDownloading: isDownloading)
            }
        }
    }
    
    func downloadMgrDidCompleteDownload(_ model: DProgressModel, withFile filePath: String) {
        tableView.reloadData()
    }
    
    func downloadMgrDidFailDownload(_ model: DProgressModel, withError error: Error) {
        tableView.reloadData()
    }
    
    func downloadMgrDidUpdateTaskList() {
        tableView.reloadData()
    }
}
