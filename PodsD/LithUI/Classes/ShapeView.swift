//
//  ShapeView.swift
//  ShapeView
//
//  Created by Cityu on 2023/5/16.
//

import UIKit

public class ShapeView: UIView {
    
    public override var layer: CAShapeLayer {
        return super.layer as! CAShapeLayer
    }
    
    var fillColor: UIColor? {
        didSet {
            layer.fillColor = resolvedColor(fillColor)?.cgColor
        }
    }
    
    var strokeColor: UIColor? {
        didSet {
            layer.strokeColor = resolvedColor(strokeColor)?.cgColor
        }
    }
    
    public override class var layerClass: AnyClass {
        return CAShapeLayer.self
    }
    
    private func resolvedColor(_ color: UIColor?) -> UIColor? {
        guard let color = color else { return nil }
        
        if #available(iOS 13.0, *) {
            return color.resolvedColor(with: traitCollection)
        }
        return color
    }
    
    public override func traitCollectionDidChange(_ previousTraitCollection: UITraitCollection?) {
        super.traitCollectionDidChange(previousTraitCollection)
        
        if #available(iOS 13.0, *) {
            if traitCollection.hasDifferentColorAppearance(comparedTo: previousTraitCollection) {
                if let fillColor = fillColor {
                    layer.fillColor = resolvedColor(fillColor)?.cgColor
                }
                if let strokeColor = strokeColor {
                    layer.strokeColor = resolvedColor(strokeColor)?.cgColor
                }
            }
        }
    }
}
