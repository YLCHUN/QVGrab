//
//  UIColor+Hex.swift
//  LithUI
//
//  Created by Cityu on 2025/7/15.
//

import UIKit

public extension UIColor {
    
    /// 16进制颜色转换
    /// - Parameter hex: 16进制颜色字符串 #RRGGBB 或 #RRGGBBAA
    /// - Returns: UIColor对象
    static func color(hex: String) -> UIColor? {
        // 去除字符串中的#和空格，并转为大写
        var cleanHex = hex.trimmingCharacters(in: .whitespacesAndNewlines).uppercased()
        if cleanHex.hasPrefix("#") {
            cleanHex = String(cleanHex.dropFirst())
        }
        
        let length = cleanHex.count
        // 只支持6位(RGB)或8位(RGBA)十六进制
        guard length == 6 || length == 8 else { return nil }
        
        var r: UInt32 = 0, g: UInt32 = 0, b: UInt32 = 0, a: UInt32 = 255
        
        // 解析RGB
        let rRange = cleanHex.startIndex..<cleanHex.index(cleanHex.startIndex, offsetBy: 2)
        let gRange = cleanHex.index(cleanHex.startIndex, offsetBy: 2)..<cleanHex.index(cleanHex.startIndex, offsetBy: 4)
        let bRange = cleanHex.index(cleanHex.startIndex, offsetBy: 4)..<cleanHex.index(cleanHex.startIndex, offsetBy: 6)
        
        Scanner(string: String(cleanHex[rRange])).scanHexInt32(&r)
        Scanner(string: String(cleanHex[gRange])).scanHexInt32(&g)
        Scanner(string: String(cleanHex[bRange])).scanHexInt32(&b)
        
        // 解析A
        if length == 8 {
            let aRange = cleanHex.index(cleanHex.startIndex, offsetBy: 6)..<cleanHex.index(cleanHex.startIndex, offsetBy: 8)
            Scanner(string: String(cleanHex[aRange])).scanHexInt32(&a)
        }
        
        // 转为CGFloat并归一化
        let rf = CGFloat(r) / 255.0
        let gf = CGFloat(g) / 255.0
        let bf = CGFloat(b) / 255.0
        let af = CGFloat(a) / 255.0
        
        return UIColor(red: rf, green: gf, blue: bf, alpha: af)
    }
    
    /// 动态颜色转换
    /// - Parameters:
    ///   - light: 浅色
    ///   - dark: 深色
    /// - Returns: UIColor对象
    static func color(light: UIColor?, dark: UIColor?) -> UIColor? {
        // 判断系统版本，iOS 13及以上支持动态色
        if #available(iOS 13.0, *) {
            if (light == nil) && (dark == nil) { return nil }
            // 使用动态颜色，自动适配浅色/深色模式
            return UIColor { traitCollection in
                if traitCollection.userInterfaceStyle == .dark {
                    return dark ?? light!
                } else {
                    return light ?? dark!
                }
            }
        } else {
            // iOS 13以下只返回浅色
            return light
        }
    }
    
    /// 动态颜色转换
    /// - Parameters:
    ///   - lightHex: 浅色16进制
    ///   - darkHex: 深色16进制
    /// - Returns: UIColor对象
    static func color(lightHex: String, darkHex: String) -> UIColor? {
        let light = color(hex:lightHex)
        let dark = color(hex:darkHex)
        return color(light: light, dark: dark)
    }
    
    /// 获取随机颜色
    /// - Parameter macaroon: 马卡龙颜色
    /// - Returns: UIColor对象
    static func randomColor(_ macaroon: Bool) -> UIColor {
        if macaroon {
            // 马卡龙色：色相随机，饱和度和亮度较高且柔和
            let hue = CGFloat(arc4random_uniform(256)) / 255.0 // 0~1
            let saturation = CGFloat(arc4random_uniform(31) + 40) / 100.0 // 0.40~0.70
            let brightness = CGFloat(arc4random_uniform(16) + 85) / 100.0 // 0.85~1.00
            return UIColor(hue: hue, saturation: saturation, brightness: brightness, alpha: 1.0)
        } else {
            // 完全随机RGB色
            let r = CGFloat(arc4random_uniform(256)) / 255.0
            let g = CGFloat(arc4random_uniform(256)) / 255.0
            let b = CGFloat(arc4random_uniform(256)) / 255.0
            return UIColor(red: r, green: g, blue: b, alpha: 1.0)
        }
    }
    
    /// 动态白色颜色
    /// - Parameters:
    ///   - light: 浅色值
    ///   - dark: 深色值
    /// - Returns: UIColor对象
    static func color(light: CGFloat, dark: CGFloat) -> UIColor? {
        return color(
            light: UIColor(white: light, alpha: 1),
            dark: UIColor(white: dark, alpha: 1)
        )
    }
    
    /// 默认背景颜色
    /// - Returns: UIColor对象
    static func defaultBackgroundColor() -> UIColor {
        if #available(iOS 13.0, *) {
            return .systemBackground
        } else {
            return .white
        }
    }
}
