//
//  FileDirConf.swift
//  FileBrowse
//
//  Created by Cityu on 2025/6/18.
//

import Foundation

public class FileDirConf: NSObject, NSCoding {
    public var sortMode: FileSortMode = .byName
    public var isAscending: Bool = true
    public var password: String?
    public var dirPath: String?
    
    public static let configFileName = ".config.dcd"
    
    private enum CodingKeys: String {
        case sortMode = "sortMode"
        case dirPath = "dirPath"
        case isAscending = "isAscending"
        case password = "password"
    }
    
    public override init() {
        super.init()
        self.isAscending = true
        self.sortMode = .byName
        self.password = nil
    }
    
    // MARK: - NSCoding
    public func encode(with coder: NSCoder) {
        coder.encode(sortMode, forKey: CodingKeys.sortMode.rawValue)
        coder.encode(dirPath, forKey: CodingKeys.dirPath.rawValue)
        coder.encode(isAscending, forKey: CodingKeys.isAscending.rawValue)
        coder.encode(password, forKey: CodingKeys.password.rawValue)
    }
    
    public required init?(coder: NSCoder) {
        super.init()
        self.sortMode = coder.decodeObject(forKey: CodingKeys.sortMode.rawValue) as? FileSortMode ?? .byName
        self.dirPath = coder.decodeObject(forKey: CodingKeys.dirPath.rawValue) as? String
        self.isAscending = coder.decodeBool(forKey: CodingKeys.isAscending.rawValue)
        self.password = coder.decodeObject(forKey: CodingKeys.password.rawValue) as? String
    }
    
    // MARK: - Public Methods
    @discardableResult
    public func saveToPath(_ dirPath: String) -> Bool {
        self.dirPath = dirPath
        guard let data = try? NSKeyedArchiver.archivedData(withRootObject: self, requiringSecureCoding: false) else {
            return false
        }
        let configPath = FileDirConf.configFilePathForDir(dirPath)
        let url = URL(fileURLWithPath: configPath);
        do {
            try data.write(to: url)
            return true
        } catch {
            return false
        }
    }
    
    public static func loadFromPath(_ dirPath: String) -> FileDirConf? {
        let configPath = configFilePathForDir(dirPath)
        let url = URL(fileURLWithPath: configPath);

        guard let data = try? Data(contentsOf: url) else {
            return nil
        }
        
        guard let conf = try? NSKeyedUnarchiver.unarchivedObject(ofClass: FileDirConf.self, from: data) else {
            return nil
        }
        conf.dirPath = dirPath
        return conf
    }
    
    public static func configFilePathForDir(_ dirPath: String) -> String {
        return (dirPath as NSString).appendingPathComponent(configFileName)
    }
    
    // MARK: - Property Setters with Auto Save
    public func setSortMode(_ sortMode: FileSortMode) {
        if self.sortMode != sortMode {
            self.sortMode = sortMode
            autoSave()
        }
    }
    
    public func setIsAscending(_ isAscending: Bool) {
        if self.isAscending != isAscending {
            self.isAscending = isAscending
            autoSave()
        }
    }
    
    public func setPassword(_ password: String?) {
        if self.password != password {
            self.password = password
            autoSave()
        }
    }
    
    // MARK: - Private Methods
    private func autoSave() {
        if let dirPath = self.dirPath {
            saveToPath(dirPath)
        }
    }
}
