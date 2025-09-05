//
//  PProgressDBM.swift
//  iOS
//
//  Created by Cityu on 2025/6/2.
//  Copyright © 2025 Cityu. All rights reserved.
//

import Foundation
import UIKit
import FMDB

// MARK: - Progress Model
private class ProgressModel {
    var key: String
    var progress: CGFloat
    var time: TimeInterval
    
    init() {
        self.key = ""
        self.progress = 0.0
        self.time = Date().timeIntervalSince1970
    }
    
    init(key: String, progress: CGFloat, time: TimeInterval) {
        self.key = key
        self.progress = progress
        self.time = time
    }
}

// MARK: - Progress Database Manager
@objc class PProgressDBM: NSObject {
    
    // MARK: - Properties
    private var tableName: String = ""
    private var dbQueue: FMDatabaseQueue?
    private var updateCache: [String: ProgressModel] = [:]
    private var modelMap: [String: ProgressModel] = [:]
    
    // MARK: - Initialization
    override init() {
        super.init()
        registerNotifications()
    }
    
    deinit {
        NotificationCenter.default.removeObserver(self)
        NSObject.cancelPreviousPerformRequests(withTarget: self)
        flushCache()
    }
    
    // MARK: - Public Methods
    @objc func setProgress(_ progress: CGFloat, forKey key: String) {
        guard !key.isEmpty else { return }
        
        let clampedProgress = max(0.0, min(1.0, progress)) // 确保进度在 0-1 之间
        
        // 先检查更新缓存中是否已有模型
        var model = updateCache[key]
        if model == nil {
            // 如果更新缓存中没有，再检查模型映射中是否有
            model = modelMap[key]
            if model == nil {
                // 如果都没有，才创建新模型
                model = ProgressModel()
                model?.key = key
            }
        }
        
        // 更新模型数据
        model?.progress = clampedProgress
        model?.time = Date().timeIntervalSince1970
        
        // 更新缓存和映射
        if let model = model {
            updateCache[key] = model
            modelMap[key] = model
        }
        
        NSObject.cancelPreviousPerformRequests(withTarget: self, selector: #selector(flushCache), object: nil)
        perform(#selector(flushCache), with: nil, afterDelay: 1.0)
    }
    
    @objc func progress(forKey key: String) -> CGFloat {
        return model(forKey: key)?.progress ?? 0.0
    }
    
    @objc func time(forKey key: String) -> TimeInterval {
        return model(forKey: key)?.time ?? 0.0
    }
    
    @objc class func dbm(withTable tableName: String) -> PProgressDBM? {
        guard !tableName.isEmpty else { return nil }
        
        let dbm = PProgressDBM()
        dbm.tableName = tableName
        dbm.setupDatabase()
        return dbm
    }
    
    // MARK: - Private Methods
    private func registerNotifications() {
        NotificationCenter.default.addObserver(
            self,
            selector: #selector(applicationWillTerminate),
            name: UIApplication.willTerminateNotification,
            object: nil
        )
        
        NotificationCenter.default.addObserver(
            self,
            selector: #selector(applicationDidEnterBackground),
            name: UIApplication.didEnterBackgroundNotification,
            object: nil
        )
    }
    
    private func dbPath() -> String {
        let path = NSSearchPathForDirectoriesInDomains(.documentDirectory, .userDomainMask, true).first ?? ""
        let dbDirectory = path + "/" + "db"
        
        if !FileManager.default.fileExists(atPath: dbDirectory) {
            try? FileManager.default.createDirectory(atPath: dbDirectory, withIntermediateDirectories: true, attributes: nil)
        }
        
        return dbDirectory + "/" + "PProgress.sqlite"
    }
    
    private func setupDatabase() {
        dbQueue = FMDatabaseQueue(path: dbPath())
        
        dbQueue?.inDatabase { db in
            let sql = "CREATE TABLE IF NOT EXISTS \(self.tableName) (key TEXT PRIMARY KEY, progress REAL, time REAL)"
            if !db.executeUpdate(sql, withArgumentsIn: []) {
                print("Failed to create table: \(self.tableName)")
            }
        }
    }
    
    private func model(forKey key: String) -> ProgressModel? {
        guard !key.isEmpty else { return nil }
        
        // 先从内存缓存中查找
        if let model = modelMap[key] {
            return model
        }
        
        // 从数据库中查找
        var dbModel: ProgressModel?
        dbQueue?.inDatabase { db in
            let sql = "SELECT progress, time FROM \(self.tableName) WHERE key = ?"
            if let rs = db.executeQuery(sql, withArgumentsIn: [key]) {
                if rs.next() {
                    dbModel = ProgressModel(
                        key: key,
                        progress: rs.double(forColumn: "progress"),
                        time: rs.double(forColumn: "time")
                    )
                    self.modelMap[key] = dbModel
                }
                rs.close()
            }
        }
        
        return dbModel
    }
    
    @objc private func flushCache() {
        guard !updateCache.isEmpty else { return }
        
        let cacheCopy = updateCache
        updateCache.removeAll()
        
        dbQueue?.inTransaction { db, rollback in
            for model in cacheCopy.values {
                let sql = "INSERT OR REPLACE INTO \(self.tableName) (key, progress, time) VALUES (?, ?, ?)"
                if !db.executeUpdate(sql, withArgumentsIn: [model.key, model.progress, model.time]) {
                    rollback.pointee = true
                    print("Failed to update progress for key: \(model.key)")
                    break
                }
            }
        }
    }
    
    // MARK: - Notification Handlers
    @objc private func applicationWillTerminate(_ notification: Notification) {
        flushCache()
    }
    
    @objc private func applicationDidEnterBackground(_ notification: Notification) {
        flushCache()
    }
}

