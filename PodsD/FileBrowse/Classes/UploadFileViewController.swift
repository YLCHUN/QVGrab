//
//  UploadFileViewController.swift
//  FileBrowse
//
//  Created by Cityu on 2025/4/25.
//

import UIKit

public typealias UploadFileBlock = ([FileModel]) -> Void

// MARK: - SelectedFileManager
private class SelectedFileManager: NSObject {
    static let shared = SelectedFileManager()
    
    var selectedFileArray: [FileModel] = []
    var maxCount: Int = 0
    
    var selectedFileCount: Int {
        return selectedFileArray.count
    }
    
    private override init() {
        super.init()
    }
    
    @discardableResult
    func addFile(_ file: FileModel) -> Bool {
        if isFileContain(file) {
            return false
        } else {
            selectedFileArray.append(file)
            return true
        }
    }
    
    @discardableResult
    func removeFile(_ file: FileModel) -> Bool {
        for (index, aFile) in selectedFileArray.enumerated() {
            if aFile.filePath == file.filePath {
                selectedFileArray.remove(at: index)
                return true
            }
        }
        return false
    }
    
    func isFileContain(_ file: FileModel) -> Bool {
        return selectedFileArray.contains { $0.filePath == file.filePath }
    }
    
    func isFull() -> Bool {
        return selectedFileArray.count >= maxCount
    }
    
    func emptySelectedArray() {
        selectedFileArray.removeAll()
    }
}

// MARK: - UploadFileViewController
public class UploadFileViewController: UIViewController {
    private let uploadBlock: UploadFileBlock?
    private let maxCount: Int
    private let fileManager = FileMgr.shared
    private weak var tableView: UITableView!
    private let homePath: String
    private lazy var files: [FileModel] = {
        let files = fileManager.getAllFileWithPath(homePath)
        return files
    }()
    
    private weak var uploadBtn: UIButton!
    
