//
//  FileExtension.swift
//  FileBrowse
//
//  Created by Cityu on 2025/5/27.
//  Copyright © 2025 Cityu. All rights reserved.
//

import Foundation

// MARK: - File Extension Types
public enum FileExtensionType: String, CaseIterable {
    case unknown = "unknown"
    case directory = "directory"
    case image = "image"
    case video = "video"
    case audio = "audio"
    case plainText = "plainText"
    case formattedText = "formattedText"
    case archive = "archive"
    case font = "font"
    case package = "package"
    case database = "database"
    case executable = "executable"
    case sourceCode = "sourceCode"
    case config = "config"
}


// MARK: - File Extensions
public enum FileExtension: String, CaseIterable {
    case unknown = "unknown"
    
    // 目录
    case directory = "directory"
    
    // 图片文件
    case jpg = "jpg"
    case png = "png"
    case gif = "gif"
    case bmp = "bmp"
    case tiff = "tiff"
    case webp = "webp"
    case svg = "svg"
    case heic = "heic"
    case psd = "psd"
    case ai = "ai"
    case eps = "eps"
    
    // 视频文件
    case mp4 = "mp4"
    case mov = "mov"
    case avi = "avi"
    case mkv = "mkv"
    case webm = "webm"
    case ts = "ts"
    case m3u8 = "m3u8"
    
    // 音频文件
    case mp3 = "mp3"
    case wav = "wav"
    case aac = "aac"
    case flac = "flac"
    
    // 纯文本文件
    case txt = "txt"
    case log = "log"
    
    // 格式文本文件
    case pdf = "pdf"
    case doc = "doc"
    case docx = "docx"
    case xls = "xls"
    case xlsx = "xlsx"
    case ppt = "ppt"
    case pptx = "pptx"
    case rtf = "rtf"
    case xml = "xml"
    case json = "json"
    case html = "html"
    
    // 压缩文件
    case zip = "zip"
    case rar = "rar"
    case sevenZ = "7z"
    case tar = "tar"
    case gz = "gz"
    case iso = "iso"
    
    // 字体文件
    case ttf = "ttf"
    case otf = "otf"
    case woff = "woff"
    case woff2 = "woff2"
    case eot = "eot"
    
    // 软件包
    case exe = "exe"
    case dll = "dll"
    case apk = "apk"
    case ipa = "ipa"
    case dmg = "dmg"
    
    // 数据库文件
    case db = "db"
    case sql = "sql"
    case sqlite = "sqlite"
    case mdb = "mdb"
    
    // 源代码文件
    case css = "css"
    case js = "js"
    case py = "py"
    case java = "java"
    case classFile = "class"
    case swift = "swift"
    case objc = "objc"
    case h = "h"
    case c = "c"
    case cpp = "cpp"
    case cs = "cs"
    case go = "go"
    case rs = "rs"
    case php = "php"
    case rb = "rb"
    case sh = "sh"
    case bat = "bat"
    case cmd = "cmd"
    
    // 配置文件
    case reg = "reg"
    case ini = "ini"
    case yaml = "yaml"
    case toml = "toml"
}

extension FileExtension {
    public init(_ raw: String, def: FileExtension = .unknown) {
        // 特殊映射表，处理一个扩展名对应多个枚举值的情况
        let specialMappings: [String: FileExtension] = [
            "m": .objc,
            "mm": .objc,
            "cc": .cpp,
            "yml": .yaml
        ]
        
        // 首先检查特殊映射
        if let specialExt = specialMappings[raw.lowercased()] {
            self = specialExt
            return
        }
        
        // 尝试通过枚举的 rawValue 直接匹配
        if let fileExt = FileExtension(rawValue: raw.lowercased()) {
            self = fileExt
            return
        }
        
        // 如果都匹配不到，使用默认值
        self = def
    }
}

extension FileExtensionType {
    public init (_ ext: FileExtension) {
        switch ext {
        case .directory:
            self = .directory
        case .jpg, .png, .gif, .bmp, .tiff, .webp, .svg, .heic, .psd, .ai, .eps:
            self = .image
        case .mp4, .mov, .avi, .mkv, .webm, .ts:
            self = .video
        case .mp3, .wav, .aac, .flac:
            self = .audio
        case .txt, .log, .m3u8:
            self = .plainText
        case .pdf, .doc, .docx, .xls, .xlsx, .ppt, .pptx, .rtf, .xml, .json, .html:
            self = .formattedText
        case .zip, .rar, .sevenZ, .tar, .gz, .iso:
            self = .archive
        case .ttf, .otf, .woff, .woff2, .eot:
            self = .font
        case .exe, .dll, .apk, .ipa, .dmg:
            self = .package
        case .db, .sql, .sqlite, .mdb:
            self = .database
        case .css, .js, .py, .java, .classFile, .swift, .objc, .h, .c, .cpp, .cs, .go, .rs, .php, .rb, .sh, .bat, .cmd:
            self = .sourceCode
        case .reg, .ini, .yaml, .toml:
            self = .config
        default:
            self = .unknown
        }
    }
}

