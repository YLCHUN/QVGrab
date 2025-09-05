//
//  M3U8.swift
//  QVGrab
//
//  Created by Cityu on 2025/4/3.
//

import Foundation

// MARK: - TSEncryption
class TSEncryption {
    private var _eid: String?
    
    /// 当前片段使用的加密密钥URI
    var key: String? {
        didSet {
            _eid = key?.hashId
        }
    }
    
    /// 当前片段使用的加密方法
    var method: String?
    
    /// 当前片段使用的初始化向量
    var iv: String?
    
    var eid: String {
        return _eid ?? "def"
    }
}

// MARK: - TS
/// TS 片段对象
/// 用于表示 M3U8 文件中的一个媒体片段
class TS: NSObject, NSCopying {
    
    /// 片段序号，从 EXT-X-MEDIA-SEQUENCE 开始递增
    var index: Int = 0
    
    /// 片段时长，来自 #EXTINF:<duration>,<title> 标签中的 duration 值
    var duration: Float = 0
    
    /// 片段 URL，可以是绝对路径或相对路径
    var url: String = ""
    
    /// 字节范围，来自 #EXT-X-BYTERANGE:<n>[@<o>] 标签
    /// n 表示字节长度，o 表示起始偏移量
    var byteRange: String?
    
    /// 片段的绝对时间，来自 #EXT-X-PROGRAM-DATE-TIME:<YYYY-MM-DDThh:mm:ssZ> 标签
    /// 格式示例：2024-04-03T14:54:23.031+08:00
    var programDateTime: String?
    
    /// 片段标题，来自 #EXTINF:<duration>,<title> 标签中的 title 值
    var title: String?
    
    /// 是否包含编码参数变化
    var discontinuity: Bool = false
    
    var encryption: TSEncryption?
    
    /// 是否为广告片段
    var isAdvertisement: Bool = false
    
    override init() {
        super.init()
    }
    
    // MARK: - NSCopying
    func copy(with zone: NSZone? = nil) -> Any {
        let copy = TS()
        copy.index = self.index
        copy.duration = self.duration
        copy.url = self.url
        copy.byteRange = self.byteRange
        copy.programDateTime = self.programDateTime
        copy.title = self.title
        copy.discontinuity = self.discontinuity
        copy.encryption = self.encryption
        copy.isAdvertisement = self.isAdvertisement
        return copy
    }
}

// MARK: - StreamAttributes
/// 流媒体属性对象
/// 用于表示 M3U8 文件中的流媒体属性
class StreamAttributes: NSObject, NSCopying {
    
    /// 带宽（bps）
    var bandwidth: Int = 0
    
    /// 分辨率（宽 × 高）
    var resolution: String?
    
    /// 编解码器信息
    var codecs: String?
    
    /// 帧率
    var frameRate: Float = 0
    
    override init() {
        super.init()
    }
    
    // MARK: - NSCopying
    func copy(with zone: NSZone? = nil) -> Any {
        let copy = StreamAttributes()
        copy.bandwidth = self.bandwidth
        copy.resolution = self.resolution
        copy.codecs = self.codecs
        copy.frameRate = self.frameRate
        return copy
    }
}

// MARK: - VariantStream
/// Variant Stream 对象
/// 用于表示 M3U8 文件中的一个变体流
class VariantStream: NSObject, NSCopying {
    
    /// 流媒体属性
    var streamAttributes: StreamAttributes
    
    /// 流 URL
    var url: String = ""
    
    override init() {
        self.streamAttributes = StreamAttributes()
        super.init()
    }
    
    // MARK: - NSCopying
    func copy(with zone: NSZone? = nil) -> Any {
        let copy = VariantStream()
        copy.streamAttributes = self.streamAttributes.copy() as! StreamAttributes
        copy.url = self.url
        return copy
    }
}

