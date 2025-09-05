//
//  MIME.swift
//  QVGrab
//
//  Created by Cityu on 2025/4/25.
//

import Foundation
import AFNetworking


class MIME: NSObject {
    
    /**
     * 获取远程文件的MIME类型
     * @param url 远程文件URL
     * @param headers 请求头字典(可选)
     * @param completion 完成回调，返回MIME类型和可能的错误
     */
    static func getMimeType(forURL url: String, headers: [String: String]? = nil, completion: @escaping (String?, Error?) -> Void) {
        guard !url.isEmpty else {
            let error = NSError(domain: NSURLErrorDomain, code: NSURLErrorBadURL, userInfo: [NSLocalizedDescriptionKey: "URL is not set"])
            completion(nil, error)
            return
        }
        
        guard let _ = URL(string: url) else {
            let error = NSError(domain: NSURLErrorDomain, code: NSURLErrorBadURL, userInfo: [NSLocalizedDescriptionKey: "Invalid URL"])
            completion(nil, error)
            return
        }
        
        // 创建AFHTTPSessionManager实例
        let manager = AFHTTPSessionManager()
        
        // 配置超时时间
        manager.requestSerializer.timeoutInterval = 15
        
        // 设置请求头
        if let headers = headers {
            for (key, value) in headers {
                manager.requestSerializer.setValue(value, forHTTPHeaderField: key)
            }
        }
        
        // 配置安全策略（如果需要信任所有证书）
        let securityPolicy = AFSecurityPolicy(pinningMode: .none)
        securityPolicy.allowInvalidCertificates = true
        securityPolicy.validatesDomainName = false
        manager.securityPolicy = securityPolicy
        
        // 发送HEAD请求
        manager.head(url, parameters: nil, headers: nil, success: { task in
            DispatchQueue.main.async {
                guard let httpResponse = task.response as? HTTPURLResponse else {
                    let error = NSError(domain: NSURLErrorDomain, code: NSURLErrorUnknown, userInfo: [NSLocalizedDescriptionKey: "Invalid response"])
                    completion(nil, error)
                    return
                }
                
                var mimeType = httpResponse.mimeType
                
                // 如果服务器没有返回MIME类型，尝试从Content-Type头获取
                if mimeType == nil {
                    let responseHeaders = httpResponse.allHeaderFields
                    let contentType = responseHeaders["Content-Type"] as? String ?? responseHeaders["content-type"] as? String
                    if let contentType = contentType {
                        // 提取MIME类型（去除charset等参数）
                        let components = contentType.components(separatedBy: ";")
                        mimeType = components.first?.trimmingCharacters(in: .whitespaces)
                    }
                }
                
                completion(mimeType, nil)
            }
        }, failure: { task, error in
            DispatchQueue.main.async {
                completion(nil, error)
            }
        })
    }
    
    /**
     * 检查远程文件是否为指定的MIME类型
     * @param mimeType 要检查的MIME类型
     * @param url 远程文件URL
     * @param headers 请求头字典(可选)
     * @param completion 完成回调，返回是否匹配和可能的错误
     */
    static func checkMimeType(_ mimeType: String, forURL url: String, headers: [String: String]? = nil, completion: @escaping (Bool, Error?) -> Void) {
        getMimeType(forURL: url, headers: headers) { actualMimeType, error in
            if let error = error {
                completion(false, error)
                return
            }
            
            guard let actualMimeType = actualMimeType else {
                let noMimeError = NSError(domain: NSURLErrorDomain, code: NSURLErrorUnknown, userInfo: [NSLocalizedDescriptionKey: "No MIME type returned"])
                completion(false, noMimeError)
                return
            }
            
            // 将两个MIME类型转换为小写进行比较
            let isMatch = actualMimeType.lowercased() == mimeType.lowercased()
            completion(isMatch, nil)
        }
    }
}
