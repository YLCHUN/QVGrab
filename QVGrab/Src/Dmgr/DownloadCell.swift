//
//  DownloadCell.swift
//  iOS
//
//  Created by Cityu on 2025/7/21.
//  Copyright © 2025 Cityu. All rights reserved.
//

import UIKit
import LithUI

class DownloadCell: UITableViewCell {
    
    private let titleLabel = UILabel()
    private let progressView = ProgressView()
    private let percentLabel = UILabel()
    private let speedLabel = UILabel()
    
    // 颜色属性
    private var completedColor: UIColor!
    private var downloadingColor: UIColor!
    private var pausedColor: UIColor!
    private var idleColor: UIColor!
    
    override init(style: UITableViewCell.CellStyle, reuseIdentifier: String?) {
        super.init(style: style, reuseIdentifier: reuseIdentifier)
        setupColors()
        setupUI()
    }
    
    required init?(coder: NSCoder) {
        super.init(coder: coder)
        setupColors()
        setupUI()
    }
    
    private func setupColors() {
        // 下载完成 - 柔和的薄荷绿，清新但不刺眼
        completedColor = UIColor.color(lightHex: "#4CAF50", darkHex: "#66BB6A")
        
        // 下载中 - 温和的天蓝色，科技感但不突兀
        downloadingColor = UIColor.color(lightHex: "#2196F3", darkHex: "#42A5F5")

        // 暂停中 - 温暖的珊瑚橙，提醒但不刺眼
        pausedColor = UIColor.color(lightHex: "#FF7043", darkHex: "#FF8A65")

        // 未开始 - 柔和的银灰色，中性且优雅
        idleColor = UIColor.color(lightHex: "#9E9E9E", darkHex: "#BDBDBD")

    }
    
    private func setupUI() {
        titleLabel.font = UIFont.systemFont(ofSize: 16)
        titleLabel.numberOfLines = 2
        contentView.addSubview(titleLabel)
        
        percentLabel.font = UIFont.systemFont(ofSize: 16)
        percentLabel.textAlignment = .right
        percentLabel.textColor = titleLabel.textColor
        contentView.addSubview(percentLabel)
        
        speedLabel.font = UIFont.systemFont(ofSize: 16)
        speedLabel.textAlignment = .right
        speedLabel.textColor = titleLabel.textColor
        contentView.addSubview(speedLabel)
        
        contentView.addSubview(progressView)
    }
    
    override func layoutSubviews() {
        super.layoutSubviews()
        
        let padding: CGFloat = 15
        let contentWidth = contentView.bounds.size.width
        let contentHeight = contentView.bounds.size.height
        let progressHeight: CGFloat = 1
        
        // 计算speedLabel和percentLabel需要的宽度
        let speedWidth = calculateSpeedLabelWidth()
        let percentWidth = calculatePercentLabelWidth()
        
        // progressView 靠底
        progressView.frame = CGRect(x: padding, y: contentHeight - progressHeight, width: contentWidth - padding, height: progressHeight)
        
        // 百分比label靠右，垂直居中
        percentLabel.frame = CGRect(x: contentWidth - padding - percentWidth, y: 0, width: percentWidth, height: contentHeight)
        
        // 速度label在百分比label左边
        speedLabel.frame = CGRect(x: contentWidth - padding - percentWidth - speedWidth, y: 0, width: speedWidth, height: contentHeight)
        
        // titleLabel 垂直居中，右侧为speedLabel
        titleLabel.frame = CGRect(x: padding, y: 0, width: contentWidth - padding * 2 - percentWidth - speedWidth, height: contentHeight)
    }
    
    private func calculateSpeedLabelWidth() -> CGFloat {
        // 获取当前速度文本
        let speedText = speedLabel.text ?? "0 B/s"
        
        // 计算文本宽度
        let size = speedText.size(withAttributes: [.font: speedLabel.font!])
        
        // 添加一些额外的padding，确保文本不会太贴近边缘
        let extraPadding: CGFloat = 8
        return ceil(size.width) + extraPadding
    }
    
    private func calculatePercentLabelWidth() -> CGFloat {
        // 获取当前百分比文本
        let percentText = percentLabel.text ?? "0.0%"
        
        // 计算文本宽度
        let size = percentText.size(withAttributes: [.font: percentLabel.font!])
        
        // 添加一些额外的padding，确保文本不会太贴近边缘
        let extraPadding: CGFloat = 8
        return ceil(size.width) + extraPadding
    }
    
    private func formatSpeed(_ speed: UInt) -> String {
        if speed == 0 {
            return "0 B/s"
        }
        
        var unit = "B/s"
        var format = "%.1f %@"
        var speedf = CGFloat(speed)
        
        if speedf >= 1024 * 1024 * 1024 {
            speedf = speedf / (1024 * 1024 * 1024)
            unit = "GB/s"
        } else if speedf >= 1024 * 1024 {
            speedf = speedf / (1024 * 1024)
            unit = "MB/s"
        } else if speedf >= 1024 {
            speedf = speedf / 1024
            unit = "KB/s"
        }
        
        // 如果整数部分超过2位数，不显示小数位
        if speedf >= 100 {
            format = "%.0f %@"
        }
        
        return String(format: format, speedf, unit)
    }
    
    func configureWithModel(_ model: DProgressModel?, isDownloading: Bool) {
        titleLabel.text = model?.name ?? ""
        progressView.progress = model?.progress ?? 0
        
        // 百分比显示，保留1位小数
        let percent = (model?.progress ?? 0) * 100.0
        percentLabel.text = String(format: "%.1f%%", percent)
        
        // 更新下载速度
        speedLabel.text = formatSpeed(model?.speed ?? 0)
        
        // 更新布局以适应新的文本
        setNeedsLayout()
        
        updateColorsWithModel(model, isDownloading: isDownloading)
    }
    
    private func updateColorsWithModel(_ model: DProgressModel?, isDownloading: Bool) {
        if model?.progress ?? 0 >= 1.0 { // 下载完成
            titleLabel.textColor = completedColor
            percentLabel.textColor = completedColor
            speedLabel.textColor = completedColor
            progressView.progressTintColor = completedColor
        } else if isDownloading { // 下载中
            titleLabel.textColor = downloadingColor
            percentLabel.textColor = downloadingColor
            speedLabel.textColor = downloadingColor
            progressView.progressTintColor = downloadingColor
        } else if model?.progress ?? 0 > 0 { // 暂停中
            titleLabel.textColor = pausedColor
            percentLabel.textColor = pausedColor
            speedLabel.textColor = pausedColor
            progressView.progressTintColor = pausedColor
        } else { // 未开始下载
            titleLabel.textColor = idleColor
            percentLabel.textColor = idleColor
            speedLabel.textColor = idleColor
            progressView.progressTintColor = idleColor
        }
    }
    
    override func traitCollectionDidChange(_ previousTraitCollection: UITraitCollection?) {
        super.traitCollectionDidChange(previousTraitCollection)
        
        // 当用户界面样式改变时（如切换暗黑模式），重新设置颜色
        if #available(iOS 13.0, *) {
            if traitCollection.userInterfaceStyle != previousTraitCollection?.userInterfaceStyle {
                // 重新设置颜色以适配新的主题
                setupColors()
                
                // 如果有当前模型，重新应用颜色
                if titleLabel.text != nil {
                    // 这里需要外部传入当前状态，暂时先重新设置一次
                    // 实际使用时，建议在外部调用configureWithModel时传入当前状态
                }
            }
        }
    }
}
