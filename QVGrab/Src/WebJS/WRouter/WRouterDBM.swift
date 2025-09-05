//
//  WRouterDBM.swift
//  iOS
//
//  Created by Cityu on 2025/6/2.
//  Copyright © 2025 Cityu. All rights reserved.
//

import Foundation
import UIKit
import FMDB

class WRouterModel: NSObject {
    var title: String = ""
    var url: String = ""
    fileprivate(set) var time: TimeInterval = 0
    
    fileprivate var idf: String = ""
    
    override init() {
        super.init()
        time = Date().timeIntervalSince1970
        idf = UUID().uuidString
    }
}

class WRouterDBM: NSObject {
    private(set) var models: [WRouterModel] = []
    
    private var tableName: String = ""
    private var dbQueue: FMDatabaseQueue?
    // 延迟批量更新相关
    private var updateCache: [String: WRouterModel] = [:]
    private var modelMap: [String: WRouterModel] = [:]
    
    private init(tableName: String) {
        super.init()
        self.tableName = tableName
        self.dbQueue = FMDatabaseQueue(path: dbPath)
        self.updateCache = [:]
        customInit()
        
        // 监听 app 进入后台/退出
        NotificationCenter.default.addObserver(self, selector: #selector(flushUpdateCache), name: UIApplication.willResignActiveNotification, object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(flushUpdateCache), name: UIApplication.willTerminateNotification, object: nil)
    }
    
    private var dbPath: String {
        let path = NSSearchPathForDirectoriesInDomains(.documentDirectory, .userDomainMask, true).first!
        let dbPath = path + "/db"
        if !FileManager.default.fileExists(atPath: dbPath) {
            try? FileManager.default.createDirectory(atPath: dbPath, withIntermediateDirectories: true, attributes: nil)
        }
        return dbPath + "/WRouter.sqlite"
    }
    
    private func customInit() {
        // 创建表 - 使用idf作为主键
        let sql = "CREATE TABLE IF NOT EXISTS \(tableName) (idf TEXT PRIMARY KEY, url TEXT, title TEXT, time REAL)"
        dbQueue?.inDatabase { db in
            db.executeUpdate(sql)
        }
        
        // 读取数据
        models.removeAll()
        modelMap.removeAll()
        let query = "SELECT * FROM \(tableName) ORDER BY time DESC"
        dbQueue?.inDatabase { db in
            if let rs = db.executeQuery(query) {
                while rs.next() {
                    let model = WRouterModel()
                    model.url = rs.string(forColumn: "url") ?? ""
                    model.title = rs.string(forColumn: "title") ?? ""
                    model.time = rs.double(forColumn: "time")
                    model.idf = rs.string(forColumn: "idf") ?? ""
                    self.models.append(model)
                    self.modelMap[model.url] = model
                    self.updateCache[model.idf] = model
                }
                rs.close()
            }
        }
    }
    
    @objc private func flushUpdateCache() {
        guard !updateCache.isEmpty else { return }
        
        // 复制缓存数据
        let cacheCopy = updateCache
        updateCache.removeAll()
        
        // 批量更新数据库
        dbQueue?.inTransaction { db, rollback in
            for (idf, model) in cacheCopy {
                // 检查记录是否存在
                let checkSql = "SELECT idf FROM \(self.tableName) WHERE idf = ?"
                if let rs = db.executeQuery(checkSql, withArgumentsIn: [idf]) {
                    let exists = rs.next()
                    rs.close()
                    
                    if exists {
                        // 更新已存在的记录
                        let updateSql = "UPDATE \(self.tableName) SET url = ?, title = ?, time = ? WHERE idf = ?"
                        db.executeUpdate(updateSql, withArgumentsIn: [model.url, model.title, model.time, idf])
                    } else {
                        // 插入新记录
                        let insertSql = "INSERT INTO \(self.tableName) (idf, url, title, time) VALUES (?, ?, ?, ?)"
                        db.executeUpdate(insertSql, withArgumentsIn: [idf, model.url, model.title, model.time])
                    }
                }
            }
        }
    }
    
    func cleanAll() {
        let sql = "DELETE FROM \(tableName)"
        dbQueue?.inDatabase { db in
            db.executeUpdate(sql)
        }
        models.removeAll()
        modelMap.removeAll()
        updateCache.removeAll()
    }
    
    deinit {
        NotificationCenter.default.removeObserver(self)
        NSObject.cancelPreviousPerformRequests(withTarget: self, selector: #selector(flushUpdateCache), object: nil)
        flushUpdateCache()
    }
    
    static func dbm(withTable tableName: String) -> WRouterDBM? {
        guard !tableName.isEmpty else { return nil }
        return WRouterDBM(tableName: tableName)
    }
    
    static func historyDBM() -> WRouterDBM {
        struct Static {
            static let instance = WRouterDBM(tableName: "webHistory")
        }
        return Static.instance
    }
    
    static func bookmarkDBM() -> WRouterDBM {
        struct Static {
            static let instance = WRouterDBM(tableName: "webBookmark")
        }
        return Static.instance
    }
    
    func addUrl(_ url: String, title: String) {
        guard !url.isEmpty else { return }
        
        // 检查是否已存在
        var model = modelMap[url]
        if model == nil {
            // 不存在则创建新模型
            model = WRouterModel()
            model!.url = url
            model!.title = title
            model!.time = Date().timeIntervalSince1970
            model!.idf = UUID().uuidString
            
            // 直接插入到数组第一位
            models.insert(model!, at: 0)
            modelMap[url] = model!
            
            // 添加到更新缓存
            updateCache[model!.idf] = model!
        } else {
            // 已存在则更新数据
            model!.title = title
            model!.time = Date().timeIntervalSince1970

            // 从原位置移除
            if let oldIndex = models.firstIndex(of: model!) {
                models.remove(at: oldIndex)
            }
            
            // 插入到第一位
            models.insert(model!, at: 0)
            
            // 添加到更新缓存
            updateCache[model!.idf] = model!
        }
        
        // 延迟执行批量更新
        NSObject.cancelPreviousPerformRequests(withTarget: self, selector: #selector(flushUpdateCache), object: nil)
        perform(#selector(flushUpdateCache), with: nil, afterDelay: 0.5)
    }
    
    func delUrl(_ url: String) {
        guard !url.isEmpty else { return }
        
        // 从缓存中获取模型
        guard let model = modelMap[url] else { return }
        
        // 从内存中移除
        if let idx = models.firstIndex(of: model) {
            models.remove(at: idx)
        }
        
        // 从映射中移除
        modelMap.removeValue(forKey: url)
        
        // 从更新缓存中移除
        updateCache.removeValue(forKey: model.idf)
        
        // 直接删除数据库记录 - 使用idf作为主键
        let sql = "DELETE FROM \(tableName) WHERE idf = ?"
        dbQueue?.inDatabase { db in
            db.executeUpdate(sql, withArgumentsIn: [model.idf])
        }
    }
    
    func hasUrl(_ url: String) -> Bool {
        guard !url.isEmpty else { return false }
        
        // 首先检查内存中的映射
        if modelMap[url] != nil {
            return true
        }
        
        // 如果内存中没有，检查数据库
        var exists = false
        let sql = "SELECT url FROM \(tableName) WHERE url = ?"
        dbQueue?.inDatabase { db in
            if let rs = db.executeQuery(sql, withArgumentsIn: [url]) {
                exists = rs.next()
                rs.close()
            }
        }
        
        return exists
    }
    
    func updateModel(_ model: WRouterModel) {
        updateCache[model.idf] = model
        NSObject.cancelPreviousPerformRequests(withTarget: self, selector: #selector(flushUpdateCache), object: nil)
        perform(#selector(flushUpdateCache), with: nil, afterDelay: 0.5)
    }
}
