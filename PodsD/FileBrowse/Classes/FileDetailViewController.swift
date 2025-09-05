//
//  FileDetailViewController.swift
//  FileBrowse
//
//  Created by Cityu on 2025/4/25.
//

import UIKit
import QuickLook

public class FileDetailViewController: UIViewController {
    private let file: FileModel
    private var documentInteraction: UIDocumentInteractionController?
    
    public init(fileModel: FileModel) {
        self.file = fileModel
        super.init(nibName: nil, bundle: nil)
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    public override func viewDidLoad() {
        super.viewDidLoad()
        setupUI()
    }
    
    private func setupUI() {
        navigationItem.title = "文件详情"
        view.backgroundColor = .white
        
        let url = URL(fileURLWithPath: file.filePath)
        documentInteraction = UIDocumentInteractionController(url: url)
        documentInteraction?.delegate = self
        
        let remindView = UIView(frame: view.bounds)
        remindView.backgroundColor = UIColor(red: 247/255.0, green: 247/255.0, blue: 247/255.0, alpha: 1.0)
        remindView.isHidden = true
        view.addSubview(remindView)
        
        let label = UILabel(frame: CGRect(x: 0, y: view.bounds.size.height * 0.4, width: view.bounds.size.width, height: 60))
        label.numberOfLines = 0
        label.font = UIFont.systemFont(ofSize: 18)
        label.textAlignment = .center
        label.text = "文件暂不支持本地打开\n请用其他应用打开"
        label.textColor = UIColor(red: 47/255.0, green: 47/255.0, blue: 47/255.0, alpha: 1.0)
        remindView.addSubview(label)
        
        let button = UIButton()
        button.setTitleColor(.white, for: .normal)
        button.setTitle("用其他应用打开", for: .normal)
        button.frame = CGRect(x: (view.bounds.size.width - 200) / 2, y: view.bounds.size.height * 0.55, width: 200, height: 45)
        button.titleLabel?.font = UIFont.systemFont(ofSize: 18)
        button.layer.cornerRadius = 5
        button.backgroundColor = UIColor(red: 43/255.0, green: 173/255.0, blue: 158/255.0, alpha: 1.0)
        button.addTarget(self, action: #selector(openInOtherApp), for: .touchUpInside)
        remindView.addSubview(button)
        
        let canOpen = documentInteraction?.presentPreview(animated: false) ?? false
        if !canOpen {
            remindView.isHidden = false
        }
    }
    
    @objc private func openInOtherApp() {
        let url = URL(fileURLWithPath: file.filePath)
        documentInteraction = UIDocumentInteractionController(url: url)
        documentInteraction?.delegate = self
        
        let canOpen = documentInteraction?.presentOpenInMenu(from: .zero, in: view, animated: true) ?? false
        if !canOpen {
            // Handle error
        }
    }
}

// MARK: - UIDocumentInteractionControllerDelegate
extension FileDetailViewController: UIDocumentInteractionControllerDelegate {
    public func documentInteractionControllerViewControllerForPreview(_ controller: UIDocumentInteractionController) -> UIViewController {
        return self
    }
    
    public func documentInteractionControllerViewForPreview(_ controller: UIDocumentInteractionController) -> UIView? {
        return view
    }
    
    public func documentInteractionControllerRectForPreview(_ controller: UIDocumentInteractionController) -> CGRect {
        return view.bounds
    }
    
    public func documentInteractionControllerDidEndPreview(_ controller: UIDocumentInteractionController) {
        navigationController?.popViewController(animated: true)
    }
}
