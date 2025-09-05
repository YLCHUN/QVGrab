//
//  BookmarkManager.swift
//  QVGrab
//
//  Created by Cityu on 2024/7/1.
//

import Foundation

class BookmarkManager {
    private let dbm: WRouterDBM
    
    static let sharedManager = BookmarkManager()
    
    private init() {
        dbm = WRouterDBM.bookmarkDBM()
    }
    
    func addBookmarkWithURL(_ url: String, title: String) {
        dbm.addUrl(url, title: title)
    }
    
    func removeBookmarkWithURL(_ url: String) {
        dbm.delUrl(url)
    }
    
    func hasBookmarkWithURL(_ url: String) -> Bool {
        return dbm.hasUrl(url)
    }
}