// MARK: - M3U8
/// M3U8 播放列表对象
/// 支持 VOD(点播) 和 LIVE(直播) 两种类型
class M3U8: NSObject, NSCopying {
    
    /// #EXT-X-VERSION:<n> - 协议版本号
    var version: Int = 0
    
    /// #EXT-X-PLAYLIST-TYPE:<EVENT|VOD> - 播放列表类型
    /// VOD: 表示该视频为点播视频，服务器不能修改播放列表
    /// EVENT: 表示服务器不能修改或删除已有片段，但可以追加新片段
    var playlistType: String?
    
    /// #EXT-X-TARGETDURATION:<s> - 所有片段的最大时长（秒）
    var targetDuration: Int = 0
    
    /// #EXT-X-ALLOW-CACHE:<YES|NO> - 是否允许客户端缓存媒体片段
    /// YES: 允许缓存
    /// NO: 不允许缓存
    var allowCache: Bool = true
    
    /// #EXT-X-MEDIA-SEQUENCE:<number> - 第一个媒体片段的序列号
    /// 如果未指定，默认为 0
    /// 用于直播场景中标识片段的起始位置
    var mediaSequence: Int = 0
    
    /// 所有媒体片段对象数组
    var segments: [TS] = []
    
    /// 所有片段总时长（秒）
    var duration: Int = 0
    
    /// 是否为直播流
    /// YES: 直播流（默认）
    /// NO: 点播内容（存在 #EXT-X-ENDLIST 标签或 PLAYLIST-TYPE:VOD）
    var isLive: Bool = true
    
    /// 是否为多层多码率格式
    var isMultiVariant: Bool = false
    
    /// 流媒体属性，仅用于多层多码率格式
    var streamAttributes: StreamAttributes?
    
    /// 子流列表，仅用于多层多码率格式
    var variantStreams: [VariantStream]?
    
    /// 是否包含编码参数变化
    var hasDiscontinuity: Bool = false
    
    override init() {
        super.init()
    }
    
