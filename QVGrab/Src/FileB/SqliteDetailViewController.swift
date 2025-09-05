//
//  SqliteDetailViewController.swift
//  iOS
//
//  Created by Cityu on 2025/7/16.
//  Copyright © 2025 Cityu. All rights reserved.
//

import UIKit
import FMDB

class SqliteDetailViewController: UIViewController {
    
    /// 需要展示的Sqlite数据库文件路径
    var dbFilePath: String = ""
    
    private var tableNames: [String] = []
    
    override func viewDidLoad() {
        super.viewDidLoad()
        title = (dbFilePath as NSString).lastPathComponent
        
        if #available(iOS 13.0, *) {
            view.backgroundColor = UIColor.systemBackground
        } else {
            view.backgroundColor = UIColor.white
        }
        
        loadTableNames()
    }
    
    private func loadTableNames() {
        guard !dbFilePath.isEmpty else { return }
        
        let db = FMDatabase(path: dbFilePath)
        guard db.open() else {
            print("无法打开数据库: \(dbFilePath)")
            return
        }
        
        var names: [String] = []
        if let rs = db.executeQuery("SELECT name FROM sqlite_master WHERE type='table' AND name NOT LIKE 'sqlite_%' ORDER BY name;") {
            while rs.next() {
                if let name = rs.string(forColumn: "name") {
                    names.append(name)
                }
            }
            rs.close()
        }
        db.close()
        
        tableNames = names
        setupTableListView()
    }
    
    private func setupTableListView() {
        // 用UITableView简单展示表名，点击后进入collectionView展示表内容
        let tableView = UITableView(frame: view.bounds, style: .plain)
        tableView.delegate = self
        tableView.dataSource = self
        tableView.autoresizingMask = [.flexibleWidth, .flexibleHeight]
        tableView.tag = 1001
        view.addSubview(tableView)
        tableView.reloadData()
    }
    
    private func loadTableContent(_ tableName: String) {
        guard !dbFilePath.isEmpty && !tableName.isEmpty else { return }
        
        let db = FMDatabase(path: dbFilePath)
        guard db.open() else {
            print("无法打开数据库: \(dbFilePath)")
            return
        }
        
        // 获取表结构
        var schema: [[String: Any]] = [] // 当前选中表结构
        var colNames: [String] = []
        
        if let schemaRS = db.getTableSchema(tableName) {
            while schemaRS.next() {
                var col: [String: Any] = [:]
                for i in 0..<schemaRS.columnCount {
                    if let colName = schemaRS.columnName(for: i) {
                        col[colName] = schemaRS.object(forColumnIndex: i) ?? ""
                    }
                }
                schema.append(col)
                if let name = col["name"] as? String {
                    colNames.append(name)
                }
            }
            schemaRS.close()
        }
        
        // 获取表内容
        var datas: [[String: Any]] = [] // 当前选中表的数据
        let sql = "SELECT * FROM \(tableName)"
        if let rs = db.executeQuery(sql) {
            while rs.next() {
                var row: [String: Any] = [:]
                for colName in colNames {
                    let value = rs.object(forColumn: colName) ?? ""
                    row[colName] = value
                }
                datas.insert(row, at: 0)
            }
            rs.close()
        }
        db.close()
        
        let excelCtrl = ExcelGridCollectionViewController()
        excelCtrl.names = colNames
        excelCtrl.datas = datas
        excelCtrl.title = tableName
        navigationController?.pushViewController(excelCtrl, animated: true)
    }
}

// MARK: - UITableViewDataSource/Delegate for表名

extension SqliteDetailViewController: UITableViewDataSource {
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return tableNames.count
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cellId = "TableNameCell"
        var cell = tableView.dequeueReusableCell(withIdentifier: cellId)
        if cell == nil {
            cell = UITableViewCell(style: .default, reuseIdentifier: cellId)
        }
        cell?.textLabel?.text = tableNames[indexPath.row]
        cell?.accessoryType = .disclosureIndicator
        return cell!
    }
}

extension SqliteDetailViewController: UITableViewDelegate {
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        tableView.deselectRow(at: indexPath, animated: true)
        let tableName = tableNames[indexPath.row]
        loadTableContent(tableName)
    }
}
