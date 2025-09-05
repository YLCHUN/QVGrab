//
//  FileBViewController.swift
//  iOS
//
//  Created by Cityu on 2025/7/15.
//  Copyright © 2025 Cityu. All rights reserved.
//

import UIKit
import FileBrowse
import LithUI

class FileBViewController: DirBrowseViewController {
    
    override func viewDidLoad() {
        super.viewDidLoad()
        title = "FileB"
        view.backgroundColor = UIColor.color(lightHex: "#FFFFFF", darkHex: "#1B1B1B")
    }
}
