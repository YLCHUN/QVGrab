////
////  FMDatabase+Table.swift
////  iOS
////
////  Created by Cityu on 2025/7/21.
////  Copyright © 2025 Cityu. All rights reserved.
////
//
//import FMDB
//
//extension FMDatabase {
//    func executeUpdate(_ sql: String) -> Bool {
//        return executeUpdate(sql, withArgumentsIn: [])
//    }
//    func executeQuery(_ sql: String)->FMResultSet? {
//        return try? executeQuery(sql, values: nil)
//    }
//    /// 创建表
//    /// - Parameters:
//    ///   - tableName: 表名
//    ///   - columns: 字段配置闭包，参数为字段定义字典，key为字段名，value为字段定义
//    /// - Returns: 是否创建成功
//    func createTable(_ tableName: String, columns: @escaping (inout [String: String]) -> Void) -> Bool {
//        guard !tableName.isEmpty else { return false }
//        
//        var columnDefinitions: [String: String] = [:]
//        columns(&columnDefinitions)
//        
//        if columnDefinitions.isEmpty {
//            print("表 \(tableName) 没有定义任何字段")
//            return false
//        }
//        
//        // 构建 CREATE TABLE SQL 语句
//        let columnDefs = columnDefinitions.map { "\($0.key) \($0.value)" }
//        let createTableSQL = "CREATE TABLE IF NOT EXISTS \(tableName) (\(columnDefs.joined(separator: ", ")))"
//        
//        // 执行创建表操作
//        let success = executeUpdate(createTableSQL)
//        if success {
//            print("表 \(tableName) 创建成功")
//        } else {
//            print("表 \(tableName) 创建失败: \(lastErrorMessage())")
//        }
//        
//        return success
//    }
//    
//    /// 批量插入表数据
//    /// - Parameters:
//    ///   - tableName: 表名
//    ///   - rows: 插入行数
//    ///   - values: 值配置闭包，参数为行索引和当前行的值字典
//    /// - Returns: 是否插入成功
//    func insertTable(_ tableName: String, rows: Int, values: @escaping (Int, inout [String: String]) -> Void) -> Bool {
//        guard !tableName.isEmpty, rows > 0 else { return false }
//        
//        // 使用事务保证批量插入的性能和一致性
//        guard executeUpdate("BEGIN TRANSACTION") else {
//            print("开始事务失败")
//            return false
//        }
//        
//        do {
//            var allSuccess = true
//            
//            for i in 0..<rows {
//                var rowValues: [String: String] = [:]
//                values(i, &rowValues)
//                
//                if rowValues.isEmpty {
//                    print("第 \(i) 行没有设置任何值，跳过")
//                    continue
//                }
//                
//                // 构建 INSERT SQL 语句
//                let columnNames = Array(rowValues.keys)
//                let columnValues = Array(rowValues.values)
//                
//                let columnsStr = columnNames.joined(separator: ", ")
//                let placeholders = Array(repeating: "?", count: columnValues.count).joined(separator: ", ")
//                let insertSQL = "INSERT INTO \(tableName) (\(columnsStr)) VALUES (\(placeholders))"
//                
//                // 执行插入操作
//                let success = executeUpdate(insertSQL, withArgumentsIn: columnValues)
//                if !success {
//                    print("插入第 \(i) 行失败: \(lastErrorMessage())")
//                    allSuccess = false
//                    break
//                }
//            }
//            
//            if allSuccess {
//                // 提交事务
//                guard executeUpdate("COMMIT") else {
//                    print("事务提交失败")
//                    executeUpdate("ROLLBACK")
//                    return false
//                }
//                print("成功插入 \(rows) 行数据到表 \(tableName)")
//                return true
//            } else {
//                // 回滚事务
//                executeUpdate("ROLLBACK")
//                return false
//            }
//            
//        } catch {
//            print("批量插入异常：\(error)")
//            executeUpdate("ROLLBACK")
//            return false
//        }
//    }
//    
//    /// 迁移表字段
//    /// - Parameters:
//    ///   - tableName: 表名
//    ///   - columns: 迁移配置闭包，参数为字段迁移配置字典，key为字段名，value为字段定义（包含类型和默认值），value 空字符串表示删除字段
//    /// - Returns: 是否迁移成功
//    func modifyTable(_ tableName: String, columns: @escaping (inout [String: String]) -> Void) -> Bool {
//        guard !tableName.isEmpty else { return false }
//        
//        var columnMigrations: [String: String] = [:]
//        columns(&columnMigrations)
//        
//        if columnMigrations.isEmpty {
//            return true // 没有需要迁移的字段，返回成功
//        }
//        
//        // 第1步：读取表中的字段
//        var existingColumns: [String: [String: Any]] = [:]
//        let rs = executeQuery("PRAGMA table_info(\(tableName))")
//        while rs?.next() == true {
//            let columnName = rs?.string(forColumn: "name") ?? ""
//            let columnType = rs?.string(forColumn: "type") ?? ""
//            let columnDefault = rs?.string(forColumn: "dflt_value") ?? ""
//            let notNull = rs?.bool(forColumn: "notnull") ?? false
//            let isPrimaryKey = rs?.bool(forColumn: "pk") ?? false
//            
//            existingColumns[columnName] = [
//                "type": columnType,
//                "default": columnDefault,
//                "notnull": notNull,
//                "primaryKey": isPrimaryKey
//            ]
//        }
//        rs?.close()
//        
//        // 第2步：比较字段，确定需要处理的字段
//        var columnsToAdd: [[String: String]] = []
//        var columnsToModify: [[String: Any]] = []
//        var columnsToDelete: [String] = []
//        var columnsToKeep: [[String: Any]] = []
//        
//        // 首先处理 migrationsBlock 中指定的字段
//        for (columnName, columnDefinition) in columnMigrations {
//            let existingColumn = existingColumns[columnName]
//            
//            if columnDefinition.isEmpty {
//                // 空字符串表示删除字段
//                if existingColumn != nil {
//                    columnsToDelete.append(columnName)
//                }
//            } else if existingColumn == nil {
//                // 字段不存在，需要新增
//                columnsToAdd.append([
//                    "name": columnName,
//                    "definition": columnDefinition
//                ])
//            } else {
//                // 字段存在，检查是否需要修改
//                let newColumnInfo = parseColumnDefinition(columnDefinition)
//                let existingType = existingColumn?["type"] as? String ?? ""
//                let existingDefault = existingColumn?["default"] as? String ?? ""
//                let existingNotNull = existingColumn?["notnull"] as? Bool ?? false
//                let newType = newColumnInfo["type"] as? String ?? ""
//                let newDefault = newColumnInfo["default"] as? String ?? ""
//                let newNotNull = newColumnInfo["notnull"] as? Bool ?? false
//                
//                let typeMatch = existingType.caseInsensitiveCompare(newType) == .orderedSame
//                let defaultMatch = existingDefault == newDefault
//                let notNullMatch = existingNotNull == newNotNull
//                
//                if typeMatch && defaultMatch && notNullMatch {
//                    // 字段完全一致，保留
//                    columnsToKeep.append([
//                        "name": columnName,
//                        "definition": columnDefinition,
//                        "existing": existingColumn as Any
//                    ])
//                } else {
//                    // 字段需要修改
//                    columnsToModify.append([
//                        "name": columnName,
//                        "oldDefinition": existingColumn as Any,
//                        "newDefinition": columnDefinition
//                    ])
//                }
//            }
//        }
//        
//        // 然后处理 migrationsBlock 中未指定但存在的字段（保留这些字段）
//        for (columnName, columnInfo) in existingColumns {
//            // 如果字段不在 migrationsBlock 中，且不在删除列表中，则保留
//            if columnMigrations[columnName] == nil && !columnsToDelete.contains(columnName) {
//                // 构建字段定义字符串
//                var columnDef = columnInfo["type"] as? String ?? ""
//                if columnInfo["notnull"] as? Bool == true {
//                    columnDef += " NOT NULL"
//                }
//                if let defaultVal = columnInfo["default"] as? String, !defaultVal.isEmpty {
//                    columnDef += " DEFAULT \(defaultVal)"
//                }
//                
//                columnsToKeep.append([
//                    "name": columnName,
//                    "definition": columnDef,
//                    "existing": columnInfo
//                ])
//            }
//        }
//        
//        // 检查是否有需要处理的字段
//        if columnsToAdd.isEmpty && columnsToModify.isEmpty && columnsToDelete.isEmpty {
//            print("表 \(tableName) 无需迁移，所有字段配置一致")
//            return true
//        }
//        
//        // 第3步：计算新的完整表结构
//        var newTableColumns: [[String: String]] = []
//        
//        // 添加保留的字段
//        for column in columnsToKeep {
//            if let name = column["name"] as? String, let definition = column["definition"] as? String {
//                newTableColumns.append([
//                    "name": name,
//                    "definition": definition
//                ])
//            }
//        }
//        
//        // 添加修改后的字段
//        for column in columnsToModify {
//            if let name = column["name"] as? String, let newDefinition = column["newDefinition"] as? String {
//                newTableColumns.append([
//                    "name": name,
//                    "definition": newDefinition
//                ])
//            }
//        }
//        
//        // 添加新字段
//        newTableColumns.append(contentsOf: columnsToAdd)
//        
//        // 构建新表结构 SQL
//        let columnDefinitions = newTableColumns.map { "\($0["name"]!) \($0["definition"]!)" }
//        let newTableSQL = "CREATE TABLE \(tableName)_new (\(columnDefinitions.joined(separator: ", ")))"
//        
//        // 第4-7步：执行表重建和数据迁移（使用事务保证完整性）
//        return executeTableMigration(
//            tableName: tableName,
//            newTableSQL: newTableSQL,
//            existingColumns: existingColumns,
//            columnsToKeep: columnsToKeep,
//            columnsToModify: columnsToModify,
//            columnsToAdd: columnsToAdd,
//            columnsToDelete: columnsToDelete
//        )
//    }
//    
//    /// 执行表重建和数据迁移
//    private func executeTableMigration(
//        tableName: String,
//        newTableSQL: String,
//        existingColumns: [String: [String: Any]],
//        columnsToKeep: [[String: Any]],
//        columnsToModify: [[String: Any]],
//        columnsToAdd: [[String: String]],
//        columnsToDelete: [String]
//    ) -> Bool {
//        
//        let tempTableName = "\(tableName)_tmp"
//        let newTableName = "\(tableName)_new"
//        
//        // 使用事务保证操作的原子性
//        // 开始事务
//        guard executeUpdate("BEGIN TRANSACTION") else {
//            print("开始事务失败")
//            return false
//        }
//        
//        // 重命名原表为临时表
//        let renameSQL = "ALTER TABLE \(tableName) RENAME TO \(tempTableName)"
//        guard executeUpdate(renameSQL) else {
//            print("重命名表失败：\(tableName) -> \(tempTableName)")
//            executeUpdate("ROLLBACK")
//            return false
//        }
//        
//        // 创建新表
//        guard executeUpdate(newTableSQL) else {
//            print("创建新表失败：\(newTableName)")
//            executeUpdate("ROLLBACK")
//            return false
//        }
//        
//        do {
//            // 第4步：将原表重命名为临时表（已在上面执行）
//            print("表重命名成功：\(tableName) -> \(tempTableName)")
//            
//            // 第5步：用新表结构创建表（已在上面执行）
//            print("新表创建成功：\(newTableName)")
//            
//            // 第6步：数据迁移
//            guard migrateDataFromTable(
//                fromTable: tempTableName,
//                toTable: newTableName,
//                existingColumns: existingColumns,
//                columnsToKeep: columnsToKeep,
//                columnsToModify: columnsToModify,
//                columnsToAdd: columnsToAdd,
//                columnsToDelete: columnsToDelete
//            ) else {
//                print("数据迁移失败")
//                executeUpdate("ROLLBACK")
//                return false
//            }
//            print("数据迁移成功")
//            
//            // 第7.2步：操作成功，删除临时表
//            let dropSQL = "DROP TABLE \(tempTableName)"
//            if !executeUpdate(dropSQL) {
//                print("删除临时表失败：\(tempTableName)")
//                // 这里不回滚，因为主要操作已经成功
//            } else {
//                print("临时表删除成功：\(tempTableName)")
//            }
//            
//            // 将新表重命名为原表名
//            let finalRenameSQL = "ALTER TABLE \(newTableName) RENAME TO \(tableName)"
//            guard executeUpdate(finalRenameSQL) else {
//                print("重命名新表失败：\(newTableName) -> \(tableName)")
//                executeUpdate("ROLLBACK")
//                return false
//            }
//            print("表迁移完成：\(tableName)")
//            
//            // 提交事务
//            guard executeUpdate("COMMIT") else {
//                print("事务提交失败")
//                executeUpdate("ROLLBACK")
//                return false
//            }
//            
//            return true
//            
//        } catch {
//            print("表迁移异常：\(error)")
//            executeUpdate("ROLLBACK")
//            return false
//        }
//    }
//    
//    /// 迁移数据从旧表到新表
//    private func migrateDataFromTable(
//        fromTable: String,
//        toTable: String,
//        existingColumns: [String: [String: Any]],
//        columnsToKeep: [[String: Any]],
//        columnsToModify: [[String: Any]],
//        columnsToAdd: [[String: String]],
//        columnsToDelete: [String]
//    ) -> Bool {
//        
//        // 构建列名列表（新表的列名）
//        var newColumnNames: [String] = []
//        var oldColumnNames: [String] = []
//        
//        // 添加保留的字段
//        for column in columnsToKeep {
//            if let name = column["name"] as? String {
//                newColumnNames.append(name)
//                oldColumnNames.append(name)
//            }
//        }
//        
//        // 添加修改后的字段
//        for column in columnsToModify {
//            if let name = column["name"] as? String {
//                newColumnNames.append(name)
//                oldColumnNames.append(name) // 使用原字段名读取数据
//            }
//        }
//        
//        // 添加新字段
//        for column in columnsToAdd {
//            if let name = column["name"] {
//                newColumnNames.append(name)
//                oldColumnNames.append("NULL") // 新字段用 NULL 填充
//            }
//        }
//        
//        // 构建 INSERT SQL
//        let columnsStr = newColumnNames.joined(separator: ", ")
//        let valuesStr = oldColumnNames.joined(separator: ", ")
//        let insertSQL = "INSERT INTO \(toTable) (\(columnsStr)) SELECT \(valuesStr) FROM \(fromTable)"
//        
//        return executeUpdate(insertSQL)
//    }
//    
//    /// 解析字段定义字符串
//    private func parseColumnDefinition(_ columnDefinition: String) -> [String: Any] {
//        guard !columnDefinition.isEmpty else {
//            return ["type": "", "default": "", "notnull": false]
//        }
//        
//        var result: [String: Any] = [:]
//        let components = columnDefinition.components(separatedBy: .whitespaces)
//        let cleanComponents = components.filter { !$0.isEmpty }
//        
//        if cleanComponents.isEmpty {
//            return ["type": "", "default": "", "notnull": false]
//        }
//        
//        // 第一个组件是类型
//        result["type"] = cleanComponents[0]
//        result["default"] = ""
//        result["notnull"] = false
//        
//        // 解析其他组件
//        var i = 1
//        while i < cleanComponents.count {
//            let component = cleanComponents[i]
//            
//            if component.caseInsensitiveCompare("DEFAULT") == .orderedSame {
//                // 下一个组件是默认值
//                if i + 1 < cleanComponents.count {
//                    result["default"] = cleanComponents[i + 1]
//                    i += 1 // 跳过默认值
//                }
//            } else if component.caseInsensitiveCompare("NOT") == .orderedSame {
//                // 检查下一个是否是 NULL
//                if i + 1 < cleanComponents.count &&
//                   cleanComponents[i + 1].caseInsensitiveCompare("NULL") == .orderedSame {
//                    result["notnull"] = true
//                    i += 1 // 跳过 NULL
//                }
//            }
//            i += 1
//        }
//        
//        return result
//    }
//    
//    /// 检查字段是否存在
//    /// - Parameters:
//    ///   - columnName: 字段名
//    ///   - tableName: 表名
//    /// - Returns: 字段是否存在
//    func columnExists(_ columnName: String, inTable tableName: String) -> Bool {
//        guard !tableName.isEmpty && !columnName.isEmpty else { return false }
//        
//        let rs = executeQuery("PRAGMA table_info(\(tableName))")
//        while rs?.next() == true {
//            let existingColumnName = rs?.string(forColumn: "name") ?? ""
//            if existingColumnName == columnName {
//                rs?.close()
//                return true
//            }
//        }
//        rs?.close()
//        return false
//    }
//    
//    /// 查询表数据
//    /// - Parameters:
//    ///   - tableName: 表名
//    ///   - conditions: 查询条件配置闭包，参数为查询条件字典，key为字段名，value为查询值
//    ///   - result: 查询结果处理闭包，参数为查询结果集
//    /// - Returns: 是否查询成功
//    func queryTable(
//        _ tableName: String,
//        conditions: @escaping (inout [String: String]) -> Void,
//        result: @escaping (FMResultSet) -> Void
//    ) -> Bool {
//        return queryTable(tableName, conditions: conditions, orderBy: nil, limit: NSNotFound, result: result)
//    }
//    
//    /// 查询表数据（带排序和限制）
//    /// - Parameters:
//    ///   - tableName: 表名
//    ///   - conditions: 查询条件配置闭包
//    ///   - orderBy: 排序字段（可选）
//    ///   - limit: 限制条数（可选，NSNotFound表示不限制）
//    ///   - result: 查询结果处理闭包
//    /// - Returns: 是否查询成功
//    func queryTable(
//        _ tableName: String,
//        conditions: @escaping (inout [String: String]) -> Void,
//        orderBy: String?,
//        limit: Int,
//        result: @escaping (FMResultSet) -> Void
//    ) -> Bool {
//        guard !tableName.isEmpty else { return false }
//        
//        // 创建查询条件字典
//        var queryConditions: [String: String] = [:]
//        
//        // 执行闭包配置查询条件
//        conditions(&queryConditions)
//        
//        // 构建 SELECT SQL 语句
//        var selectSQL = "SELECT * FROM \(tableName)"
//        var arguments: [Any] = []
//        
//        // 添加 WHERE 条件
//        if !queryConditions.isEmpty {
//            let whereClauses = queryConditions.map { "\($0.key) = ?" }
//            arguments.append(contentsOf: queryConditions.values)
//            selectSQL += " WHERE \(whereClauses.joined(separator: " AND "))"
//        }
//        
//        // 添加 ORDER BY
//        if let orderBy = orderBy, !orderBy.isEmpty {
//            selectSQL += " ORDER BY \(orderBy)"
//        }
//        
//        // 添加 LIMIT
//        if limit != NSNotFound && limit > 0 {
//            selectSQL += " LIMIT \(limit)"
//        }
//        
//        // 执行查询
//        guard let rs = executeQuery(selectSQL, withArgumentsIn: arguments) else {
//            print("查询表 \(tableName) 失败: \(lastErrorMessage())")
//            return false
//        }
//        
//        // 处理查询结果
//        do {
//            result(rs)
//            print("查询表 \(tableName) 成功")
//            rs.close()
//            return true
//        } catch {
//            print("处理查询结果异常：\(error)")
//            rs.close()
//            return false
//        }
//    }
//    
//    /// 删除表数据
//    /// - Parameters:
//    ///   - tableName: 表名
//    ///   - conditions: 删除条件配置闭包，参数为删除条件字典，key为字段名，value为删除条件值
//    /// - Returns: 是否删除成功
//    func deleteTable(
//        _ tableName: String,
//        conditions: @escaping (inout [String: String]) -> Void
//    ) -> Bool {
//        return deleteTable(tableName, conditions: conditions, limit: NSNotFound)
//    }
//    
//    /// 删除表数据（带限制）
//    /// - Parameters:
//    ///   - tableName: 表名
//    ///   - conditions: 删除条件配置闭包
//    ///   - limit: 限制删除条数（可选，NSNotFound表示不限制）
//    /// - Returns: 是否删除成功
//    func deleteTable(
//        _ tableName: String,
//        conditions: @escaping (inout [String: String]) -> Void,
//        limit: Int
//    ) -> Bool {
//        guard !tableName.isEmpty else { return false }
//        
//        // 创建删除条件字典
//        var deleteConditions: [String: String] = [:]
//        
//        // 执行闭包配置删除条件
//        conditions(&deleteConditions)
//        
//        // 如果没有删除条件，可以选择是否允许删除所有数据
//        if deleteConditions.isEmpty {
//            print("警告：删除表 \(tableName) 时没有指定条件，将删除所有数据")
//            // 这里可以根据需要决定是否允许无条件删除
//            // return false // 如果禁止无条件删除，取消注释这行
//        }
//        
//        // 构建 DELETE SQL 语句
//        var deleteSQL = "DELETE FROM \(tableName)"
//        var arguments: [Any] = []
//        
//        // 添加 WHERE 条件
//        if !deleteConditions.isEmpty {
//            let whereClauses = deleteConditions.map { "\($0.key) = ?" }
//            arguments.append(contentsOf: deleteConditions.values)
//            deleteSQL += " WHERE \(whereClauses.joined(separator: " AND "))"
//        }
//        
//        // 添加 LIMIT
//        if limit != NSNotFound && limit > 0 {
//            deleteSQL += " LIMIT \(limit)"
//        }
//        
//        // 执行删除操作
//        let success = executeUpdate(deleteSQL, withArgumentsIn: arguments)
//        if success {
//            print("删除表 \(tableName) 数据成功，影响行数：\(changes)")
//        } else {
//            print("删除表 \(tableName) 数据失败: \(lastErrorMessage())")
//        }
//        
//        return success
//    }
//}
//
