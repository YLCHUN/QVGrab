//
//  MoreViewController.swift
//  FileBrowse
//
//  Created by Cityu on 2025/4/25.
//

import UIKit

// MARK: - MProgress
private class MProgress: UIView {
    var progress: Float = 0 {
        didSet {
            blackView.frame = CGRect(x: 2, y: 2, width: bounds.size.width * CGFloat(progress) - 4, height: bounds.size.height - 4)
            isHidden = progress <= 0 || progress >= 1
        }
    }
    
    private let blackView = UIView()
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        setupView()
    }
    
    required init?(coder: NSCoder) {
        super.init(coder: coder)
        setupView()
    }
    
    private func setupView() {
        backgroundColor = .white
        progress = 0
        layer.borderWidth = 1
        layer.borderColor = UIColor.black.cgColor
        
        blackView.backgroundColor = .black
        blackView.frame = CGRect(x: 2, y: 2, width: bounds.size.width * CGFloat(progress) - 4, height: bounds.size.height - 4)
        addSubview(blackView)
    }
}

// MARK: - MoreViewController
public class MoreViewController: UIViewController {
    public var fileModel: FileModel?
    
    private let fileManager = FileMgr.shared
    private weak var tv: UITableView!
    private var files: [FileModel] = []
    private var homePath: String = ""
    private weak var progress: MProgress?
    
    // 下载相关
    private var longPressFile: FileModel?
    private var longPressIndexPath: IndexPath?
    private var downloadFileName: String = ""
    private var totalLen: UInt = 0
    private var currentLen: UInt = 0
    
    public override func viewDidLoad() {
        super.viewDidLoad()
        
        if fileModel == nil {
            homePath = (NSSearchPathForDirectoriesInDomains(.cachesDirectory, .userDomainMask, true).last! as NSString).appendingPathComponent("FileCache")
            fileManager.createFolderToFullPath(homePath)
            title = "总目录"
        } else {
            title = fileModel!.name
            homePath = fileModel!.filePath
        }
        
        initViews()
        getAllFile()
    }
    
