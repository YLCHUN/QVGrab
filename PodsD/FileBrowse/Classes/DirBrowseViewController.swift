//
//  DirBrowseViewController.swift
//  FileBrowse
//
//  Created by Cityu on 2025/5/13.
//  Copyright © 2025 Cityu. All rights reserved.
//

import UIKit

open class DirBrowseViewController: UIViewController {
    private let fileManager = FileMgr.shared
    private weak var tableView: UITableView!
    private let dirPaths: [String]
    private var files: [FileModel] = []
    
    public init(paths: [String]) {
        self.dirPaths = paths
        super.init(nibName: nil, bundle: nil)
    }
    
    required public init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    open override func viewDidLoad() {
        super.viewDidLoad()
        
        title = "FileB"
        
        var files: [FileModel] = []
        for path in dirPaths {
            if !fileManager.fileExistsAtPath(path) {
                fileManager.createFolderToFullPath(path)
            }
            let file = FileModel(filePath: path)
            files.append(file)
        }
        
        self.files = files
        initViews()
    }
    
    public override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
    }
    
    public override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
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
    }
    
    public override var supportedInterfaceOrientations: UIInterfaceOrientationMask {
        return .portrait
    }
}

// MARK: - UITableViewDataSource
extension DirBrowseViewController: UITableViewDataSource {
    public func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return files.count
    }
    
    public func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        var cell = tableView.dequeueReusableCell(withIdentifier: "cell") as? FileBrowseViewCell
        if cell == nil {
            cell = FileBrowseViewCell(style: .subtitle, reuseIdentifier: "cell")
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
extension DirBrowseViewController: UITableViewDelegate {
    public func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        tableView.deselectRow(at: indexPath, animated: true)
        
        let file = files[indexPath.row]
        if file.isDir {
            let vc = FileBrowseViewController(path: file.filePath)
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
