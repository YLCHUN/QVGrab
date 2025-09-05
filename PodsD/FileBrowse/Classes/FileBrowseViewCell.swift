//
//  FileBrowseViewCell.swift
//  FileBrowse
//
//  Created by Cityu on 2025/6/16.
//

import UIKit

// MARK: - FBProgressView
private class FBProgressView: UIView {
    var progress: CGFloat = 0 {
        didSet {
            setNeedsLayout()
        }
    }
    
    private let tintView = UIView()
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        setupView()
    }
    
    required init?(coder: NSCoder) {
        super.init(coder: coder)
        setupView()
    }
    
    private func setupView() {
        backgroundColor = UIColor(white: 0.9, alpha: 1)
        tintView.backgroundColor = UIColor(red: 43/255.0, green: 173/255.0, blue: 158/255.0, alpha: 1.0)
        addSubview(tintView)
        clipsToBounds = true
    }
    
    override func layoutSubviews() {
        super.layoutSubviews()
        let width = bounds.size.width * progress
        tintView.frame = CGRect(x: 0, y: 0, width: width, height: bounds.size.height)
    }
}

// MARK: - FileBrowseViewCell
public class FileBrowseViewCell: UITableViewCell {
    public var progress: CGFloat = 0 {
        didSet {
            if progress < 0 {
                progressView.isHidden = true
            } else {
                progressView.isHidden = false
                progressView.progress = progress
            }
        }
    }
    
    private let progressView = FBProgressView()
    
    public override init(style: UITableViewCell.CellStyle, reuseIdentifier: String?) {
        super.init(style: style, reuseIdentifier: reuseIdentifier)
        setupView()
    }
    
    required init?(coder: NSCoder) {
        super.init(coder: coder)
        setupView()
    }
    
    private func setupView() {
        progressView.isHidden = true
        progressView.alpha = 0.5
        backgroundView = UIView()
        backgroundColor = .clear
        addSubview(progressView)
    }
    
    public override func layoutSubviews() {
        super.layoutSubviews()
        let progressHeight: CGFloat = 2
        progressView.frame = CGRect(x: 0, 
                                  y: bounds.size.height - progressHeight, 
                                  width: bounds.size.width, 
                                  height: progressHeight)
    }
}
