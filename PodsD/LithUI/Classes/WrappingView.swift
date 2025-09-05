//
//  WrappingView.swift
//  WrappingView
//
//  Created by Cityu on 2024/7/10.
//

import UIKit

protocol WrappingViewDelegate: AnyObject {
    func wrappingView(_ wrappingView: WrappingView, didSetView view: UIView?)
}

public class WrappingView: UIView {
    
    weak var delegate: WrappingViewDelegate?
    public var view: UIView? {
        get { return contentView.view }
        set { contentView.view = newValue }
    }
    
    public var rectCorner: UIRectCorner = [] {
        didSet {
            contentMaskView.rectCorner = rectCorner
        }
    }
    
    public var cornerRadius: CGFloat = 0 {
        didSet {
            contentMaskView.cornerRadius = cornerRadius
        }
    }
    
    private let contentView: _WrappingContentView
    private let contentMaskView: _WrappingMaskView
    
    public override init(frame: CGRect) {
        contentView = _WrappingContentView()
        contentMaskView = _WrappingMaskView()
        super.init(frame: frame)
        setupViews()
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    
    private func setupViews() {
        backgroundColor = .clear
        contentView.delegate = self
        contentMaskView.fillColor = .black
        contentMaskView.rectCorner = rectCorner
        contentMaskView.cornerRadius = cornerRadius
        
        addSubview(contentView)
        contentView.mask = contentMaskView
    }
    
    public override func layoutSubviews() {
        super.layoutSubviews()
        let bounds = self.bounds
        contentView.frame = bounds
        contentMaskView.frame = bounds
    }
    
    public override var backgroundColor: UIColor? {
        get { return contentView.backgroundColor }
        set { contentView.backgroundColor = newValue }
    }
}

// MARK: - _WrappingContentViewDelegate
extension WrappingView: _WrappingContentViewDelegate {
    fileprivate func wrappingView(_ wrappingView: _WrappingContentView, didSetView view: UIView?) {
        delegate?.wrappingView(self, didSetView: view)
    }
}

// MARK: - Private Classes

private protocol _WrappingContentViewDelegate: AnyObject {
     func wrappingView(_ wrappingView: _WrappingContentView, didSetView view: UIView?)
}

private class _WrappingContentView: UIView {
    
    weak var delegate: _WrappingContentViewDelegate?
    var view: UIView? {
        didSet {
            if oldValue == view { return }
            
            oldValue?.removeFromSuperview()
            
            if let view = view {
                addSubview(view)
                view.frame = bounds
            }
        }
    }
    
    override func layoutSubviews() {
        super.layoutSubviews()
        view?.frame = bounds
    }
    
    override func didAddSubview(_ subview: UIView) {
        super.didAddSubview(subview)
        if subview == view {
            delegate?.wrappingView(self, didSetView: view)
        }
    }
    
    override func willRemoveSubview(_ subview: UIView) {
        super.willRemoveSubview(subview)
        if subview == view {
            view = nil
            delegate?.wrappingView(self, didSetView: nil)
        }
    }
}

private class _WrappingMaskView: ShapeView {
    
    var rectCorner: UIRectCorner = [] {
        didSet {
            setNeedsLayout()
        }
    }
    
    var cornerRadius: CGFloat = 0 {
        didSet {
            setNeedsLayout()
        }
    }
    
    override func layoutSubviews() {
        super.layoutSubviews()
        updateCorner()
    }
    
    private func updateCorner() {
        let rect = bounds
        let path = UIBezierPath(
            roundedRect: rect,
            byRoundingCorners: rectCorner,
            cornerRadii: CGSize(width: cornerRadius, height: cornerRadius)
        )
        layer.path = path.cgPath
    }
}