    /// 解析 M3U8 文件内容
    /// - Parameter m3u8Content: M3U8 文件内容字符串
    /// - Returns: 解析后的 M3U8 对象，解析失败返回 nil
    static func m3u8(_ m3u8Content: String) -> M3U8? {
        guard !m3u8Content.isEmpty else {
            return nil
        }
        
        let model = M3U8()
        model.isLive = true  // 默认为直播流
        model.allowCache = true  // 默认允许缓存
        model.mediaSequence = 0  // 默认媒体序列号为0
        model.isMultiVariant = false  // 默认为单层格式
        model.hasDiscontinuity = false  // 默认无编码参数变化
        
        // 将内容按行分割
        let lines = m3u8Content.components(separatedBy: CharacterSet.newlines)
        
        // 检查文件头
        guard !lines.isEmpty, lines.first == "#EXTM3U" else {
            print("Invalid M3U8 file: Missing #EXTM3U header")
            return nil
        }
        
        var segments: [TS] = []
        var variantStreams: [VariantStream] = []
        var currentTS: TS?
        var currentStreamAttributes: StreamAttributes?
        var totalDuration: Int = 0
        var tsIndex = 0
        
        // 当前加密信息
        var encryption: TSEncryption?
        
        for line in lines {
            let trimmedLine = line.trimmingCharacters(in: CharacterSet.whitespacesAndNewlines)
            
            guard !trimmedLine.isEmpty else { continue }
            
            // 检查文件头
            if trimmedLine == "#EXTM3U" {
                continue
            }
            
            // 解析版本信息
            if trimmedLine.hasPrefix("#EXT-X-VERSION:") {
                model.version = Int(parseTagContent(trimmedLine) ?? "0") ?? 0
                continue
            }
            
            // 解析播放列表类型
            if trimmedLine.hasPrefix("#EXT-X-PLAYLIST-TYPE:") {
                model.playlistType = parseTagContent(trimmedLine)
                // VOD类型表示这是一个点播视频
                if model.playlistType == "VOD" {
                    model.isLive = false
                }
                continue
            }
            
            // 解析目标时长
            if trimmedLine.hasPrefix("#EXT-X-TARGETDURATION:") {
                model.targetDuration = Int(parseTagContent(trimmedLine) ?? "0") ?? 0
                continue
            }
            
            // 解析媒体序列号
            if trimmedLine.hasPrefix("#EXT-X-MEDIA-SEQUENCE:") {
                model.mediaSequence = Int(parseTagContent(trimmedLine) ?? "0") ?? 0
                continue
            }
            
            // 解析是否允许缓存
            if trimmedLine.hasPrefix("#EXT-X-ALLOW-CACHE:") {
                model.allowCache = parseTagContent(trimmedLine) == "YES"
                continue
            }
            
            // 解析加密信息
            if trimmedLine.hasPrefix("#EXT-X-KEY:") {
                let obj = parseTagObj(trimmedLine)
                let method = obj?["METHOD"]
                if method == nil || method == "NONE" {
                    encryption = nil
                } else {
                    encryption = TSEncryption()
                    encryption?.method = method
                    encryption?.key = obj?["URI"]
                    encryption?.iv = obj?["IV"]
                }
                continue
            }
            
            // 解析字节范围
            if trimmedLine.hasPrefix("#EXT-X-BYTERANGE:") {
                if let currentTS = currentTS {
                    currentTS.byteRange = parseTagContent(trimmedLine)
                }
                continue
            }
            
            // 解析程序日期时间
            if trimmedLine.hasPrefix("#EXT-X-PROGRAM-DATE-TIME:") {
                if let currentTS = currentTS {
                    currentTS.programDateTime = parseTagContent(trimmedLine)
                }
                continue
            }
            
            // 解析编码参数变化标记
            if trimmedLine == "#EXT-X-DISCONTINUITY" {
                model.hasDiscontinuity = true
                if let currentTS = currentTS {
                    currentTS.discontinuity = true
                }
                continue
            }
            
            // 解析流媒体属性
            if trimmedLine.hasPrefix("#EXT-X-STREAM-INF:") {
                model.isMultiVariant = true
                
                let obj = parseTagObj(trimmedLine)
                if let obj = obj, !obj.isEmpty {
                    currentStreamAttributes = StreamAttributes()
                    
                    // 解析带宽
                    if let bandwidth = obj["BANDWIDTH"] {
                        currentStreamAttributes?.bandwidth = Int(bandwidth) ?? 0
                    }
                    
                    // 解析分辨率
                    currentStreamAttributes?.resolution = obj["RESOLUTION"]
                    
                    // 解析编解码器
                    currentStreamAttributes?.codecs = obj["CODECS"]
                    
                    // 解析帧率
                    if let frameRate = obj["FRAME-RATE"] {
                        currentStreamAttributes?.frameRate = Float(frameRate) ?? 0
                    }
                } else {
                    currentStreamAttributes = nil
                }
                continue
            }
            
            // 解析片段时长
            if trimmedLine.hasPrefix("#EXTINF:") {
                currentTS = TS()
                currentTS?.index = tsIndex
                currentTS?.discontinuity = false
                currentTS?.encryption = encryption
                
                // 解析时长
                let durationInfo = parseTagContent(trimmedLine) ?? ""
                if let commaRange = durationInfo.range(of: ",") {
                    let durationStr = String(durationInfo[..<commaRange.lowerBound])
                    currentTS?.duration = Float(durationStr) ?? 0
                    currentTS?.title = String(durationInfo[commaRange.upperBound...])
                } else {
                    currentTS?.duration = Float(durationInfo) ?? 0
                }
                
                totalDuration += Int(currentTS?.duration ?? 0)
                continue
            }
            
            // 处理非标签行（URL）
            if !trimmedLine.hasPrefix("#") {
                if let ts = currentTS {
                    ts.url = trimmedLine
                    segments.append(ts)
                    currentTS = nil
                    tsIndex += 1
                } else if model.isMultiVariant, let attributes = currentStreamAttributes {
                    // 处理子流URL
                    let variantStream = VariantStream()
                    variantStream.streamAttributes = attributes
                    variantStream.url = trimmedLine
                    variantStreams.append(variantStream)
                    currentStreamAttributes = nil
                }
            }
            
            // 检查播放列表结束标记
            if trimmedLine == "#EXT-X-ENDLIST" {
                model.isLive = false  // 存在ENDLIST标记说明这是点播视频
                continue
            }
        }
        
        // 设置解析结果
        model.segments = segments
        model.duration = totalDuration
        model.variantStreams = variantStreams.isEmpty ? nil : variantStreams
        
        // 如果没有解析到任何分片或子流，返回nil
        if segments.isEmpty && variantStreams.isEmpty {
            print("No valid segments or variant streams found in M3U8 file")
            return nil
        }
        
        return model
    }
    
