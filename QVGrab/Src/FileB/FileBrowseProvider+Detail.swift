//
//  FileBrowseProvider+Detail.swift
//  iOS
//
//  Created by Cityu on 2025/6/5.
//  Copyright © 2025 Cityu. All rights reserved.
//

import Foundation
import UIKit
import FileBrowse

extension PlayerViewController: FileBrowseDetailProtocol {
    var viewController: UIViewController {
        return self
    }
    
    var modal: Bool {
        return true
    }
    
}

extension SqliteDetailViewController: FileBrowseDetailProtocol {
    var viewController: UIViewController {
        return self
    }
    
    var modal: Bool {
        return false
    }
}

extension FileBrowseProvider {
    static func setup() {        
        FileBrowseProvider.detailProvider = { file in
            var detail: FileBrowseDetailProtocol?
            if file.fileType == FileExtensionType.video {
                let urlStr = file.filePath as String
                let url = URL(fileURLWithPath: urlStr)
                let playerVC = PlayerViewController()
                playerVC.modalPresentationStyle = .fullScreen
                playerVC.videoURL = url
                detail = playerVC
            } else if file.fileType == FileExtensionType.database {
                let urlStr = file.filePath as String
                let detailVC = SqliteDetailViewController()
                detailVC.modalPresentationStyle = .fullScreen
                detailVC.dbFilePath = urlStr
                detail = detailVC
            }
            return detail
        }
        
        let progressDBM = PProgressDBM.dbm(withTable: "video_progress")
        
        FileBrowseProvider.progressProvider = { file in
            if file.fileType != FileExtensionType.video { return -1 }
            let url = URL(fileURLWithPath: file.filePath)
            let videoId = PlayerViewController.videoId(url)
            return progressDBM?.progress(forKey: videoId) ?? -1
        }
    }
}
