//
//  VideoTitleParser.swift
//  JSScript
//
//  Created by Cityu on 2025/6/2.
//  Copyright © 2025 Cityu. All rights reserved.
//

import Foundation

public func parseVideoTitle(_ webTitle: String?) -> String? {
    guard let webTitle = webTitle, !webTitle.isEmpty else {
        return webTitle
    }
    
    // 首先尝试匹配书名号内的内容
    let bookTitlePattern = "《([^》]+)》"
    if let bookTitleRegex = try? NSRegularExpression(pattern: bookTitlePattern, options: []),
       let bookTitleMatch = bookTitleRegex.firstMatch(in: webTitle, options: [], range: NSRange(location: 0, length: webTitle.count)) {
        
        let bookTitle = (webTitle as NSString).substring(with: bookTitleMatch.range(at: 1))
        
        // 查找集数信息
        let episodePattern = "第\\d+集"
        if let episodeRegex = try? NSRegularExpression(pattern: episodePattern, options: []),
           let episodeMatch = episodeRegex.firstMatch(in: webTitle, options: [], range: NSRange(location: 0, length: webTitle.count)) {
            
            let episodeInfo = (webTitle as NSString).substring(with: episodeMatch.range)
            return cleanTitle("\(bookTitle) \(episodeInfo)")
        }
        
        return cleanTitle(bookTitle)
    }
    
    // 如果没有找到书名号，尝试其他模式
    let patterns = [
        // 匹配 "视频名称 - 第X集 - 播放" 格式
        ".*?(?=\\s*-\\s*(?:播放|在线观看|观看|视频|高清|免费|完整版|全集|正片))",
        // 匹配 "视频名称 - 第X集 | 播放" 格式
        ".*?(?=\\s*\\|\\s*(?:播放|在线观看|观看|视频|高清|免费|完整版|全集|正片))",
        // 匹配 "视频名称 - 第X集【播放】" 格式
        ".*?(?=\\s*【(?:播放|在线观看|观看|视频|高清|免费|完整版|全集|正片)】)",
        // 匹配 "视频名称 - 第X集（播放）" 格式
        ".*?(?=\\s*\\((?:播放|在线观看|观看|视频|高清|免费|完整版|全集|正片)\\))",
        // 匹配 "视频名称 - 第X集 - 网站名称" 格式
        ".*?(?=\\s*-\\s*[^-]+$)",
        // 匹配 "视频名称 - 第X集 | 网站名称" 格式
        ".*?(?=\\s*\\|\\s*[^|]+$)",
        // 匹配 "视频名称 - 第X集【网站名称】" 格式
        ".*?(?=\\s*【[^】]+】$)",
        // 匹配 "视频名称 - 第X集（网站名称）" 格式
        ".*?(?=\\s*\\([^)]+\\)$)",
        // 匹配 "视频名称 - 第X集" 格式
        ".*?(?=\\s*-\\s*第\\d+集$)",
        // 匹配 "视频名称 第X集" 格式
        ".*?(?=\\s*第\\d+集$)",
        // 匹配 "视频名称 - 更新至X集" 格式
        ".*?(?=\\s*-\\s*更新至\\d+集$)",
        // 匹配 "视频名称 更新至X集" 格式
        ".*?(?=\\s*更新至\\d+集$)",
        // 匹配 "视频名称 - 全X集" 格式
        ".*?(?=\\s*-\\s*全\\d+集$)",
        // 匹配 "视频名称 全X集" 格式
        ".*?(?=\\s*全\\d+集$)",
        // 匹配 "视频名称 - 第X季" 格式
        ".*?(?=\\s*-\\s*第\\d+季$)",
        // 匹配 "视频名称 第X季" 格式
        ".*?(?=\\s*第\\d+季$)",
        // 匹配 "视频名称 - 第X部" 格式
        ".*?(?=\\s*-\\s*第\\d+部$)",
        // 匹配 "视频名称 第X部" 格式
        ".*?(?=\\s*第\\d+部$)",
        // 匹配 "视频名称 - 国语" 格式
        ".*?(?=\\s*-\\s*(?:国语|粤语|英语|日语|韩语)$)",
        // 匹配 "视频名称 国语" 格式
        ".*?(?=\\s*(?:国语|粤语|英语|日语|韩语)$)",
        // 匹配 "视频名称 - 中文字幕" 格式
        ".*?(?=\\s*-\\s*(?:中文字幕|英文字幕|双语字幕)$)",
        // 匹配 "视频名称 中文字幕" 格式
        ".*?(?=\\s*(?:中文字幕|英文字幕|双语字幕)$)",
        // 匹配 "视频名称 - 1080P" 格式
        ".*?(?=\\s*-\\s*(?:1080P|720P|4K|蓝光|高清)$)",
        // 匹配 "视频名称 1080P" 格式
        ".*?(?=\\s*(?:1080P|720P|4K|蓝光|高清)$)"
    ]
    
    // 尝试所有模式
    for pattern in patterns {
        if let regex = try? NSRegularExpression(pattern: pattern, options: .caseInsensitive),
           let match = regex.firstMatch(in: webTitle, options: [], range: NSRange(location: 0, length: webTitle.count)) {
            
            let extractedTitle = (webTitle as NSString).substring(with: match.range)
            if !extractedTitle.isEmpty {
                // 检查提取的标题是否包含集数信息
                let episodePattern = "第\\d+集"
                if let episodeRegex = try? NSRegularExpression(pattern: episodePattern, options: []),
                   episodeRegex.firstMatch(in: extractedTitle, options: [], range: NSRange(location: 0, length: extractedTitle.count)) == nil {
                    
                    // 如果提取的标题不包含集数，尝试从原始标题中查找集数信息
                    if let originalEpisodeRegex = try? NSRegularExpression(pattern: episodePattern, options: []),
                       let originalEpisodeMatch = originalEpisodeRegex.firstMatch(in: webTitle, options: [], range: NSRange(location: 0, length: webTitle.count)) {
                        
                        let episodeInfo = (webTitle as NSString).substring(with: originalEpisodeMatch.range)
                        let finalTitle = "\(extractedTitle) \(episodeInfo)"
                        return cleanTitle(finalTitle)
                    }
                }
                // 清理标题中的播放相关字眼
                return cleanTitle(extractedTitle)
            }
        }
    }
    
    // 如果所有模式都没有匹配到，清理原始标题
    return cleanTitle(webTitle)
}

