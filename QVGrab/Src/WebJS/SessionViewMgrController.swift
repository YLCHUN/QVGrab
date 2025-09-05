//
//  SessionViewMgrController.swift
//  QVGrab
//
//  Created by Cityu on 2024/6/13.
//

import UIKit
import SnapKit

class SessionViewMgrController: UIViewController {
    
    var sessions: [WebViewSession] = [] {
        didSet {
            for session in sessions {
                session.previewDelegate = self
            }
        }
    }
    
    var currentSessionIndex: Int = 0
    var onSelectSession: ((Int) -> Void)?
    var onCloseSession: ((Int) -> Void)?
    var onAddNewSession: (() -> Void)?
    
    private var collectionView: UICollectionView!
    private var toolbar: UIToolbar!
    
    private let kNumberOfColumns: CGFloat = 2
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        if #available(iOS 13.0, *) {
            view.backgroundColor = UIColor.systemBackground
        } else {
            view.backgroundColor = UIColor.white
        }
        
        title = "窗口管理"
        
        setupToolbar()
        setupCollectionView()
    }
    
    private func setupToolbar() {
        toolbar = UIToolbar()
        view.addSubview(toolbar)
        toolbar.snp.makeConstraints { make in
            make.left.right.equalTo(view)
            if #available(iOS 11.0, *) {
                make.bottom.equalTo(view.safeAreaLayoutGuide.snp.bottom)
            } else {
                make.bottom.equalTo(view)
            }
            make.height.equalTo(44) // UIToolbar 标准高度
        }
        
        // 创建返回按钮
        let backButton = UIBarButtonItem(image: UIImage(named: "session_tabbar_back"), style: .plain, target: self, action: #selector(backButtonTapped))
        backButton.width = view.bounds.width / 2.0
        
        // 创建新增窗口按钮
        let addButton = UIBarButtonItem(image: UIImage(named: "session_tabbar_add"), style: .plain, target: self, action: #selector(addButtonTapped))
        addButton.width = view.bounds.width / 2.0
        
        toolbar.items = [backButton, addButton]
    }
    
    private func setupCollectionView() {
        let layout = UICollectionViewFlowLayout()
        // 调整 cell 大小以适应卡片式设计
        layout.minimumLineSpacing = 0
        layout.minimumInteritemSpacing = 0
        layout.sectionInset = UIEdgeInsets(top: kSessionViewMgrCellPadding, left: kSessionViewMgrCellPadding, bottom: kSessionViewMgrCellPadding, right: kSessionViewMgrCellPadding)
        
        collectionView = UICollectionView(frame: .zero, collectionViewLayout: layout)
        collectionView.backgroundColor = UIColor.clear
        collectionView.dataSource = self
        collectionView.delegate = self
        collectionView.register(SessionViewMgrCell.self, forCellWithReuseIdentifier: "SessionViewMgrCell")
        view.addSubview(collectionView)
        
        collectionView.snp.makeConstraints { make in
            make.top.left.right.equalTo(view)
            if #available(iOS 11.0, *) {
                make.bottom.equalTo(view.safeAreaLayoutGuide.snp.bottom).offset(-44)
            } else {
                make.bottom.equalTo(view).offset(-44)
            }
        }
    }
    
    func reload() {
        collectionView.reloadData()
    }
    
    // MARK: - Button Actions
    
    @objc private func backButtonTapped() {
        dismiss(animated: true)
    }
    
    @objc private func addButtonTapped() {
        onAddNewSession?()
    }
    
    // MARK: - Private Methods
    
    private func closeSessionAtIndex(_ index: Int) {
        guard index < sessions.count else { return }
        onCloseSession?(index)
    }
}

// MARK: - UICollectionViewDataSource

extension SessionViewMgrController: UICollectionViewDataSource {
    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        return sessions.count
    }
    
    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        let cell = collectionView.dequeueReusableCell(withReuseIdentifier: "SessionViewMgrCell", for: indexPath) as! SessionViewMgrCell
        
        let session = sessions[indexPath.item]
        cell.session = session
        cell.isCurrent = indexPath.item == currentSessionIndex
        
        // 设置关闭按钮回调
        cell.closeButtonTapped = { [weak self] in
            self?.closeSessionAtIndex(indexPath.item)
        }
        
        return cell
    }
    
    func collectionView(_ collectionView: UICollectionView, willDisplay cell: UICollectionViewCell, forItemAt indexPath: IndexPath) {
        (cell as? SessionViewMgrCell)?.previewSessionIfNeed()
    }
}

// MARK: - UICollectionViewDelegate

extension SessionViewMgrController: UICollectionViewDelegate {
    func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
        onSelectSession?(indexPath.item)
        dismiss(animated: true)
    }
}

// MARK: - UICollectionViewDelegateFlowLayout

extension SessionViewMgrController: UICollectionViewDelegateFlowLayout {
    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, sizeForItemAt indexPath: IndexPath) -> CGSize {
        let column = kNumberOfColumns
        let w = (collectionView.bounds.width - kSessionViewMgrCellPadding - kSessionViewMgrCellPadding) / column
        let h = w / 3 * 4
        return CGSize(width: w, height: h)
    }
}

// MARK: - WebViewSessionPreviewDelegate

extension SessionViewMgrController: WebViewSessionPreviewDelegate {
    func webViewSession(_ session: WebViewSession, didFinishNavigation url: String) {
        guard let index = sessions.firstIndex(of: session) else { return }
        let cell = collectionView.cellForItem(at: IndexPath(item: index, section: 0)) as? SessionViewMgrCell
        cell?.previewSessionIfNeed()
    }
}
