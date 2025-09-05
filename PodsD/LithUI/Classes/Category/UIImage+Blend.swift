//
//  UIImage+Blend.swift
//  LithUI
//
//  Created by Cityu on 2025/7/15.
//

import UIKit
import Chouye

public extension UIImage {
    
    /// 图片着色
    /// - Parameter color: 颜色
    /// - Returns: 着色后的图片
    func imageWithBlendColor(_ color: UIColor?) -> UIImage? {
        guard let color = color else { return self }
        
        let blendBlock: (UIColor?) -> UIImage? = { [weak self] color in
            guard let self = self, let color = color else { return self }
            
            let block: (UIImage, UIColor) -> UIImage? = { image, color in
                return UIImage.imageByRendering(
                    size: image.size,
                    opaque: false,
                    scale: image.scale
                ) { context in
                    guard let context = context else { return }
                    
                    context.translateBy(x: 0, y: image.size.height)
                    context.scaleBy(x: 1.0, y: -1.0)
                    context.setBlendMode(.normal)
                    
                    let rect = CGRect(x: 0, y: 0, width: image.size.width, height: image.size.height)
                    context.clip(to: rect, mask: image.cgImage!)
                    color.setFill()
                    context.fill(rect)
                }
            }
            
            if let images = self.images, images.count > 0 {
                let arr = images.compactMap { block($0, color) }
                return UIImage.animatedImage(with: arr, duration: self.duration)
            } else {
                return block(self, color)
            }
        }
        
        var image: UIImage?
        
        if #available(iOS 13.0, *) {
            let lightColor = color.resolvedColor(with: UITraitCollection(userInterfaceStyle: .light))
            let darkColor = color.resolvedColor(with: UITraitCollection(userInterfaceStyle: .dark))
            let light = blendBlock(lightColor)?.withRenderingMode(.alwaysOriginal)
            let dark = blendBlock(darkColor)?.withRenderingMode(.alwaysOriginal)
            image = UIImage.chouye(light: light, dark: dark)
        } else {
            image = blendBlock(color)?.withRenderingMode(.alwaysOriginal)
        }
        
        return image
    }
    
    /// 通过自定义绘制生成图片
    /// - Parameters:
    ///   - size: 图片尺寸
    ///   - opaque: 是否不透明
    ///   - scale: 缩放比例
    ///   - actions: 绘制 block
    /// - Returns: 生成的图片
    static func imageByRendering(
        size: CGSize,
        opaque: Bool,
        scale: CGFloat,
        actions: @escaping (CGContext?) -> Void
    ) -> UIImage? {
        guard size.width > 0 && size.height > 0 else { return nil }
        
        if #available(iOS 17.0, *) {
            let format = UIGraphicsImageRendererFormat()
            format.opaque = opaque
            format.scale = scale
            
            let renderer = UIGraphicsImageRenderer(size: size, format: format)
            return renderer.image { rendererContext in
                actions(rendererContext.cgContext)
            }
        } else {
            UIGraphicsBeginImageContextWithOptions(size, opaque, scale)
            actions(UIGraphicsGetCurrentContext())
            let image = UIGraphicsGetImageFromCurrentImageContext()
            UIGraphicsEndImageContext()
            return image
        }
    }
}
