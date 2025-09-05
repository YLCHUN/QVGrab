//
//  ChouyeAsset.swift
//  Chouye
//
//  Created by YLCHUN on 2020/9/4.
//

import Foundation
import UIKit
import ObjectiveC

// MARK: - Runtime Helper Function
private let mutex = DispatchQueue(label: "com.chouye.dynamicclass")
private func c_runtime_dynamicSubClass(_ originClass: AnyClass, _ suffix: String, _ initBlock: (AnyClass, UnsafeMutablePointer<Bool>) -> Void) -> AnyClass? {
    guard !suffix.isEmpty else { return originClass }
    
    let originClassName = NSStringFromClass(originClass)
    guard !originClassName.hasSuffix(suffix) else { return originClass }
    
    let subClassName = originClassName + suffix
    let subClassNameCString = subClassName.cString(using: .utf8)!
    
    // 使用DispatchQueue来模拟pthread_mutex
    return mutex.sync {
        var subClass: AnyClass? = objc_getClass(subClassNameCString) as? AnyClass
        if subClass == nil {
            subClass = objc_allocateClassPair(originClass, subClassNameCString, 0)
            if let subClass = subClass {
                var restoreClass = false
                initBlock(subClass, &restoreClass)
                
                if restoreClass {
                    let sel = #selector(NSObject.classForCoder)
                    if let m = class_getInstanceMethod(subClass, sel), let te = method_getTypeEncoding(m)  {
                        let imp = imp_implementationWithBlock { (_: Any) -> AnyClass in
                            return originClass
                        }
                        class_addMethod(subClass, sel, imp, te)
                    }
                }
                
                objc_registerClassPair(subClass)
            }
        }
        return subClass
    }
}

@available(iOS 13.0, *)
final class ChouyeAsset {
    static func isChouye(_ image: UIImage) -> Bool {
        return image.caTrait != nil
    }
    
    private let rawImageProvider: ((UIUserInterfaceStyle) -> UIImage)
    
    init(_ imageProvider: @escaping (UIUserInterfaceStyle) -> UIImage) {
        self.rawImageProvider = imageProvider
    }

    func resolvedImage(with style: UIUserInterfaceStyle) -> UIImage? {
        var image = self.image(with: style)
        if image == nil {
            let alternateStyle: UIUserInterfaceStyle = style == .dark ? .light : .dark
            image = self.image(with: alternateStyle)
        }
        return image
    }
    
    static func rawImage(from image: UIImage) -> UIImage? {
        return image.caTrait?.image
    }
    
    private func rawImage(with style: UIUserInterfaceStyle) -> UIImage {
        return rawImageProvider(style)
    }
    
    private func cloneImage(from image: UIImage) -> UIImage? {
        if let images = image.images, images.count > 0 {
            return UIImage.animatedImage(with: images, duration: image.duration)
        } 
        else {
            var newImage: UIImage?
            autoreleasepool {
                newImage = image.withBaselineOffset(fromBottom: (image.baselineOffsetFromBottom ?? 0) + 10)
                if let baselineOffsetFromBottom = image.baselineOffsetFromBottom {
                    newImage = newImage?.withBaselineOffset(fromBottom: baselineOffsetFromBottom)
                } else {
                    newImage = newImage?.imageWithoutBaseline()
                }
            }
            return newImage
        }
    }
    
    private func image(with style: UIUserInterfaceStyle) -> UIImage? {
        let image = rawImage(with: style)
        
        guard let newImage = cloneImage(from: image) else {
            assertionFailure("Must return a brand new image here!")
            return nil
        }
        
        let trait = ChouyeAssetTrait()
        trait.ChouyeAsset = self
        trait.userInterfaceStyle = style
        trait.image = image
        
        newImage.caTrait = trait
        setChouyeClass(to: newImage)
        
        return newImage
    }
    
    private func setChouyeClass(to image: UIImage) {
        let originClass: AnyClass = object_getClass(image)!
        let subClass: AnyClass? = c_runtime_dynamicSubClass(originClass, "_ChouyeClass") { subClass, restoreClass in
            restoreClass.pointee = true
            
            // imageWithConfiguration: method
            let sel1 = #selector(UIImage.withConfiguration(_:))
            class_addMethod(subClass, sel1, imp_implementationWithBlock { (self: UIImage, ic: UIImage.Configuration) -> UIImage in
                guard let trait = self.caTrait else {
                    guard let imp = class_getMethodImplementation(object_getClass(self), sel1) else {
                        return self
                    }
                    typealias TIMP = @convention(c) (UIImage, Selector, UIImage.Configuration) -> UIImage
                    return unsafeBitCast(imp, to: TIMP.self)(self, sel1, ic)
                }
                guard let style = ic.traitCollection?.userInterfaceStyle else { return self }
                if trait.userInterfaceStyle == style {
                    return self
                }
                else {
                    let img = trait.ChouyeAsset.resolvedImage(with: style)
                    return img ?? self
                }
            } , method_getTypeEncoding(class_getInstanceMethod(originClass, sel1)!)!)
            
            // resizableImageWithCapInsets: method
            let sel2 = #selector(UIImage.resizableImage(withCapInsets:))
            class_addMethod(subClass, sel2, imp_implementationWithBlock { (self: UIImage, capInsets: UIEdgeInsets) -> UIImage in
                guard let trait = self.caTrait else {
                    guard let imp = class_getMethodImplementation(object_getClass(self), sel2) else {
                        return self
                    }
                    typealias TIMP = (@convention(c) (UIImage, Selector, UIEdgeInsets) -> UIImage)
                    return unsafeBitCast(imp, to: TIMP.self)(self, sel2, capInsets)
                }
                
                let asset = ChouyeAsset() { style in
                    var image = trait.ChouyeAsset.rawImage(with: style)
                    image = image.resizableImage(withCapInsets: capInsets)
                    return image
                }
                guard let style = self.configuration?.traitCollection?.userInterfaceStyle else { return self }
                return asset.resolvedImage(with: style) ?? self
                
            }, method_getTypeEncoding(class_getInstanceMethod(originClass, sel2)!)!)
        }
        
        if let subClass = subClass, originClass != subClass {
            object_setClass(image, subClass)
        }
    }
}

// MARK: - Private Classes

@available(iOS 13.0, *)
private class ChouyeAssetTrait: NSObject {
    var ChouyeAsset: ChouyeAsset!
    var userInterfaceStyle: UIUserInterfaceStyle = .unspecified
    var image: UIImage!
}

@available(iOS 13.0, *)
private extension UIImage {
    private static var caTraitKey: UInt8 = 0
    
    var caTrait: ChouyeAssetTrait? {
        get {
            return objc_getAssociatedObject(self, &UIImage.caTraitKey) as? ChouyeAssetTrait
        }
        set {
            objc_setAssociatedObject(self, &UIImage.caTraitKey, newValue, .OBJC_ASSOCIATION_RETAIN_NONATOMIC)
        }
    }
}