    // MARK: - NSCopying
    func copy(with zone: NSZone? = nil) -> Any {
        let copy = M3U8()
        copy.version = self.version
        copy.playlistType = self.playlistType
        copy.targetDuration = self.targetDuration
        copy.allowCache = self.allowCache
        copy.mediaSequence = self.mediaSequence
        copy.duration = self.duration
        copy.isLive = self.isLive
        copy.isMultiVariant = self.isMultiVariant
        copy.hasDiscontinuity = self.hasDiscontinuity
        
        // 深拷贝segments数组
        copy.segments = self.segments.map { $0.copy() as! TS }
        
        // 深拷贝streamAttributes
        if let streamAttributes = self.streamAttributes {
            copy.streamAttributes = streamAttributes.copy() as? StreamAttributes
        }
        
        // 深拷贝variantStreams数组
        if let variantStreams = self.variantStreams {
            copy.variantStreams = variantStreams.map { $0.copy() as! VariantStream }
        }
        
        return copy
    }
    
    /// 将相对URL转换为绝对URL
    /// - Parameter baseURL: 基础URL
    /// - Returns: 转换后的M3U8对象，如果baseURL为空则返回原对象
    func convertRelativeURLsToAbsoluteURLs(_ baseURL: String) -> M3U8 {
        guard !baseURL.isEmpty else {
            return self
        }
        
        // 创建深拷贝
        let convertedM3U8 = self.copy() as! M3U8
        
        // 获取基础URL
        guard let base = URL(string: baseURL) else {
            return convertedM3U8
        }
        let baseURLObject = base.deletingLastPathComponent()
        
        // 处理主流的segments
        var convertedSegments: [TS] = []
        for ts in convertedM3U8.segments {
            let convertedTS = ts.copy() as! TS
            if !convertedTS.url.hasPrefix("http://") && !convertedTS.url.hasPrefix("https://") {
                if let absoluteURL = URL(string: convertedTS.url, relativeTo: baseURLObject) {
                    convertedTS.url = absoluteURL.absoluteString
                }
            }
            if let encryption = ts.encryption {
                if let key = encryption.key, !key.hasPrefix("http://") && !key.hasPrefix("https://") {
                    if let absoluteURL = URL(string: key, relativeTo: baseURLObject) {
                        encryption.key = absoluteURL.absoluteString
                    }
                }
            }
            
            convertedSegments.append(convertedTS)
        }
        convertedM3U8.segments = convertedSegments
        
        // 处理variantStreams
        if let variantStreams = convertedM3U8.variantStreams {
            var convertedVariantStreams: [VariantStream] = []
            for variant in variantStreams {
                let convertedVariant = variant.copy() as! VariantStream
                if !convertedVariant.url.hasPrefix("http://") && !convertedVariant.url.hasPrefix("https://") {
                    if let absoluteURL = URL(string: convertedVariant.url, relativeTo: baseURLObject) {
                        convertedVariant.url = absoluteURL.absoluteString
                    }
                }
                convertedVariantStreams.append(convertedVariant)
            }
            convertedM3U8.variantStreams = convertedVariantStreams
        }
        
        return convertedM3U8
    }
    
