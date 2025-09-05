//
//  SessionViewMgrCell.swift
//  QVGrab
//
//  Created by Cityu on 2024/6/13.
//

import UIKit
import LithUI
import Kingfisher

let kSessionViewMgrCellPadding: CGFloat = 8

class SessionViewMgrCell: UICollectionViewCell {
    
    var session: WebViewSession? {
        didSet {
            // 可以在这里添加session变化时的处理逻辑
        }
    }
    
    var isCurrent: Bool = false {
        didSet {
            backgroundView?.isHidden = !isCurrent
        }
    }
    
    var closeButtonTapped: (() -> Void)?
    
    private let titleBar = UIView()
    private let iconView = UIImageView()
    private let titleLabel = UILabel()
    private let closeButton = UIButton()
    private let previewView = UIImageView()
    private var placeholderIcon: UIImage?
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        setupUI()
    }
    
    required init?(coder: NSCoder) {
        super.init(coder: coder)
        setupUI()
    }
    
    private func setupUI() {
        // 设置 cell 背景样式
        contentView.backgroundColor = UIColor.color(lightHex: "#CCCCCC", darkHex: "#333333")
        contentView.layer.cornerRadius = 12
        contentView.layer.masksToBounds = true
        contentView.layer.borderWidth = 1.0 / UIScreen.main.scale
        contentView.chouyeBlock = { [unowned self] view in
            self.contentView.layer.borderColor = self.contentView.backgroundColor?.cgColor;
        }
 
        setupTitleBar()
        setupPreviewView()
        setupConstraints()
        setupBackgroundView()
    }
    
    override func layoutSubviews() {
        super.layoutSubviews()
        contentView.frame = bounds.insetBy(dx: kSessionViewMgrCellPadding, dy: kSessionViewMgrCellPadding)
    }
    
    private func setupTitleBar() {
        // 创建标题栏
        titleBar.backgroundColor = UIColor.color(lightHex: "#F2F2F2", darkHex: "#0D0D0D")
        contentView.addSubview(titleBar)
        
        let titleTintColor = UIColor.color(lightHex: "#333333", darkHex: "#CCCCCC")
        
        // 标题栏中的图标
        placeholderIcon = UIImage(named: "globe")
        if let titleTintColor = titleTintColor {
            placeholderIcon = placeholderIcon?.withTintColor(titleTintColor, renderingMode: .alwaysOriginal)
        }
        iconView.image = placeholderIcon
        iconView.layer.cornerRadius = 3
        iconView.layer.masksToBounds = true
        titleBar.addSubview(iconView)
        
        // 标题文本
        titleLabel.font = UIFont.boldSystemFont(ofSize: 14)
        titleLabel.textColor = titleTintColor
        titleLabel.numberOfLines = 1
        titleBar.addSubview(titleLabel)
        
        // 关闭按钮
        let image = UIImage.closeIcon(with: UIColor.black, lineWidth: 1, size: CGSize(width: 10, height: 10), padding: UIEdgeInsets(top: 5, left: 5, bottom: 5, right: 5))?.withRenderingMode(.alwaysTemplate)
        closeButton.tintColor = titleTintColor
        closeButton.setImage(image, for: .normal)
        closeButton.addTarget(self, action: #selector(closeButtonTapped(_:)), for: .touchUpInside)
        titleBar.addSubview(closeButton)
    }
    
    private func setupBackgroundView() {
        backgroundView = UIView()
        backgroundView?.layer.borderWidth = 5
        backgroundView?.layer.cornerRadius = contentView.layer.cornerRadius + kSessionViewMgrCellPadding
        backgroundView?.chouyeBlock = { [unowned self] view in
            self.backgroundView?.layer.borderColor = self.contentView.backgroundColor?.cgColor;
        }
    }
    
    private func setupPreviewView() {
        // 创建预览内容区域
        previewView.contentMode = .scaleAspectFill
        previewView.clipsToBounds = true
        contentView.addSubview(previewView)
    }
    
    private func setupConstraints() {
        // 标题栏布局
        titleBar.snp.makeConstraints { make in
            make.top.left.right.equalTo(contentView)
            make.height.equalTo(32)
        }
        
        iconView.snp.makeConstraints { make in
            make.left.equalTo(titleBar).offset(8)
            make.centerY.equalTo(titleBar)
            make.width.height.equalTo(16)
        }
        
        titleLabel.snp.makeConstraints { make in
            make.left.equalTo(iconView.snp.right).offset(8)
            make.centerY.equalTo(titleBar)
            make.right.equalTo(closeButton.snp.left).offset(-8)
        }
        
        closeButton.snp.makeConstraints { make in
            make.right.equalTo(titleBar).offset(-8)
            make.centerY.equalTo(titleBar)
            make.width.height.equalTo(20)
        }
        
        // 预览内容布局
        previewView.snp.makeConstraints { make in
            make.top.equalTo(titleBar.snp.bottom)
            make.left.right.equalTo(contentView)
            make.height.equalTo(contentView)
        }
    }
    
    @objc private func closeButtonTapped(_ sender: UIButton) {
        closeButtonTapped?()
    }
    
    override func prepareForReuse() {
        super.prepareForReuse()
        session = nil
        closeButtonTapped = nil
        updatePreviewImage(nil)
    }
    
    func previewSessionIfNeed() {
        guard let session = session else { return }
        
        titleLabel.text = !session.title.isEmpty ? session.title : session.currentURL
        
        session.getPreviewImage { [weak self] image in
            self?.updatePreviewImage(image)
        }
        
        session.getFavicon { [weak self] favicon in
            guard let favicon = favicon else { return }
            guard let faviconURL = URL(string: favicon) else { return }
            self?.iconView.kf.setImage(with: faviconURL, placeholder: self?.placeholderIcon)            
        }
    }
    
    private func updatePreviewImage(_ image: UIImage?) {
        previewView.image = image
        
        previewView.snp.remakeConstraints { make in
            make.top.equalTo(titleBar.snp.bottom)
            make.left.right.equalTo(contentView)
            
            if let image = image, image.size.width > 0 && image.size.height > 0 {
                make.height.equalTo(previewView.snp.width).multipliedBy(image.size.height / image.size.width)
            } else {
                make.height.equalTo(contentView)
            }
        }
    }
}
