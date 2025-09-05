//
//  GetAlllFileInDeepSearchViewController.swift
//  FileBrowse
//
//  Created by Cityu on 2025/4/25.
//

import UIKit

public class GetAlllFileInDeepSearchViewController: UIViewController {
    private let fileManager = FileMgr.shared
    private weak var tableView: UITableView!
    private let homePath: String
    private lazy var files: [FileModel] = {
        let files = fileManager.getAllFileInPathWithDeepSearch(homePath)
        return files
    }()
    
    public init(path: String) {
        self.homePath = path
        super.init(nibName: nil, bundle: nil)
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    public override func viewDidLoad() {
        super.viewDidLoad()
        
        if !fileManager.fileExistsAtPath(homePath) {
            fileManager.createFolderToFullPath(homePath)
        }
        
        initViews()
    }
    
    private func initViews() {
        let tv = UITableView(frame: view.bounds, style: .grouped)
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
extension GetAlllFileInDeepSearchViewController: UITableViewDataSource {
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
        
        return cell!
    }
}

// MARK: - UITableViewDelegate
extension GetAlllFileInDeepSearchViewController: UITableViewDelegate {
    public func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        let file = files[indexPath.row]
        let fileDetail = FileDetailViewController(fileModel: file)
        navigationController?.pushViewController(fileDetail, animated: true)
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