// MARK: - File Signature Detection
public struct FileSignatureDetector {
    
    // MARK: - File Signatures
    private static let signatures: [FileExtension: [UInt8]] = [
        .pdf: [0x25, 0x50, 0x44, 0x46], // %PDF
        .png: [0x89, 0x50, 0x4E, 0x47, 0x0D, 0x0A, 0x1A, 0x0A], // PNG
        .jpg: [0xFF, 0xD8, 0xFF], // JPEG
        .gif: [0x47, 0x49, 0x46, 0x38], // GIF87a/GIF89a
        .zip: [0x50, 0x4B, 0x03, 0x04], // ZIP
        .rar: [0x52, 0x61, 0x72, 0x21], // RAR
        .mp3: [0x49, 0x44, 0x33], // ID3v2 MP3
        .mp4: [0x00, 0x00, 0x00, 0x20, 0x66, 0x74, 0x79, 0x70], // MP4
        .doc: [0xD0, 0xCF, 0x11, 0xE0, 0xA1, 0xB1, 0x1A, 0xE1], // OLE2 Compound File
        .bmp: [0x42, 0x4D], // BM
        .tiff: [0x49, 0x49, 0x2A, 0x00], // II* (Intel) - 使用Intel版本作为主要检测
        .webp: [0x57, 0x45, 0x42, 0x50], // WEBP
        .wav: [0x52, 0x49, 0x46, 0x46], // RIFF
        .flac: [0x66, 0x4C, 0x61, 0x43], // fLaC
        .sevenZ: [0x37, 0x7A, 0xBC, 0xAF, 0x27, 0x1C], // 7z
        .tar: [0x75, 0x73, 0x74, 0x61, 0x72], // ustar
        .gz: [0x1F, 0x8B], // gzip
        .iso: [0x43, 0x44, 0x30, 0x30, 0x31], // CD001
        .exe: [0x4D, 0x5A], // MZ
        .dmg: [0x78, 0x01, 0x73, 0x0D, 0x62, 0x62, 0x60], // DMG
        .heic: [0x00, 0x00, 0x00, 0x20, 0x66, 0x74, 0x79, 0x70, 0x68, 0x65, 0x69, 0x63], // HEIC
        .mov: [0x00, 0x00, 0x00, 0x20, 0x66, 0x74, 0x79, 0x70, 0x71, 0x74, 0x20, 0x20], // MOV
        .avi: [0x52, 0x49, 0x46, 0x46], // RIFF
        .mkv: [0x1A, 0x45, 0xDF, 0xA3], // MKV
        .webm: [0x1A, 0x45, 0xDF, 0xA3], // WebM
        .psd: [0x38, 0x42, 0x50, 0x53], // 8BPS
        .ai: [0x25, 0x50, 0x44, 0x46], // %PDF
        .eps: [0xC5, 0xD0, 0xD3, 0xC6], // EPS
        .rtf: [0x7B, 0x5C, 0x72, 0x74, 0x66, 0x31], // {\rtf1
        .xml: [0x3C, 0x3F, 0x78, 0x6D, 0x6C, 0x20], // <?xml
        .json: [0x7B], // {
        .html: [0x3C, 0x21, 0x44, 0x4F, 0x43, 0x54, 0x59, 0x50, 0x45], // <!DOCTYPE
        .sqlite: [0x53, 0x51, 0x4C, 0x69, 0x74, 0x65, 0x20, 0x66, 0x6F, 0x72, 0x6D, 0x61, 0x74, 0x20, 0x33, 0x00], // SQLite format 3
        .ttf: [0x00, 0x01, 0x00, 0x00], // TTF
        .otf: [0x4F, 0x54, 0x54, 0x4F], // OTF
        .woff: [0x77, 0x4F, 0x46, 0x46], // wOFF
        .woff2: [0x77, 0x4F, 0x46, 0x32], // wOF2
        .eot: [0x4C, 0x50], // LP
        .ts: [0x47] // TS
    ]
    
    // MARK: - Public Methods
    public static func detectFileExtension(from filePath: String) -> FileExtension {
    guard let fileHandle = FileHandle(forReadingAtPath: filePath) else {
        return .unknown
    }
    
    // 读取文件头（最多读取32字节）
    let headerData = fileHandle.readData(ofLength: 32)
    fileHandle.closeFile()
    
    guard !headerData.isEmpty else {
        return .unknown
    }
    
    // 检查各种文件类型
        for (fileExt, signature) in signatures {
            if checkFileSignature(headerData, signature) {
                return handleSpecialCases(headerData: headerData, filePath: filePath, detectedExtension: fileExt)
            }
        }
        
        // 特殊处理 TIFF Motorola 字节序
        if checkFileSignature(headerData, [0x4D, 0x4D, 0x00, 0x2A]) {
            return .tiff
        }
        
        // 处理特殊格式
        if let specialExtension = handleSpecialFormats(headerData: headerData, filePath: filePath) {
            return specialExtension
        }
        
        // 检查是否为文本文件
        if isTextFile(headerData) {
            return FileExtension(filePath.pathExtension, def: .txt)
        }
        
        // 根据扩展名判断
        return FileExtension(filePath.pathExtension, def: .unknown)
    }
    
