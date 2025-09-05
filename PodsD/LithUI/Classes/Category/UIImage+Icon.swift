//
//  UIImage+Icon.swift
//  LithUI
//
//  Created by Cityu on 2025/7/15.
//

import UIKit

public extension UIImage {
    
    /// 箭头图标
    /// - Parameters:
    ///   - color: 颜色
    ///   - lineWidth: 线宽
    ///   - orientation: 方向
    ///   - size: 图标大小
    ///   - padding: 内边距
    /// - Returns: 箭头图标
    static func arrowIcon(
        with color: UIColor?,
        lineWidth: CGFloat,
        orientation: UIImage.Orientation,
        size: CGSize,
        padding: UIEdgeInsets
    ) -> UIImage? {
        // 计算最终图片大小
        let imgSize = CGSize(
            width: size.width + padding.left + padding.right,
            height: size.height + padding.top + padding.bottom
        )
        
        guard imgSize.width > 0 && imgSize.height > 0 && size.width > 0 && size.height > 0 && color != nil else {
            return nil
        }
        
        // icon区域frame
        let iconRect = CGRect(
            x: padding.left,
            y: padding.top,
            width: size.width,
            height: size.height
        )
        
        UIGraphicsBeginImageContextWithOptions(imgSize, false, 0)
        guard let context = UIGraphicsGetCurrentContext() else {
            UIGraphicsEndImageContext()
            return nil
        }
        
        context.setAllowsAntialiasing(true)
        context.setShouldAntialias(true)
        
        let path = UIBezierPath()
        path.lineWidth = lineWidth
        path.lineCapStyle = .round
        path.lineJoinStyle = .round
        
        // 根据orientation分别计算三点坐标
        let (p1, p2, p3): (CGPoint, CGPoint, CGPoint)
        
        switch orientation {
        case .right:
            p1 = CGPoint(x: iconRect.origin.x, y: iconRect.origin.y)
            p2 = CGPoint(x: iconRect.origin.x + iconRect.size.width, y: iconRect.origin.y + iconRect.size.height / 2.0)
            p3 = CGPoint(x: iconRect.origin.x, y: iconRect.origin.y + iconRect.size.height)
            
        case .left:
            p1 = CGPoint(x: iconRect.origin.x + iconRect.size.width, y: iconRect.origin.y)
            p2 = CGPoint(x: iconRect.origin.x, y: iconRect.origin.y + iconRect.size.height / 2.0)
            p3 = CGPoint(x: iconRect.origin.x + iconRect.size.width, y: iconRect.origin.y + iconRect.size.height)
            
        case .up:
            p1 = CGPoint(x: iconRect.origin.x, y: iconRect.origin.y + iconRect.size.height)
            p2 = CGPoint(x: iconRect.origin.x + iconRect.size.width / 2.0, y: iconRect.origin.y)
            p3 = CGPoint(x: iconRect.origin.x + iconRect.size.width, y: iconRect.origin.y + iconRect.size.height)
            
        case .down:
            p1 = CGPoint(x: iconRect.origin.x, y: iconRect.origin.y)
            p2 = CGPoint(x: iconRect.origin.x + iconRect.size.width / 2.0, y: iconRect.origin.y + iconRect.size.height)
            p3 = CGPoint(x: iconRect.origin.x + iconRect.size.width, y: iconRect.origin.y)
            
        default:
            p1 = CGPoint(x: iconRect.origin.x, y: iconRect.origin.y)
            p2 = CGPoint(x: iconRect.origin.x + iconRect.size.width, y: iconRect.origin.y + iconRect.size.height / 2.0)
            p3 = CGPoint(x: iconRect.origin.x, y: iconRect.origin.y + iconRect.size.height)
        }
        
        path.move(to: p1)
        path.addLine(to: p2)
        path.addLine(to: p3)
        
        color?.setStroke()
        path.stroke()
        
        let image = UIGraphicsGetImageFromCurrentImageContext()
        UIGraphicsEndImageContext()
        return image
    }
    
    /// 关闭图标
    /// - Parameters:
    ///   - color: 颜色
    ///   - lineWidth: 线宽
    ///   - size: 图标大小
    ///   - padding: 内边距
    /// - Returns: 关闭图标
    static func closeIcon(
        with color: UIColor?,
        lineWidth: CGFloat,
        size: CGSize,
        padding: UIEdgeInsets
    ) -> UIImage? {
        // 计算最终图片大小
        let imgSize = CGSize(
            width: size.width + padding.left + padding.right,
            height: size.height + padding.top + padding.bottom
        )
        
        guard imgSize.width > 0 && imgSize.height > 0 && size.width > 0 && size.height > 0 && color != nil else {
            return nil
        }
        
        // icon区域frame
        let iconRect = CGRect(
            x: padding.left,
            y: padding.top,
            width: size.width,
            height: size.height
        )
        
        UIGraphicsBeginImageContextWithOptions(imgSize, false, 0)
        guard let context = UIGraphicsGetCurrentContext() else {
            UIGraphicsEndImageContext()
            return nil
        }
        
        context.setAllowsAntialiasing(true)
        context.setShouldAntialias(true)
        
        let path = UIBezierPath()
        path.lineWidth = lineWidth
        path.lineCapStyle = .round
        
        // 画X的两条对角线
        let p1 = CGPoint(x: iconRect.origin.x, y: iconRect.origin.y)
        let p2 = CGPoint(x: iconRect.origin.x + iconRect.size.width, y: iconRect.origin.y + iconRect.size.height)
        let p3 = CGPoint(x: iconRect.origin.x + iconRect.size.width, y: iconRect.origin.y)
        let p4 = CGPoint(x: iconRect.origin.x, y: iconRect.origin.y + iconRect.size.height)
        
        path.move(to: p1)
        path.addLine(to: p2)
        path.move(to: p3)
        path.addLine(to: p4)
        
        color?.setStroke()
        path.stroke()
        
        let image = UIGraphicsGetImageFromCurrentImageContext()
        UIGraphicsEndImageContext()
        return image
    }
}