    private func initViews() {
        let tv = UITableView(frame: view.bounds, style: .grouped)
        tv.delegate = self
        tv.dataSource = self
        view.addSubview(tv)
        self.tv = tv
        
        navigationItem.rightBarButtonItem = UIBarButtonItem(barButtonSystemItem: .edit, target: self, action: #selector(addAction))
        
        let progress = MProgress(frame: CGRect(x: 10, y: view.bounds.size.height - 30, width: view.bounds.size.width - 20, height: 20))
        progress.progress = 0
        view.addSubview(progress)
        self.progress = progress
    }
    
    private func getAllFile() {
        files = fileManager.getAllFileWithPath(homePath)
        DispatchQueue.main.async { [weak self] in
            self?.tv.reloadData()
        }
    }
    
    @objc private func addAction() {
        let actionSheetController = UIAlertController(title: nil, message: "操作", preferredStyle: .actionSheet)
        let cancelAction = UIAlertAction(title: "取消", style: .cancel)
        
        let createFolderAction = UIAlertAction(title: "添加一个文件夹", style: .default) { [weak self] _ in
            guard let self = self else { return }
            let num = Int.random(in: 0..<100)
            let name = "新建的文件夹--\(num)"
            if self.fileManager.createFolderToPath(self.homePath, folderName: name) {
                self.getAllFile()
            } else {
                print("创建失败")
            }
        }
        
        let createFileAction = UIAlertAction(title: "新建一个文件", style: .default) { [weak self] _ in
            guard let self = self else { return }
            if self.fileManager.createFileToPath(self.homePath, fileName: "hello.api") {
                self.getAllFile()
            } else {
                print("创建失败")
            }
        }
        
        let addFileAction = UIAlertAction(title: "添加一个文件", style: .default) { [weak self] _ in
            guard let self = self else { return }
            let num = Int.random(in: 0..<100)
            let dic = ["name": "YYQQ"]
            if self.fileManager.addFile(dic, toPath: self.homePath, fileName: "添加的字典--\(num).txt") {
                self.getAllFile()
            } else {
                print("添加失败")
            }
        }
        
        let downloadFileAction = UIAlertAction(title: "下载一个大文件", style: .default) { [weak self] _ in
            guard let self = self else { return }
            let session = URLSession(configuration: .default, delegate: self, delegateQueue: OperationQueue())
            let url = URL(string: "http://120.25.226.186:32812/resources/videos/minion_02.mp4")!
            let dataTask = session.dataTask(with: URLRequest(url: url))
            dataTask.resume()
        }
        
        let searchAction = UIAlertAction(title: "搜索的字文件", style: .default) { [weak self] _ in
            guard let self = self else { return }
            let resFiles = self.fileManager.searchDeepFile("的", folderPath: self.homePath)
            for file in resFiles {
                print(file.name)
            }
        }
        
        actionSheetController.addAction(createFolderAction)
        actionSheetController.addAction(createFileAction)
        actionSheetController.addAction(addFileAction)
        actionSheetController.addAction(downloadFileAction)
        actionSheetController.addAction(searchAction)
        actionSheetController.addAction(cancelAction)
        
        present(actionSheetController, animated: true)
    }
    
    @objc private func cellLongPress(_ longRecognizer: UILongPressGestureRecognizer) {
        guard longRecognizer.state == .began else { return }
        
        let location = longRecognizer.location(in: tv)
        guard let indexPath = tv.indexPathForRow(at: location) else { return }
        
        longPressIndexPath = indexPath
        longPressFile = files[indexPath.row]
        
        becomeFirstResponder()
        let menuController = UIMenuController.shared
        menuController.arrowDirection = .default
        
        let renameItem = UIMenuItem(title: "重命名", action: #selector(renameAction(_:)))
        let moveItem = UIMenuItem(title: "移动", action: #selector(moveFileAction))
        let copyItem = UIMenuItem(title: "复制", action: #selector(copyFileAction))
        
        menuController.menuItems = [renameItem, moveItem, copyItem]
        if let cell = tv.cellForRow(at: indexPath) {
            menuController.setTargetRect(cell.frame, in: tv)
            menuController.setMenuVisible(true, animated: true)
        }
    }
    
    @objc private func renameAction(_ menu: UIMenuController) {
        guard let longPressFile = longPressFile else { return }
        
        let actionAlertController = UIAlertController(title: "重命名", message: nil, preferredStyle: .alert)
        let cancelAction = UIAlertAction(title: "取消", style: .cancel)
        
        let defaultAction = UIAlertAction(title: "确定", style: .default) { [weak self] _ in
            guard let self = self,
                  let newName = actionAlertController.textFields?.first?.text else { return }
            
            if self.fileManager.renameFileWithPath(self.homePath, oldName: longPressFile.name, newName: newName) {
                self.getAllFile()
            } else {
                print("失败")
            }
        }
        
        actionAlertController.addAction(cancelAction)
        actionAlertController.addAction(defaultAction)
        
        actionAlertController.addTextField { textField in
            textField.text = longPressFile.name
        }
        
        present(actionAlertController, animated: true)
    }
    
    @objc private func copyFileAction() {
        guard let longPressFile = longPressFile else { return }
        
        var directoryFile: FileModel?
        for file in files {
            if file.isDir {
                directoryFile = file
                break
            }
        }
        
        if let directoryFile = directoryFile,
           fileManager.copyFile(longPressFile.filePath, toNewPath: directoryFile.filePath) {
            getAllFile()
            print("复制成功")
        } else {
            print("复制失败")
        }
    }
    
    @objc private func moveFileAction() {
        guard let longPressFile = longPressFile else { return }
        
        var directoryFile: FileModel?
        for file in files {
            if file.isDir {
                directoryFile = file
                break
            }
        }
        
        if let directoryFile = directoryFile,
           fileManager.moveFile(longPressFile.filePath, toNewPath: directoryFile.filePath) {
            getAllFile()
            print("移动成功")
        } else {
            print("移动失败")
        }
    }
    
    public override var canBecomeFirstResponder: Bool {
        return true
    }
    
    public override func canPerformAction(_ action: Selector, withSender sender: Any?) -> Bool {
        return action == #selector(renameAction(_:)) || action == #selector(moveFileAction) || action == #selector(copyFileAction)
    }
}

// MARK: - UITableViewDataSource
extension MoreViewController: UITableViewDataSource {
    public func numberOfSections(in tableView: UITableView) -> Int {
        return 1
    }
    
    public func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return files.count
    }
    
    public func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        var cell = tableView.dequeueReusableCell(withIdentifier: "cell")
        if cell == nil {
            cell = UITableViewCell(style: .subtitle, reuseIdentifier: "cell")
            // 添加长按手势
            let longPressGesture = UILongPressGestureRecognizer(target: self, action: #selector(cellLongPress(_:)))
            longPressGesture.minimumPressDuration = 1.0
            cell?.addGestureRecognizer(longPressGesture)
        }
        
        let file = files[indexPath.row]
        cell?.textLabel?.text = file.name
        cell?.accessoryType = .disclosureIndicator
        cell?.detailTextLabel?.text = file.fileModelDesc()
        cell?.imageView?.image = UIImage.imageWithExtension(file.fileExtension)
        
        return cell!
    }
}

// MARK: - UITableViewDelegate
extension MoreViewController: UITableViewDelegate {
    public func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        let file = files[indexPath.row]
        if file.isDir {
            let vc = MoreViewController()
            vc.fileModel = file
            vc.homePath = file.filePath
            navigationController?.pushViewController(vc, animated: true)
        } else {
            if let data = fileManager.readDataFromFilePath(file.filePath) {
                fileManager.seriesWriteContent(data, intoHandleFile: file.filePath)
            }
        }
    }
    
    public func tableView(_ tableView: UITableView, canEditRowAt indexPath: IndexPath) -> Bool {
        return true
    }
    
    public func tableView(_ tableView: UITableView, editingStyleForRowAt indexPath: IndexPath) -> UITableViewCell.EditingStyle {
        return .delete
    }
    
    public func tableView(_ tableView: UITableView, commit editingStyle: UITableViewCell.EditingStyle, forRowAt indexPath: IndexPath) {
        let file = files[indexPath.row]
        if fileManager.deleteFileWithPath(file.filePath) {
            files.remove(at: indexPath.row)
            tv.deleteRows(at: [indexPath], with: .left)
        }
    }
}

// MARK: - URLSessionDataDelegate
extension MoreViewController: URLSessionDataDelegate {
    public func urlSession(_ session: URLSession, dataTask: URLSessionDataTask, didReceive response: URLResponse, completionHandler: @escaping (URLSession.ResponseDisposition) -> Void) {
        downloadFileName = response.suggestedFilename ?? "unknown"
        fileManager.createFileToPath(homePath, fileName: downloadFileName)
        totalLen = UInt(response.expectedContentLength)
        completionHandler(.allow)
    }
    
    public func urlSession(_ session: URLSession, dataTask: URLSessionDataTask, didReceive data: Data) {
        let filePath = (homePath as NSString).appendingPathComponent(downloadFileName)
        fileManager.seriesWriteContent(data, intoHandleFile: filePath)
        currentLen += UInt(data.count)
        let progress = Double(currentLen) / Double(totalLen)
        DispatchQueue.main.async { [weak self] in
            self?.progress?.progress = Float(progress)
        }
    }
    
    public func urlSession(_ session: URLSession, task: URLSessionTask, didCompleteWithError error: Error?) {
        getAllFile()
    }
}