    // MARK: - Private Methods
    private static func checkFileSignature(_ data: Data, _ signature: [UInt8]) -> Bool {
        guard data.count >= signature.count else { return false }
        return data.withUnsafeBytes { bytes in
            memcmp(bytes.baseAddress, signature, signature.count) == 0
        }
    }
    
    private static func handleSpecialCases(headerData: Data, filePath: String, detectedExtension: FileExtension) -> FileExtension {
        switch detectedExtension {
        case .doc:
            return FileExtension(filePath.pathExtension, def: .doc)
        case .zip:
            return FileExtension(filePath.pathExtension, def: .zip)
        case .wav:
            return handleRIFFFormat(headerData: headerData)
        case .mp4:
            return handleMP4Format(headerData: headerData)
        default:
            return detectedExtension
        }
    }
    
    private static func handleSpecialFormats(headerData: Data, filePath: String) -> FileExtension? {
        // m3u8 特征判断：文件头以 #EXTM3U 开头
        if headerData.count >= 7 {
            let cstr = headerData.withUnsafeBytes { $0.bindMemory(to: CChar.self) }
            if strncmp(cstr.baseAddress, "#EXTM3U", 7) == 0 {
                return .m3u8
            }
        }
        
        return nil
    }
    
    private static func handleRIFFFormat(headerData: Data) -> FileExtension {
        let bytes = headerData.withUnsafeBytes { $0.bindMemory(to: UInt8.self) }
        if headerData.count >= 12 {
            if bytes[8] == UInt8(ascii: "W") && bytes[9] == UInt8(ascii: "A") && 
               bytes[10] == UInt8(ascii: "V") && bytes[11] == UInt8(ascii: "E") {
                return .wav
            } else if bytes[8] == UInt8(ascii: "A") && bytes[9] == UInt8(ascii: "V") && 
                      bytes[10] == UInt8(ascii: "I") && bytes[11] == UInt8(ascii: " ") {
                return .avi
            } else if bytes[8] == UInt8(ascii: "W") && bytes[9] == UInt8(ascii: "E") && 
                      bytes[10] == UInt8(ascii: "B") && bytes[11] == UInt8(ascii: "P") {
                return .webp
            }
        }
        return .unknown
    }
    
    private static func handleMP4Format(headerData: Data) -> FileExtension {
        let bytes = headerData.withUnsafeBytes { $0.bindMemory(to: UInt8.self) }
        if headerData.count >= 12 {
            if (bytes[8] == UInt8(ascii: "i") && bytes[9] == UInt8(ascii: "s") && 
                bytes[10] == UInt8(ascii: "o") && bytes[11] == UInt8(ascii: "m")) ||
               (bytes[8] == UInt8(ascii: "i") && bytes[9] == UInt8(ascii: "s") && 
                bytes[10] == UInt8(ascii: "o") && bytes[11] == UInt8(ascii: "2")) ||
               (bytes[8] == UInt8(ascii: "m") && bytes[9] == UInt8(ascii: "p") && 
                bytes[10] == UInt8(ascii: "4") && bytes[11] == UInt8(ascii: "1")) ||
               (bytes[8] == UInt8(ascii: "m") && bytes[9] == UInt8(ascii: "p") && 
                bytes[10] == UInt8(ascii: "4") && bytes[11] == UInt8(ascii: "2")) ||
               (bytes[8] == UInt8(ascii: "a") && bytes[9] == UInt8(ascii: "v") && 
                bytes[10] == UInt8(ascii: "c") && bytes[11] == UInt8(ascii: "1")) ||
               (bytes[8] == UInt8(ascii: "3") && bytes[9] == UInt8(ascii: "g") && 
                bytes[10] == UInt8(ascii: "p") && bytes[11] == UInt8(ascii: "4")) ||
               (bytes[8] == UInt8(ascii: "3") && bytes[9] == UInt8(ascii: "g") && 
                bytes[10] == UInt8(ascii: "p") && bytes[11] == UInt8(ascii: "5")) {
                return .mp4
            }
        }
        return .unknown
    }
    
    private static func isTextFile(_ headerData: Data) -> Bool {
    let bytes = headerData.withUnsafeBytes { $0.bindMemory(to: UInt8.self) }
    for i in 0..<headerData.count {
        if bytes[i] == 0 || (bytes[i] < 32 && bytes[i] != UInt8(ascii: "\n") && 
                            bytes[i] != UInt8(ascii: "\r") && bytes[i] != UInt8(ascii: "\t")) {
                return false
            }
        }
        return true
    }
}

// MARK: - Legacy Support
public func judgeExtensionFromContent(_ filePath: String) -> FileExtension {
    return FileSignatureDetector.detectFileExtension(from: filePath)
}
