//
//  FileBrowseViewController.swift
//  FileBrowse
//
//  Created by Cityu on 2025/4/25.
//

import UIKit

public class FileBrowseViewController: UIViewController {
    private let fileManager = FileMgr.shared
    private weak var tableView: UITableView!
    private let dirPath: String
    private var files: [FileModel] = []
    private var dirConf: FileDirConf
    private var hasAppeared = false
    
    public init(path: String) {
        self.dirPath = path
        self.dirConf = FileDirConf.loadFromPath(path) ?? FileDirConf()
        if FileDirConf.loadFromPath(path) == nil {
            dirConf.sortMode = .byModTime
            dirConf.isAscending = false
            dirConf.saveToPath(path)
        }
        super.init(nibName: nil, bundle: nil)
        updateRightBarButton()
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    public override func viewDidLoad() {
        super.viewDidLoad()
        
        if !fileManager.fileExistsAtPath(dirPath) {
            fileManager.createFolderToFullPath(dirPath)
        }
        
        let folder = fileManager.getFileWithPath(dirPath)
        title = folder.name
        
        files = sortedFiles(fileManager.getAllFileWithPath(dirPath))
        initViews()
    }
    
    public override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        if hasAppeared {
            files = sortedFiles(fileManager.getAllFileWithPath(dirPath))
            tableView.reloadData()
        }
        hasAppeared = true
    }
    
