//
//  HistoryManager.swift
//  QVGrab
//
//  Created by Cityu on 2024/7/1.
//

import Foundation

class HistoryManager {
    private let dbm: WRouterDBM
    
    static let sharedManager = HistoryManager()
    
    private init() {
        dbm = WRouterDBM.historyDBM()
    }
    
    func addHistoryWithURL(_ url: String, title: String) {
        dbm.addUrl(url, title: title)
    }
    
    func removeHistoryWithURL(_ url: String) {
        dbm.delUrl(url)
    }
    
    func hasHistoryWithURL(_ url: String) -> Bool {
        return dbm.hasUrl(url)
    }
}
