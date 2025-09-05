//
//  ProgressView.swift
//  iOS
//
//  Created by Cityu on 2025/5/16.
//  Copyright © 2025 Cityu. All rights reserved.
//

import UIKit
import LithUI


class ProgressView: UIView {
    
    var progress: Float = 0.0 { // 0.0~1.0
        didSet {
            progress = min(max(progress, 0), 1)
            setNeedsDisplay()
        }
    }
    
    var progressTintColor: UIColor = UIColor.systemBlue {
        didSet {
            setNeedsDisplay()
        }
    }
    
    override var backgroundColor: UIColor? {
        didSet {
            setNeedsDisplay()
        }
    }
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        setupUI()
    }
    
    required init?(coder: NSCoder) {
        super.init(coder: coder)
        setupUI()
    }
    
    private func setupUI() {
        backgroundColor = UIColor.clear
        progress = 0
        progressTintColor = UIColor.systemBlue
    }
    
    override func draw(_ rect: CGRect) {
        let radius = rect.size.height / 2.0
        
        // 背景
        let bgColor = UIColor.color(lightHex: "#E6E6E6", darkHex: "#1A1A1A")
        bgColor?.setFill()
        let bgPath = UIBezierPath(roundedRect: rect, cornerRadius: radius)
        bgPath.fill()
        
        // 进度
        if progress > 0 {
            var progressRect = rect
            progressRect.size.width *= CGFloat(progress)
            progressTintColor.setFill()
            let progressPath = UIBezierPath(roundedRect: progressRect, cornerRadius: radius)
            progressPath.fill()
        }
    }
}
