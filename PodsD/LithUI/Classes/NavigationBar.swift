//
//  NavigationBar.swift
//  LithUI
//
//  Created by Cityu on 2025/7/24.
//

import UIKit

public class NavigationBar: UINavigationBar {
    
    public override var barPosition: UIBarPosition {
        // 背景覆盖到状态栏
        return .topAttached
    }
}
