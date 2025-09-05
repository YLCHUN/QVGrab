//
//  UIImage+FileExtension.swift
//  FileBrowse
//
//  Created by Cityu on 2025/6/5.
//

import UIKit

public extension UIImage {
    static func imageWithExtension(_ extension: FileExtension) -> UIImage? {
        let imageName = fileExtensionImageNamed(`extension`)
        return UIImage(named: imageName, in: FileBrowseBundle.resourceBundle, compatibleWith: nil)
    }
    
    static func fileExtensionImageNamed(_ extension: FileExtension) -> String {
        switch `extension` {
        case .unknown: return "Unknown"
        case .directory: return "Directory"
        default: return `extension`.rawValue.uppercased()
        }
    }
}
