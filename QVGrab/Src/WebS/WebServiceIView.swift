//
//  WebServiceIView.swift
//  iOS
//
//  Created by Cityu on 2025/6/4.
//  Copyright © 2025 Cityu. All rights reserved.
//

import UIKit


protocol WebServiceIViewDelegate: AnyObject {
    func webServiceIView(_ view: WebServiceIView, openSwitch open: Bool)
}

class WebServiceIView: UIView {
    
    weak var delegate: WebServiceIViewDelegate?
    var open: Bool = false {
        didSet {
            openSwitch.isOn = open
            statusLabel.text = open ? "状态: 运行中" : "状态: 已停止"
            updateUrlLabel()
        }
    }
    
    var title: String = "" {
        didSet {
            titleLabel.text = title
        }
    }
    
    var url: String = "" {
        didSet {
            updateUrlLabel()
        }
    }
    
    private let titleLabel = UILabel()
    private let statusLabel = UILabel()
    private let openSwitch = UISwitch()
    private let urlLabel = UILabel()
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        setupUI()
    }
    
    required init?(coder: NSCoder) {
        super.init(coder: coder)
        setupUI()
    }
    
    private func setupUI() {
        backgroundColor = UIColor.secondarySystemBackground
        layer.cornerRadius = 10
        
        // 标题标签
        titleLabel.font = UIFont.boldSystemFont(ofSize: 18)
        addSubview(titleLabel)
        
        // 状态标签
        statusLabel.font = UIFont.systemFont(ofSize: 14)
        addSubview(statusLabel)
        
        // 开关
        openSwitch.addTarget(self, action: #selector(switchChanged(_:)), for: .valueChanged)
        addSubview(openSwitch)
        
        // URL标签
        urlLabel.font = UIFont.systemFont(ofSize: 14)
        urlLabel.textColor = UIColor.systemBlue
        addSubview(urlLabel)
        
        updateLayout()
        
        open = false
    }
    
    private func updateLayout() {
        let padding: CGFloat = 15
        let switchWidth: CGFloat = 51
        let switchHeight: CGFloat = 31
        
        // 设置标题标签
        titleLabel.frame = CGRect(x: padding, y: padding, width: bounds.size.width - padding * 3 - switchWidth, height: 24)
        
        // 设置开关
        openSwitch.frame = CGRect(x: bounds.size.width - padding - switchWidth, y: padding, width: switchWidth, height: switchHeight)
        
        // 设置状态标签
        statusLabel.frame = CGRect(x: padding, y: titleLabel.frame.maxY + 6, width: bounds.size.width - padding * 2, height: 20)
        
        // 设置URL标签
        urlLabel.frame = CGRect(x: padding, y: statusLabel.frame.maxY + 6, width: bounds.size.width - padding * 2, height: 20)
    }
    
    override func layoutSubviews() {
        super.layoutSubviews()
        updateLayout()
    }
    
    private func updateUrlLabel() {
        urlLabel.text = "URL: \(open ? (url.isEmpty ? "" : url) : "未启动")"
    }
    
    @objc private func switchChanged(_ sender: UISwitch) {
        delegate?.webServiceIView(self, openSwitch: sender.isOn)
    }
}
