//
//  ExcelGridCollectionViewController.swift
//  iOS
//
//  Created by Cityu on 2025/7/16.
//  Copyright © 2025 Cityu. All rights reserved.
//

import UIKit
import LithUI
import SnapKit

class ExcelGridCollectionViewController: UIViewController, UICollectionViewDelegate, UICollectionViewDataSource, UIGestureRecognizerDelegate {
    private let layoutSize: (nameHeight:CGFloat, itemHeight:CGFloat, itemWidth:CGFloat) = (30, 30, 150)
    
    var names: [String] = [] {
        didSet {
            updateLayoutItemWidths()
            reloadData()
        }
    }
    
    private func updateLayoutItemWidths() {
        var itemWidths: [CGFloat] = []
        let itemWidth: CGFloat = layoutSize.itemWidth
        for _ in 0 ..< names.count {
            itemWidths.append(itemWidth)
        }
        layout.itemWidths = itemWidths
    }
    
    var datas: [[String: Any]] = [] {
        didSet {
            reloadData()
        }
    }
    
    private lazy var layout: ExcelGridCollectionLayout = {
        let layout = ExcelGridCollectionLayout()
        layout.nameHeight = layoutSize.nameHeight
        layout.itemHeight = layoutSize.itemHeight
        layout.itemWidths = [layoutSize.itemWidth]
        let lineWidth = 3.0 / UIScreen.main.scale
        layout.lineSpacing = lineWidth
        layout.interitemSpacing = lineWidth
        return layout
    }()
    
    private lazy var collectionView: UICollectionView = {
        let collectionView = UICollectionView(frame: CGRectZero, collectionViewLayout: layout)
        collectionView.register(UICollectionViewCell.self, forCellWithReuseIdentifier: "DataCell")
        collectionView.delegate = self
        collectionView.dataSource = self
        collectionView.backgroundColor = UIColor.clear
        collectionView.showsHorizontalScrollIndicator = true
        collectionView.showsVerticalScrollIndicator = true
        collectionView.alwaysBounceHorizontal = true
        
        // 长按复制
        let longPress = UILongPressGestureRecognizer(target: self, action: #selector(handleCellLongPress(_:)))
        longPress.minimumPressDuration = 0.5 // 设置长按时间
        longPress.delegate = self
        collectionView.addGestureRecognizer(longPress)
        return collectionView
    }()
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        if #available(iOS 13.0, *) {
            view.backgroundColor = UIColor.systemBackground
        } else {
            view.backgroundColor = UIColor.white
        }
        
        view.addSubview(collectionView)
        collectionView.frame = view.bounds
        collectionView.autoresizingMask = [.flexibleWidth, .flexibleHeight]
        reloadData()
    }
    
    private func reloadData() {
        // 只有在 view 已经加载后才执行 reloadData
        guard isViewLoaded else { return }
        
        if names.count > 0, datas.count > 0 {
            collectionView.reloadData()
        }
    }
    
    // MARK: - UICollectionViewDataSource
    // 2. 数据源：section=数据行数+1（含表头），item=字段数
    func numberOfSections(in collectionView: UICollectionView) -> Int {
        return datas.count + 1
    }
    
    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        return names.count
    }
    
    // header和cell内部label适配
    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        let cell = collectionView.dequeueReusableCell(withReuseIdentifier: "DataCell", for: indexPath)
        let tag = 10011
        var label = cell.contentView.viewWithTag(tag) as? UILabel
        if label == nil {
            label = UILabel(frame: cell.contentView.bounds)
            label!.tag = tag
            label!.numberOfLines = 0
            label!.lineBreakMode = .byCharWrapping
            cell.contentView.addSubview(label!)
            label!.snp.makeConstraints { make in
                make.top.left.equalTo(cell.contentView).offset(5)
                make.right.bottom.equalTo(cell.contentView).offset(-5)
            }
        }
        
        if indexPath.section == 0 { // 表头
            label!.font = UIFont.boldSystemFont(ofSize: 14)
            cell.contentView.backgroundColor = UIColor.color(lightHex: "#CCCCCC", darkHex: "#333333")
        } else { // 数据
            label!.font = UIFont.systemFont(ofSize: 12)
            cell.contentView.backgroundColor = UIColor.color(lightHex: "#F2F2F2", darkHex: "#0D0D0D")
        }
        label!.text = value(with: indexPath)
        return cell
    }
    
    private func value(with indexPath: IndexPath) -> String {
        let name = names[indexPath.item]
        if indexPath.section == 0 { // 表头
            return name
        } else { // 数据
            let data = datas[indexPath.section - 1]
            let value = data[name] ?? ""
            return "\(value)"
        }
    }
    
    // MARK: - 横向滚动同步
    func scrollViewDidScroll(_ scrollView: UIScrollView) {
        // This method is no longer needed as we only have one collectionView.
        // If you need to sync scrolling between two collectionViews, you would implement it here.
    }
    
    // MARK: - 长按复制
    // 长按复制，仅复制数据区内容
    @objc private func handleCellLongPress(_ gesture: UILongPressGestureRecognizer) {
        guard gesture.state == .began else { return }
        let point = gesture.location(in: gesture.view)
        guard let indexPath = collectionView.indexPathForItem(at: point) else {
            return
        }
        
        let value = self.value(with: indexPath)
        if !value.isEmpty {
            UIPasteboard.general.string = value
            let alert = UIAlertController(title: "已复制", message: value, preferredStyle: .alert)
            present(alert, animated: true) {
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.8) {
                    alert.dismiss(animated: true)
                }
            }
        }
    }
    
    // 适配横竖屏切换
    override func viewSafeAreaInsetsDidChange() {
        super.viewSafeAreaInsetsDidChange()
        // This method is no longer needed as we only have one collectionView.
        // If you need to adjust the frame of a single collectionView, you would implement it here.
    }
}

