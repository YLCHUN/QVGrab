//
//  ChouyeImage.swift
//  Chouye
//
//  Created by YLCHUN on 2020/8/30.
//  Copyright © 2020 YLCHUN. All rights reserved.
//

import UIKit

public extension UIImage {
    /// 构造动态 image
    /// - Parameter chouyeProvider: 动态提供图片, style 对应 image 已经存在时不再执行
    /// - Returns: 动态图片
    @available(iOS 13.0, *)
    static func image(chouyeProvider: @escaping (UIUserInterfaceStyle) -> UIImage) -> UIImage? {
        let asset = ChouyeAsset(chouyeProvider)
        return asset.resolvedImage(with: UITraitCollection.current.userInterfaceStyle)
    }
    
    /// 构造动态 image
    /// - Parameters:
    ///   - light: lightImage
    ///   - dark: darkImage
    /// - Returns: 动态图片
    static func chouye(light: UIImage?, dark: UIImage?) -> UIImage? {
        guard let dark = dark else { return light }
        guard let light = light else { return dark }
        
        if #available(iOS 13.0, *) {
            return image { style in
                return style == .dark ? dark : light
            }
        } else {
            return light
        }
    }
    
    /// 获取自身原始图片
    /// - Returns: 原始图片
    var chouyeRaw: UIImage? {
        if #available(iOS 13.0, *) {
            return ChouyeAsset.rawImage(from: self)
        } else {
            return self
        }
    }
    
    /// 是否为动态提供者图片
    /// - Returns: 是否为动态图片
    var isChouye: Bool {
        if #available(iOS 13.0, *) {
            return ChouyeAsset.isChouye(self)
        } else {
            return false
        }
    }
}