private func cleanTitle(_ title: String?) -> String? {
    guard let title = title, !title.isEmpty else {
        return title
    }
    
    // 定义需要移除的播放相关字眼
    let playKeywords = [
        "播放",
        "在线观看",
        "观看",
        "视频",
        "高清",
        "免费",
        "完整版",
        "全集",
        "正片",
        "在线",
        "直播",
        "在线播放",
        "在线视频",
        "在线高清",
        "在线免费",
        "在线完整版",
        "在线全集",
        "在线正片",
        "在线直播",
        "在线观看",
        "在线观看免费",
        "在线观看高清",
        "在线观看完整版",
        "在线观看全集",
        "在线观看正片",
        "在线观看直播",
        "在线观看视频"
    ]
    
    // 移除播放相关字眼
    var cleanedTitle = title
    for keyword in playKeywords {
        cleanedTitle = cleanedTitle.replacingOccurrences(of: keyword, with: "")
    }
    
    // 移除多余的空格和分隔符
    cleanedTitle = cleanedTitle.replacingOccurrences(of: "\\s+", with: " ", options: .regularExpression, range: nil)
    cleanedTitle = cleanedTitle.replacingOccurrences(of: "\\s*-\\s*", with: " - ", options: .regularExpression, range: nil)
    
    return cleanedTitle
}

