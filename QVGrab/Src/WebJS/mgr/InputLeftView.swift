//
//  InputLeftView.swift
//  iOS
//
//  Created by Cityu on 2025/7/25.
//  Copyright © 2025 Cityu. All rights reserved.
//

import UIKit
import LithUI
import SnapKit

class InputLeftItem: NSObject {
    var image: UIImage?
    var name: String?
    var idf: String = ""
    var url: String = ""
}

class InputLeftView: ThroughView {
    
    var items: [InputLeftItem] = [] {
        didSet {
            reloadData()
        }
    }
    
    var itemIdf: String = "" {
        didSet {
            reloadData()
        }
    }
    
    var item: InputLeftItem? {
        guard curIndex < items.count else { return nil }
        return items[curIndex]
    }
    
    var callback: ((InputLeftItem) -> Void)?
    
    private let btn = UIButton()
    private let contentView = UIView()
    private let tm = TouchMonitor()
    private let collectionView: UICollectionView
    private var curIndex: Int = NSNotFound
    
    private let kIconSide: CGFloat = 20
    
    override init(frame: CGRect) {
        let layout = UICollectionViewFlowLayout()
        layout.scrollDirection = .horizontal
        layout.minimumLineSpacing = 0
        layout.minimumInteritemSpacing = 0
        collectionView = UICollectionView(frame: .zero, collectionViewLayout: layout)
        
        super.init(frame: frame)
        customInit()
    }
    
    required init?(coder: NSCoder) {
        let layout = UICollectionViewFlowLayout()
        layout.scrollDirection = .horizontal
        layout.minimumLineSpacing = 0
        layout.minimumInteritemSpacing = 0
        collectionView = UICollectionView(frame: .zero, collectionViewLayout: layout)
        
        super.init(coder: coder)
        customInit()
    }
    
    private func customInit() {
        curIndex = NSNotFound
        
        btn.addTarget(self, action: #selector(btnAction), for: .touchUpInside)
        addSubview(btn)
        
        contentView.isHidden = true
        addSubview(contentView)
        
        collectionView.register(UICollectionViewCell.self, forCellWithReuseIdentifier: "cell")
        collectionView.delegate = self
        collectionView.dataSource = self
        contentView.addSubview(collectionView)
        
        tm.view = contentView
        tm.delegate = self
    }
    
    override func layoutSubviews() {
        super.layoutSubviews()
        btn.frame = bounds
        layoutContent()
    }
    
    private func layoutContent() {
        guard let superview = superview else { return }
        
        var frame = superview.bounds
        frame.origin.x = bounds.width
        frame.size.width -= frame.origin.x
        contentView.frame = frame
        
        frame = contentView.bounds
        frame.origin.x = 6
        frame.size.width -= frame.origin.x
        collectionView.frame = frame
    }
    
    private func showContentView() {
        contentView.isHidden = false
        btn.alpha = 0.5
        resetHideContentViewDelay()
        hideContentView(delay: true)
    }
    
    private func resetHideContentViewDelay() {
        NSObject.cancelPreviousPerformRequests(withTarget: self, selector: #selector(hideContentViewDelayed), object: nil)
    }
    
    private func hideContentView(delay: Bool) {
        resetHideContentViewDelay()
        if delay {
            perform(#selector(hideContentViewDelayed), with: nil, afterDelay: 3.0)
        } else {
            hideContentViewDelayed()
        }
    }
    
    @objc private func hideContentViewDelayed() {
        contentView.isHidden = true
        btn.alpha = 1
    }
    
    private func reloadData() {
        guard !itemIdf.isEmpty else { return }
        updateCurIdx()
        guard curIndex < items.count else { return }
        
        let item = items[curIndex]
        btn.setImage(item.image, for: .normal)
        collectionView.reloadData()
    }
    
    private func updateCurIdx() {
        var idx = 0
        for (i, item) in items.enumerated() {
            if item.idf == itemIdf {
                idx = i
                break
            }
        }
        curIndex = idx
    }
    
    private func cellItemAtIndex(_ index: Int) -> InputLeftItem {
        var actualIndex = index
        if index >= curIndex {
            actualIndex = index + 1
        }
        return items[actualIndex]
    }
    
    override func didMoveToSuperview() {
        super.didMoveToSuperview()
        
        if superview != nil {
            var frame = superview!.bounds
            let h = frame.height
            let side = kIconSide
            let left: CGFloat = 6
            let tb = (h - side) / 2.0
            frame.size.width = left + side
            self.frame = frame
            btn.imageEdgeInsets = UIEdgeInsets(top: tb, left: left, bottom: tb, right: 0)
            contentView.backgroundColor = superview!.backgroundColor
            
            // KVO观察superview的frame变化
            superview!.addObserver(self, forKeyPath: "frame", options: .new, context: nil)
        } else {
            hideContentView(delay: false)
        }
    }
    
    override func observeValue(forKeyPath keyPath: String?, of object: Any?, change: [NSKeyValueChangeKey : Any]?, context: UnsafeMutableRawPointer?) {
        if keyPath == "frame" {
            layoutContent()
        }
    }
    
    deinit {
        superview?.removeObserver(self, forKeyPath: "frame")
    }
    
    @objc private func btnAction() {
        if contentView.isHidden {
            showContentView()
        } else {
            hideContentView(delay: false)
        }
    }
}

// MARK: - TouchMonitorDelegate

extension InputLeftView: TouchMonitorDelegate {
    func touchMonitor(_ monitor: TouchMonitor, touchesBegan touches: Set<UITouch>, with event: UIEvent?) {
        resetHideContentViewDelay()
    }
    
    func touchMonitor(_ monitor: TouchMonitor, touchesCancelled touches: Set<UITouch>, with event: UIEvent?) {
        hideContentView(delay: true)
    }
    
    func touchMonitor(_ monitor: TouchMonitor, touchesEnded touches: Set<UITouch>, with event: UIEvent?) {
        hideContentView(delay: true)
    }
}

// MARK: - UICollectionViewDataSource

extension InputLeftView: UICollectionViewDataSource {
    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        return items.count - 1
    }
    
    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        let cell = collectionView.dequeueReusableCell(withReuseIdentifier: "cell", for: indexPath)
        
        var imageView = cell.contentView.viewWithTag(10011) as? UIImageView
        if imageView == nil {
            imageView = UIImageView()
            imageView!.tag = 10011
            cell.contentView.addSubview(imageView!)
            imageView!.snp.makeConstraints { make in
                make.width.height.equalTo(kIconSide)
                make.center.equalTo(cell.contentView)
            }
        }
        
        let item = cellItemAtIndex(indexPath.item)
        imageView!.image = item.image
        
        return cell
    }
}

// MARK: - UICollectionViewDelegate

extension InputLeftView: UICollectionViewDelegate {
    func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
        let item = cellItemAtIndex(indexPath.item)
        itemIdf = item.idf
        reloadData()
        hideContentView(delay: false)
        callback?(self.item!)
    }
}

// MARK: - UICollectionViewDelegateFlowLayout

extension InputLeftView: UICollectionViewDelegateFlowLayout {
    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, sizeForItemAt indexPath: IndexPath) -> CGSize {
        var size = collectionView.bounds.size
        size.width = kIconSide + 20
        return size
    }
}
