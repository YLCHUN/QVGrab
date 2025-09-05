//
//  FMDB+SQL.swift
//  QVGrab
//
//  Created by YLCHUN on 2025/9/3.
//

import Foundation
import FMDB

extension FMDatabase {
    @discardableResult
    func executeUpdate(_ sql: String) -> Bool {
        return executeUpdate(sql, withArgumentsIn: [])
    }
    func executeQuery(_ sql: String)->FMResultSet? {
        return try? executeQuery(sql, values: nil)
    }
}