    public init(path: String, maxCount: Int, uploadBlock: @escaping UploadFileBlock) {
        self.homePath = path
        self.maxCount = maxCount
        self.uploadBlock = uploadBlock
        super.init(nibName: nil, bundle: nil)
        
        if SelectedFileManager.shared.maxCount == 0 {
            SelectedFileManager.shared.maxCount = maxCount
        }
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    public override func viewDidLoad() {
        super.viewDidLoad()
        
        if !fileManager.fileExistsAtPath(homePath) {
            fileManager.createFolderToFullPath(homePath)
        }
        
        let folder = fileManager.getFileWithPath(homePath)
        title = folder.name
        
        initViews()
    }
    
    private func initViews() {
        navigationItem.rightBarButtonItem = UIBarButtonItem(title: "取消", style: .done, target: self, action: #selector(cancel))
        
        let tv = UITableView(frame: CGRect(x: 0, y: 0, width: view.bounds.size.width, height: view.bounds.size.height - 50), style: .grouped)
        tv.delegate = self
        tv.dataSource = self
        view.addSubview(tv)
        tableView = tv
        
        // 添加上传按钮
        let uploadBtn = UIButton()
        uploadBtn.frame = CGRect(x: 0, y: view.bounds.size.height - 50, width: view.bounds.size.width, height: 50)
        uploadBtn.backgroundColor = UIColor(red: 43/255.0, green: 173/255.0, blue: 158/255.0, alpha: 1.0)
        uploadBtn.setTitle("上  传", for: .normal)
        uploadBtn.setTitleColor(.white, for: .normal)
        uploadBtn.titleLabel?.font = UIFont.boldSystemFont(ofSize: 19)
        uploadBtn.addTarget(self, action: #selector(uploadBtnDidClick(_:)), for: .touchUpInside)
        view.addSubview(uploadBtn)
        self.uploadBtn = uploadBtn
        
        reloadUploadBtnStr()
    }
    
    private func alertWithString(_ str: String) {
        let alertC = UIAlertController(title: "温馨提示", message: str, preferredStyle: .alert)
        let action = UIAlertAction(title: "确定", style: .default)
        alertC.addAction(action)
        present(alertC, animated: true)
    }
    
    @objc private func uploadBtnDidClick(_ sender: UIButton) {
        let selectedFileArray = SelectedFileManager.shared.selectedFileArray
        uploadBlock?(selectedFileArray)
        SelectedFileManager.shared.emptySelectedArray()
        dismiss(animated: true)
    }
    
    private func reloadUploadBtnStr() {
        let selectedCount = SelectedFileManager.shared.selectedFileCount
        if selectedCount == 0 {
            uploadBtn.setTitle("上传", for: .normal)
            uploadBtn.backgroundColor = .gray
            uploadBtn.isEnabled = false
        } else {
            uploadBtn.setTitle("上传(\(selectedCount))", for: .normal)
            uploadBtn.backgroundColor = UIColor(red: 43/255.0, green: 173/255.0, blue: 158/255.0, alpha: 1.0)
            uploadBtn.isEnabled = true
        }
    }
    
    @objc private func seleteBtnDidClick(_ sender: UIButton) {
        let index = sender.tag % 1000
        let file = files[index]
        
        if sender.isSelected {
            SelectedFileManager.shared.removeFile(file)
        } else {
            if SelectedFileManager.shared.isFull() {
                alertWithString("最多只能选择\(SelectedFileManager.shared.maxCount)个文件")
                return
            }
            SelectedFileManager.shared.addFile(file)
        }
        
        reloadUploadBtnStr()
        sender.isSelected.toggle()
    }
    
    @objc private func cancel() {
        dismiss(animated: true)
    }
    
    public override var supportedInterfaceOrientations: UIInterfaceOrientationMask {
        return .portrait
    }
}

// MARK: - UITableViewDataSource
extension UploadFileViewController: UITableViewDataSource {
    public func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return files.count
    }
    
    public func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        var cell = tableView.dequeueReusableCell(withIdentifier: "cell")
        if cell == nil {
            cell = UITableViewCell(style: .subtitle, reuseIdentifier: "cell")
        }
        
        let file = files[indexPath.row]
        cell?.textLabel?.text = file.name
        cell?.accessoryType = .disclosureIndicator
        cell?.detailTextLabel?.text = file.fileModelDesc()
        cell?.imageView?.image = UIImage.imageWithExtension(file.fileExtension)
        
        if !file.isDir {
            // 选择按钮
            let selectBtn = UIButton()
            selectBtn.tag = 1000 + indexPath.row
            selectBtn.setImage(UIImage(named: "filemanager_cell_unselected"), for: .normal)
            selectBtn.setImage(UIImage(named: "filemanager_cell_selected"), for: .selected)
            selectBtn.frame = CGRect(x: 0, y: 0, width: 40, height: 40)
            selectBtn.addTarget(self, action: #selector(seleteBtnDidClick(_:)), for: .touchUpInside)
            cell?.accessoryView = selectBtn
            selectBtn.isSelected = SelectedFileManager.shared.isFileContain(file)
        }
        
        // 设置cell图片大小
        let imageSize = CGSize(width: 40, height: 40)
        UIGraphicsBeginImageContextWithOptions(imageSize, false, 0.0)
        let imageRect = CGRect(x: 0.0, y: 0.0, width: imageSize.width, height: imageSize.height)
        cell?.imageView?.image?.draw(in: imageRect)
        cell?.imageView?.image = UIGraphicsGetImageFromCurrentImageContext()
        UIGraphicsEndImageContext()
        
        return cell!
    }
}

// MARK: - UITableViewDelegate
extension UploadFileViewController: UITableViewDelegate {
    public func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        let file = files[indexPath.row]
        if file.isDir {
            let vc = UploadFileViewController(path: file.filePath, 
                                           maxCount: SelectedFileManager.shared.maxCount - SelectedFileManager.shared.selectedFileCount, 
                                           uploadBlock: uploadBlock!)
            navigationController?.pushViewController(vc, animated: true)
        } else {
            let fileDetail = FileDetailViewController(fileModel: file)
            navigationController?.pushViewController(fileDetail, animated: true)
        }
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
}

