//
//  TabViewControllerAction.swift
//  iOS
//
//  Created by Cityu on 2025/7/24.
//  Copyright © 2025 Cityu. All rights reserved.
//

import Foundation

protocol TabViewControllerAction: AnyObject {
    func tabBarSingleAction()
    func tabBarDoubleAction()
}
