//
//  ThroughView.swift
//  ThroughView
//
//  Created by Cityu on 2022/5/17.
//
//  subviews 之外区域事件穿透

import UIKit

open class ThroughView: UIView {
    
    public override func point(inside point: CGPoint, with event: UIEvent?) -> Bool {
        return throughPointInside(point, with: event)
    }
}

// MARK: - UIView Extension
public extension UIView {
    
    func throughPointInside(_ point: CGPoint, with event: UIEvent?) -> Bool {
        return throughPointInside(point, with: event, clipsToBounds: clipsToBounds)
    }
    
    func throughPointInside(_ point: CGPoint, with event: UIEvent?, clipsToBounds: Bool) -> Bool {
        var b = false
        if !clipsToBounds || bounds.contains(point) {
            let subviews = self.subviews
            for i in stride(from: subviews.count - 1, through: 0, by: -1) {
                let v = subviews[i]
                if v.isUserInteractionEnabled && !v.isHidden && v.alpha > 0 {
                    let p = convert(point, to: v)
                    if v.point(inside: p, with: event) {
                        b = true
                        break
                    }
                }
            }
        }
        return b
    }
}