    /// 识别并移除广告片段
    /// - Returns: 移除广告后的M3U8对象
    func removeAdvertisements() -> M3U8 {
        // 先检测广告
        let count = markAdvertisements()
        
        if count == 0 {
            return self // 没有广告，返回原对象
        }
        
        // 创建新的M3U8对象
        let cleanM3U8 = self.copy() as! M3U8
        cleanM3U8.hasDiscontinuity = false
        var cleanSegments: [TS] = []
        
        // 过滤掉广告片段
        for ts in self.segments {
            if !ts.isAdvertisement {
                cleanSegments.append(ts.copy() as! TS)
            }
        }
        
        // 重新计算索引和总时长
        var newIndex = 0
        var newTotalDuration: Float = 0
        
        for ts in cleanSegments {
            ts.index = newIndex
            newIndex += 1
            ts.discontinuity = false
            newTotalDuration += ts.duration
        }
        
        cleanM3U8.segments = cleanSegments
        cleanM3U8.duration = Int(newTotalDuration)
        
        print("移除广告完成: 原始片段数=\(self.segments.count), 清理后片段数=\(cleanSegments.count), 移除片段数=\(self.segments.count - cleanSegments.count)")
        
        return cleanM3U8
    }
    
    // MARK: - Private Methods
    
    /// 标记广告片段
    /// - Returns: 标记的广告片段数量
    private func markAdvertisements() -> UInt {
        guard !self.segments.isEmpty else {
            return 0
        }
        guard self.hasDiscontinuity else {
            return 0
        }
        
        // 统计每个path的出现次数
        var pathUrlsMap: [String: Set<String>] = [:]
        var pathTSsMap: [String: [TS]] = [:]
        
        for i in 0..<self.segments.count {
            let ts = self.segments[i]
            let url = ts.url.components(separatedBy: "?").first ?? ""
            let path = (url as NSString).deletingLastPathComponent
            
            // 处理空路径的情况
            let finalPath = path.isEmpty ? "/" : path
            
            // 统计path出现次数
            if pathUrlsMap[finalPath] == nil {
                pathUrlsMap[finalPath] = Set<String>()
            }
            pathUrlsMap[finalPath]?.insert(url)
            
            if pathTSsMap[finalPath] == nil {
                pathTSsMap[finalPath] = []
            }
            pathTSsMap[finalPath]?.append(ts)
        }
        
        var count: UInt = 0
        
        // 如果path种类超过1种，则认定存在广告
        if pathUrlsMap.count > 1 {
            print("检测到 \(pathUrlsMap.count) 种不同的path类型，可能存在广告")
            
            // 找出数量最多的path类型（非广告内容）
            var mainPath = ""
            var maxCount = 0
            
            for (path, urls) in pathUrlsMap {
                let urlCount = urls.count
                print("Path: \(path), 片段数: \(urlCount)")
                if urlCount > maxCount {
                    maxCount = urlCount
                    mainPath = path
                }
            }
            
            print("主要路径: \(mainPath) (片段数: \(maxCount))")
            
            // 标记非主要path的片段为广告
            for (path, tss) in pathTSsMap {
                if path != mainPath {
                    let adCount = tss.count
                    count += UInt(adCount)
                    print("标记广告路径: \(path) (片段数: \(adCount))")
                    
                    for ts in tss {
                        ts.isAdvertisement = true // 标记为广告
                    }
                }
            }
            
            print("总共标记了 \(count) 个广告片段")
        } else {
            print("Path类型数量为 \(pathUrlsMap.count)，未检测到广告")
        }
        
        return count
    }
}