    public override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        updateRightBarButton()
    }
    
    private func updateRightBarButton() {
        let pasteboard = fileManager.pasteboard
        let sortBtn = UIBarButtonItem(title: "排序", style: .plain, target: self, action: #selector(showSortActionSheet))
        
        if let pasteboard = pasteboard {
            let cancel = UIBarButtonItem(title: "取消", style: .plain, target: self, action: #selector(cancelMoveAction))
            if pasteboard.dirPath != dirPath {
                let paste = UIBarButtonItem(title: "粘贴", style: .plain, target: self, action: #selector(pasteAction))
                navigationItem.rightBarButtonItems = [sortBtn, paste, cancel]
            } else {
                navigationItem.rightBarButtonItems = [sortBtn, cancel]
            }
        } else {
            let addBtn = UIBarButtonItem(title: "新建", style: .plain, target: self, action: #selector(addFolderAction))
            navigationItem.rightBarButtonItems = [sortBtn, addBtn]
        }
    }
    
    @objc private func pasteAction() {
        guard let pasteboard = fileManager.pasteboard,
              let file = pasteboard.files.first else { return }
        
        let targetPath = dirPath
        
        // 防止粘贴到自身或子目录
        if file.filePath == targetPath || targetPath.hasPrefix(file.filePath + "/") {
            showAlert(title: "无效操作", message: "不能粘贴到自身或子目录下")
            return
        }
        
        // 防止粘贴到同一目录
        let srcParent = (file.filePath as NSString).deletingLastPathComponent
        if srcParent == targetPath {
            showAlert(title: "无效操作", message: "文件已在当前目录")
            return
        }
        
        let success = fileManager.moveFile(file.filePath, toNewPath: targetPath)
        if success {
            fileManager.pasteboard = nil
            refreshFiles()
            updateRightBarButton()
        } else {
            showAlert(title: "粘贴失败", message: nil)
        }
    }
    
    @objc private func cancelMoveAction() {
        fileManager.pasteboard = nil
        tableView.reloadData()
        updateRightBarButton()
    }
    
    private func initViews() {
        let tv = UITableView(frame: view.bounds, style: .grouped)
        tv.autoresizingMask = [.flexibleWidth, .flexibleHeight]
        if #available(iOS 13.0, *) {
            tv.backgroundColor = .systemBackground
        } else {
            tv.backgroundColor = .white
        }
        tv.delegate = self
        tv.dataSource = self
        view.addSubview(tv)
        tableView = tv
        
        // 添加长按手势
        let longPress = UILongPressGestureRecognizer(target: self, action: #selector(handleLongPress(_:)))
        tv.addGestureRecognizer(longPress)
    }
    
    @objc private func handleLongPress(_ gesture: UILongPressGestureRecognizer) {
        guard gesture.state == .began else { return }
        
        let point = gesture.location(in: tableView)
        guard let indexPath = tableView.indexPathForRow(at: point) else { return }
        
        let alert = UIAlertController(title: "操作", message: nil, preferredStyle: .actionSheet)
        
        alert.addAction(UIAlertAction(title: "重命名", style: .default) { [weak self] _ in
            self?.renameFile(at: indexPath)
        })
        
        alert.addAction(UIAlertAction(title: "分享", style: .default) { [weak self] _ in
            self?.shareFile(at: indexPath)
        })
        
        alert.addAction(UIAlertAction(title: "移动", style: .default) { [weak self] _ in
            self?.moveFile(at: indexPath)
        })
        
        alert.addAction(UIAlertAction(title: "删除", style: .destructive) { [weak self] _ in
            self?.deleteFile(at: indexPath)
        })
        
        alert.addAction(UIAlertAction(title: "取消", style: .cancel))
        
        present(alert, animated: true)
    }
    
    private func refreshFiles() {
        files = sortedFiles(fileManager.getAllFileWithPath(dirPath))
        tableView.reloadData()
    }
    
    private func sortedFiles(_ files: [FileModel]) -> [FileModel] {
        return files.sort([dirConf.sortMode], ascendings: [dirConf.isAscending])
    }
    
    private func showAlert(title: String, message: String?) {
        let alert = UIAlertController(title: title, message: message, preferredStyle: .alert)
        alert.addAction(UIAlertAction(title: "确定", style: .default))
        present(alert, animated: true)
    }
    
    // MARK: - Actions
    @objc private func addFolderAction() {
        let alert = UIAlertController(title: "新建文件夹", message: "请输入文件夹名称", preferredStyle: .alert)
        alert.addTextField { textField in
            textField.placeholder = "文件夹名称"
        }
        
        alert.addAction(UIAlertAction(title: "取消", style: .cancel))
        alert.addAction(UIAlertAction(title: "确定", style: .default) { [weak self] _ in
            guard let self = self,
                  let folderName = alert.textFields?.first?.text,
                  !folderName.isEmpty else { return }
            
            let success = self.fileManager.createFolderToPath(self.dirPath, folderName: folderName)
            if success {
                self.files = self.sortedFiles(self.fileManager.getAllFileWithPath(self.dirPath))
                self.tableView.reloadData()
            } else {
                let failAlert = UIAlertController(title: "创建失败", message: nil, preferredStyle: .alert)
                failAlert.addAction(UIAlertAction(title: "确定", style: .default))
                self.present(failAlert, animated: true)
            }
        })
        
        present(alert, animated: true)
    }
    
    @objc private func showSortActionSheet() {
        let alert = UIAlertController(title: "排序方式", message: nil, preferredStyle: .actionSheet)
        
        let sortOptions:[(String, FileSortMode)] = [
            ("名称", .byName),
            ("修改时间", .byModTime),
            ("大小", .byFileSizefloat)
        ]
        
        for (title, mode) in sortOptions {
            let isCurrent = dirConf.sortMode == mode
            let order = isCurrent ? (dirConf.isAscending ? "↑" : "↓") : ""
            let actionTitle = "\(title)\(order)"
            
            alert.addAction(UIAlertAction(title: actionTitle, style: .default) { [weak self] _ in
                guard let self = self else { return }
                
                if self.dirConf.sortMode == mode {
                    // 同一选项，切换升降序
                    self.dirConf.isAscending.toggle()
                } else {
                    // 切换排序字段，默认升序（时间默认降序）
                    self.dirConf.sortMode = mode
                    if mode == .byModTime {
                        self.dirConf.isAscending = false
                    } else {
                        self.dirConf.isAscending = true
                    }
                }
                self.sortAndReload()
            })
        }
        
        alert.addAction(UIAlertAction(title: "取消", style: .cancel))
        present(alert, animated: true)
    }
    
    private func sortAndReload() {
        files = sortedFiles(files)
        tableView.reloadData()
    }
    
    // MARK: - File Operations
    private func renameFile(at indexPath: IndexPath) {
        let file = files[indexPath.row]
        let alert = UIAlertController(title: "重命名", message: "请输入新文件名", preferredStyle: .alert)
        alert.addTextField { textField in
            textField.text = file.name
        }
        
        alert.addAction(UIAlertAction(title: "取消", style: .cancel))
        alert.addAction(UIAlertAction(title: "确定", style: .default) { [weak self] _ in
            guard let self = self,
                  let newName = alert.textFields?.first?.text,
                  !newName.isEmpty && newName != file.name else { return }
            
            let dirPath = (file.filePath as NSString).deletingLastPathComponent
            let success = self.fileManager.renameFileWithPath(dirPath, oldName: file.name, newName: newName)
            if success {
                self.refreshFiles()
            } else {
                self.showAlert(title: "重命名失败", message: nil)
            }
        })
        
        present(alert, animated: true)
    }
    
    private func shareFile(at indexPath: IndexPath) {
        let file = files[indexPath.row]
        let fileURL = URL(fileURLWithPath: file.filePath)
        let activityVC = UIActivityViewController(activityItems: [fileURL], applicationActivities: nil)
        present(activityVC, animated: true)
    }
    
    private func moveFile(at indexPath: IndexPath) {
        let existingPasteboard = fileManager.pasteboard
        if existingPasteboard != nil && !existingPasteboard!.files.isEmpty {
            let alert = UIAlertController(title: "提示", message: "已有待移动文件，是否覆盖？", preferredStyle: .alert)
            alert.addAction(UIAlertAction(title: "取消", style: .cancel))
            alert.addAction(UIAlertAction(title: "覆盖", style: .destructive) { [weak self] _ in
                self?.actuallyMoveFile(at: indexPath)
            })
            present(alert, animated: true)
            return
        }
        actuallyMoveFile(at: indexPath)
    }
    
    private func actuallyMoveFile(at indexPath: IndexPath) {
        let file = files[indexPath.row]
        let pasteboard = FilePasteboard()
        pasteboard.dirPath = dirPath
        pasteboard.files = [file]
        fileManager.pasteboard = pasteboard
        updateRightBarButton()
        tableView.reloadData()
    }
    
    private func deleteFile(at indexPath: IndexPath) {
        let file = files[indexPath.row]
        let alert = UIAlertController(title: "删除", message: "确定要删除该文件吗？", preferredStyle: .alert)
        alert.addAction(UIAlertAction(title: "取消", style: .cancel))
        alert.addAction(UIAlertAction(title: "删除", style: .destructive) { [weak self] _ in
            guard let self = self else { return }
            let success = self.fileManager.deleteFileWithPath(file.filePath)
            if success {
                self.refreshFiles()
            } else {
                self.showAlert(title: "删除失败", message: nil)
            }
        })
        present(alert, animated: true)
    }
    
    public override var supportedInterfaceOrientations: UIInterfaceOrientationMask {
        if presentedViewController != nil {
            return presentedViewController!.supportedInterfaceOrientations
        } else {
            return .portrait
        }
    }
}

// MARK: - UITableViewDataSource
extension FileBrowseViewController: UITableViewDataSource {
    public func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return files.count
    }
    
    public func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cellId = "FileBrowseViewCell"
        var cell = tableView.dequeueReusableCell(withIdentifier: cellId) as? FileBrowseViewCell
        if cell == nil {
            cell = FileBrowseViewCell(style: .subtitle, reuseIdentifier: cellId)
        }
        
        let file = files[indexPath.row]
        cell?.textLabel?.text = file.name
        cell?.accessoryType = file.isDir ? .disclosureIndicator : .none
        cell?.detailTextLabel?.text = file.fileModelDesc()
        cell?.imageView?.image = UIImage.imageWithExtension(file.fileExtension)
        
        let pasteboard = fileManager.pasteboard
        var shouldDisable = false
        if let pasteboard = pasteboard, pasteboard.dirPath == dirPath {
            for pbFile in pasteboard.files {
                if pbFile.filePath == file.filePath {
                    shouldDisable = true
                    break
                }
            }
        }
        
        cell?.contentView.alpha = shouldDisable ? 0.5 : 1.0
        cell?.isUserInteractionEnabled = !shouldDisable
        
        // 进度条逻辑
        let progress = FileBrowseProvider.progress(file)
        cell?.progress = progress
        
        return cell!
    }
}

// MARK: - UITableViewDelegate
extension FileBrowseViewController: UITableViewDelegate {
    public func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        tableView.deselectRow(at: indexPath, animated: true)
        
        let pasteboard = fileManager.pasteboard
        var shouldDisable = false
        if let pasteboard = pasteboard, pasteboard.dirPath == dirPath {
            let file = files[indexPath.row]
            for pbFile in pasteboard.files {
                if pbFile.filePath == file.filePath {
                    shouldDisable = true
                    break
                }
            }
        }
        
        if shouldDisable { return }
        
        let file = files[indexPath.row]
        if file.isDir {
            let vc = FileBrowseViewController(path: file.filePath)
            navigationController?.pushViewController(vc, animated: true)
        } else {
            var fileDetail: UIViewController?
            var modalToDetail = false
            
            if let detailProvider = FileBrowseProvider.detailProvider {
                if let detail = detailProvider(file) {
                    fileDetail = detail.viewController
                    modalToDetail = detail.modal
                }
            }
            
            if fileDetail == nil {
                fileDetail = FileDetailViewController(fileModel: file)
            }
            
            if modalToDetail {
                present(fileDetail!, animated: true)
            } else {
                navigationController?.pushViewController(fileDetail!, animated: true)
            }
        }
        
        updateRightBarButton()
    }
    
    public func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        return 50
    }
    
    public func tableView(_ tableView: UITableView, viewForHeaderInSection section: Int) -> UIView? {
        return UIView()
    }
    
    public func tableView(_ tableView: UITableView, heightForHeaderInSection section: Int) -> CGFloat {
        return 0.01
    }
    
    public func tableView(_ tableView: UITableView, viewForFooterInSection section: Int) -> UIView? {
        return UIView()
    }
    
    public func tableView(_ tableView: UITableView, heightForFooterInSection section: Int) -> CGFloat {
        return 0.01
    }
    
    // MARK: - Editing
    public func tableView(_ tableView: UITableView, canEditRowAt indexPath: IndexPath) -> Bool {
        let pasteboard = fileManager.pasteboard
        if let pasteboard = pasteboard, pasteboard.dirPath == dirPath {
            let file = files[indexPath.row]
            for pbFile in pasteboard.files {
                if pbFile.filePath == file.filePath {
                    return false
                }
            }
        }
        return true
    }
    
    public func tableView(_ tableView: UITableView, commit editingStyle: UITableViewCell.EditingStyle, forRowAt indexPath: IndexPath) {
        if editingStyle == .delete {
            deleteFile(at: indexPath)
        }
    }
    
    public func tableView(_ tableView: UITableView, titleForDeleteConfirmationButtonForRowAt indexPath: IndexPath) -> String? {
        return "删除"
    }
    
    // MARK: - Swipe Actions
    @available(iOS 11.0, *)
    public func tableView(_ tableView: UITableView, trailingSwipeActionsConfigurationForRowAt indexPath: IndexPath) -> UISwipeActionsConfiguration? {
        let pasteboard = fileManager.pasteboard
        if let pasteboard = pasteboard, pasteboard.dirPath == dirPath {
            let file = files[indexPath.row]
            for pbFile in pasteboard.files {
                if pbFile.filePath == file.filePath {
                    return nil
                }
            }
        }
        
        let deleteAction = UIContextualAction(style: .destructive, title: "删除") { [weak self] _, _, completionHandler in
            self?.deleteFile(at: indexPath)
            completionHandler(true)
        }
        deleteAction.backgroundColor = .systemRed
        
        let configuration = UISwipeActionsConfiguration(actions: [deleteAction])
        configuration.performsFirstActionWithFullSwipe = false
        return configuration
    }
}
