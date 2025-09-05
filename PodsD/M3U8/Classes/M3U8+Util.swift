//
//  M3U8+Util.swift
//  M3U8
//
//  Created by Cityu on 2025/8/19.
//

import Foundation
    
/// 解析标签内容
/// - Parameter tag: 标签字符串
/// - Returns: 解析出的内容
public func parseTagContent(_ tag: String) -> String? {
    var content = tag
    if !content.isEmpty && content.first == "#" {
        let startIndex = content.index(after: content.startIndex)
        if let colonRange = content.range(of: ":", range: startIndex..<content.endIndex) {
            content = String(content[colonRange.upperBound...])
        } else {
            content = ""
        }
    }
    return content.isEmpty ? nil : content
}
    
/// 解析标签对象
/// - Parameter tag: 标签字符串
/// - Returns: 解析出的参数字典
public func parseTagObj(_ tag: String) -> [String: String]? {
    guard let content = parseTagContent(tag), !content.isEmpty else {
        return nil
    }
    
    var result: [String: String] = [:]
    let length = content.count
    var currentIndex = content.startIndex
    var inQuotes = false // 是否在双引号内部
    var currentParam = ""
    
    while currentIndex < content.endIndex {
        let c = content[currentIndex]
        
        if c == "\"" {
            // 切换引号状态
            inQuotes.toggle()
            // 不保留引号
        } else if c == "," && !inQuotes {
            // 遇到逗号且不在引号内，分割参数
            processParam(currentParam, result: &result)
            currentParam = ""
        } else {
            // 其他字符直接拼接
            currentParam.append(c)
        }
        
        currentIndex = content.index(after: currentIndex)
    }
    
    // 处理最后一个参数
    if !currentParam.isEmpty {
        processParam(currentParam, result: &result)
    }
    
    return result.isEmpty ? nil : result
}

/// 辅助方法：解析单个参数（key=value）
/// - Parameters:
///   - param: 参数字符串
///   - result: 结果字典
private  func processParam(_ param: String, result: inout [String: String]) {
    let trimmedParam = param.trimmingCharacters(in: CharacterSet.whitespaces)
    if let equalRange = trimmedParam.range(of: "=") {
        let key = String(trimmedParam[..<equalRange.lowerBound])
        let value = String(trimmedParam[equalRange.upperBound...])
        result[key] = value
    }
}
