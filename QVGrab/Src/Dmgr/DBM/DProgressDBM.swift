//
//  DProgressDBM.swift
//  iOS
//
//  Created by Cityu on 2025/5/15.
//  Copyright © 2025 Cityu. All rights reserved.
//

import Foundation
import UIKit
import FMDB

class DProgressDBM: NSObject {
    
    private let tableName: String
    private let dbQueue: FMDatabaseQueue
    private var updateCache: [String: DProgressModel] = [:]
    private var modelMap: [String: DProgressModel] = [:]
    
    private(set) var models: [DProgressModel] = []
    
    private init(tableName: String) {
        self.tableName = tableName
        self.dbQueue = FMDatabaseQueue(path: Self.dbPath)!
        super.init()
        customInit()
        
        // 监听 app 进入后台/退出
        NotificationCenter.default.addObserver(
            self,
            selector: #selector(flushUpdateCache),
            name: UIApplication.willResignActiveNotification,
            object: nil
        )
        NotificationCenter.default.addObserver(
            self,
            selector: #selector(flushUpdateCache),
            name: UIApplication.willTerminateNotification,
            object: nil
        )
    }
    
    private static var dbPath: String {
        let path = NSSearchPathForDirectoriesInDomains(.documentDirectory, .userDomainMask, true).first!
        let dbPath = path + "/" + "db"
        
        if !FileManager.default.fileExists(atPath: dbPath) {
            try? FileManager.default.createDirectory(atPath: dbPath, withIntermediateDirectories: true, attributes: nil)
        }
        
        return dbPath + "/" + "DProgress.sqlite"
    }
    
    private func customInit() {
        // 创建表，新增 mimeType 和 src 字段
        let sql = "CREATE TABLE IF NOT EXISTS \(tableName) (mid TEXT PRIMARY KEY, url TEXT, name TEXT, progress REAL, mimeType TEXT, src TEXT)"
        
        dbQueue.inDatabase { db in
            try? db.executeUpdate(sql, values: nil)
        }
        
        // 读取数据
        models.removeAll()
        modelMap.removeAll()
        
        let query = "SELECT * FROM \(tableName)"
        dbQueue.inDatabase { db in
            if let rs = db.executeQuery(query, withArgumentsIn: []) {
                while rs.next() {
                    let model = DProgressModel()
                    model.mid = rs.string(forColumn: "mid") ?? ""
                    model.url = rs.string(forColumn: "url") ?? ""
                    model.name = rs.string(forColumn: "name") ?? ""
                    model.progress = Float(rs.double(forColumn: "progress"))
                    model.mimeType = rs.string(forColumn: "mimeType")
                    model.src = rs.string(forColumn: "src")
                    
                    self.models.append(model)
                    self.modelMap[model.mid] = model
                }
                rs.close()
            }
        }
    }
    
    func add(_ model: DProgressModel) {
        guard !model.mid.isEmpty else { return }
        
        let sql = "INSERT OR REPLACE INTO \(tableName) (mid, url, name, progress, mimeType, src) VALUES (?, ?, ?, ?, ?, ?)"
        
        dbQueue.inDatabase { db in
           try? db.executeUpdate(sql, values: [model.mid, model.url, model.name, model.progress, model.mimeType ?? "", model.src ?? ""])
        }
        
        // 更新内存
        let oldModel = modelMap[model.mid]
        if oldModel == nil {
            models.append(model)
            modelMap[model.mid] = model
        }
    }
    
    func del(_ model: DProgressModel) {
        guard !model.mid.isEmpty else { return }
        
        let sql = "DELETE FROM \(tableName) WHERE mid = ?"
        
        dbQueue.inDatabase { db in
            try? db.executeUpdate(sql, values: [model.mid])
        }
        
        // 更新内存
        if let oldModel = modelMap[model.mid] {
            if let idx = models.firstIndex(of: oldModel) {
                models.remove(at: idx)
            }
        }
        
        // 同步移除 updateCache
        updateCache.removeValue(forKey: model.mid)
        // 同步移除 modelMap
        modelMap.removeValue(forKey: model.mid)
    }
    
    func update(_ model: DProgressModel) {
        guard !model.mid.isEmpty else { return }
        
        let oldModel = modelMap[model.mid]
        guard oldModel != nil else { return }
        
        updateCache[model.mid] = model
        
        NSObject.cancelPreviousPerformRequests(withTarget: self, selector: #selector(flushUpdateCache), object: nil)
        perform(#selector(flushUpdateCache), with: nil, afterDelay: 0.5)
    }
    
    @objc private func flushUpdateCache() {
        guard !updateCache.isEmpty else { return }
        
        let cacheCopy = updateCache
        updateCache.removeAll()
        
        dbQueue.inTransaction { db, rollback in
            for (mid, model) in cacheCopy {
                let sql = "UPDATE \(self.tableName) SET url = ?, name = ?, progress = ?, mimeType = ?, src = ? WHERE mid = ?"
                try? db.executeUpdate(sql, values: [model.url, model.name, model.progress, model.mimeType ?? "", model.src ?? "", model.mid])
            }
        }
    }
    
    deinit {
        NotificationCenter.default.removeObserver(self)
        NSObject.cancelPreviousPerformRequests(withTarget: self, selector: #selector(flushUpdateCache), object: nil)
        flushUpdateCache()
    }
    
    // MARK: - 数据迁移方法
//    
//    private func migrateDatabaseIfNeeded() {
//        dbQueue.inDatabase { db in
//            // 使用 FMDatabase 分类进行批量迁移
//            let success = db.modifyTable(self.tableName) { defs in
//                // 配置需要迁移的字段
//                defs["src"] = "TEXT DEFAULT ''"
//            }
//            
//            if success {
//                print("数据迁移完成：表 \(self.tableName)")
//            } else {
//                print("数据迁移失败：表 \(self.tableName)")
//            }
//        }
//    }
    
    static func dbmWithTable(_ tableName: String) -> DProgressDBM? {
        guard !tableName.isEmpty else { return nil }
        return DProgressDBM(tableName: tableName)
    }
}
