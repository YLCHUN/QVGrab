//
//  MBProgressHUD+Toast.swift
//  iOS
//
//  Created by Cityu on 2025/6/6.
//  Copyright © 2025 Cityu. All rights reserved.
//

import MBProgressHUD
import UIKit

public func showToast(_ text: String, in view: UIView?) {
    guard let view = view else { return }
    
    let hud = MBProgressHUD.showAdded(to: view, animated: true)
    hud.mode = .text
    hud.label.text = text
    hud.bezelView.style = .solidColor
    hud.bezelView.color = UIColor(white: 0.0, alpha: 0.7)
    hud.label.textColor = UIColor.white
    hud.margin = 10.0
    hud.removeFromSuperViewOnHide = true
    hud.show(animated: true)
    hud.hide(animated: true, afterDelay: 1.5)
}
