//
//  NSString+Hash.swift
//  QVGrab
//
//  Created by Cityu on 2025/4/30.
//

import Foundation
import CommonCrypto

extension String {
    
    /// 生成哈希ID
    /// - Returns: 哈希ID字符串
    var hashId: String  {
        let string = self
        let cStr = string.cString(using: .utf8)!
        
        if #available(iOS 13.0, *) {
            var result = [UInt8](repeating: 0, count: Int(CC_SHA256_DIGEST_LENGTH))
            CC_SHA256(cStr, CC_LONG(strlen(cStr)), &result)
            
            var hash = ""
            for i in 0..<Int(CC_SHA256_DIGEST_LENGTH) {
                hash += String(format: "%02x", result[i])
            }
            return hash
        } else {
            var result = [UInt8](repeating: 0, count: Int(CC_MD5_DIGEST_LENGTH))
            CC_MD5(cStr, CC_LONG(strlen(cStr)), &result)
            
            return String(format: "%02x%02x%02x%02x%02x%02x%02x%02x%02x%02x%02x%02x%02x%02x%02x%02x",
                         result[0], result[1], result[2], result[3],
                         result[4], result[5], result[6], result[7],
                         result[8], result[9], result[10], result[11],
                         result[12], result[13], result[14], result[15])
        }
    }
}
