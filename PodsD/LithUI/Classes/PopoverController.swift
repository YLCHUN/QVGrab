//
//  PopoverController.swift
//  iOS
//
//  Created by Cityu on 2025/6/2.
//  Copyright © 2025 Cityu. All rights reserved.
//

import UIKit

public class PopoverCItem: NSObject {
    public var afterDismis: Bool = false
    public var image: UIImage?
    public var title: String = ""
    public var handler: ((PopoverCItem) -> Void)?
}

public class PopoverController: UIViewController {
    
    /// 菜单项数组
    public var items: [PopoverCItem] = []
    
    private var tableView: UITableView!
    
    public override func viewDidLoad() {
        super.viewDidLoad()
        
        let rowHeight: CGFloat = 44
        let minWidth: CGFloat = 100
        let maxWidth: CGFloat = 240
        let horizontalPadding: CGFloat = 32 // 左右各16
        let font = UIFont.systemFont(ofSize: 17)
        let textWidth = getMaxWidth(font: font)
        
        let bubbleWidth = min(max(textWidth + horizontalPadding, minWidth), maxWidth)
        let bubbleHeight = rowHeight * CGFloat(items.count)
        
        preferredContentSize = CGSize(width: bubbleWidth, height: bubbleHeight)
        view.backgroundColor = .clear
        
        // tableView下移，顶部预留箭头空间
        tableView = UITableView(frame: .zero, style: .plain)
        tableView.delegate = self
        tableView.dataSource = self
        tableView.backgroundColor = .clear
        tableView.separatorInset = .zero
        tableView.separatorColor = UIColor.color(light: 0.8, dark: 0.2)
        tableView.isScrollEnabled = false
        tableView.rowHeight = rowHeight
        view.addSubview(tableView)
    }
    
    private func getMaxWidth(font: UIFont) -> CGFloat {
        // 1. 计算最大文本宽度
        var maxTextWidth: CGFloat = 0
        for item in items {
            let textSize = item.title.boundingRect(
                with: CGSize(width: CGFloat.greatestFiniteMagnitude, height: 0),
                options: .usesLineFragmentOrigin,
                attributes: [.font: font],
                context: nil
            ).size
            if textSize.width > maxTextWidth {
                maxTextWidth = textSize.width
            }
        }
        return maxTextWidth
    }
    
    public override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
        var frame = view.bounds
        frame.size.height = tableView.rowHeight * CGFloat(items.count)
        frame.origin.y = view.bounds.height - frame.height
        tableView.frame = frame
    }
    
    /// 从指定视图显示弹出菜单
    /// - Parameters:
    ///   - sourceView: 源视图
    ///   - sourceRect: 源视图的矩形区域
    public func present(_ sourceView: UIView, sourceRect: CGRect) {
        modalPresentationStyle = .popover
        let popover = popoverPresentationController
        popover?.sourceView = sourceView
        popover?.sourceRect = sourceRect
        popover?.permittedArrowDirections = .any
        popover?.backgroundColor = .clear
        popover?.delegate = self
        
        var topVC = UIApplication.shared.windows.first?.rootViewController
        while let presented = topVC?.presentedViewController {
            topVC = presented
        }
        topVC?.present(self, animated: true)
    }
    
    /// 从指定按钮项显示弹出菜单
    /// - Parameter barButtonItem: 导航栏按钮项
    public func present(_ barButtonItem: UIBarButtonItem) {
        modalPresentationStyle = .popover
        let popover = popoverPresentationController
        popover?.barButtonItem = barButtonItem
        popover?.permittedArrowDirections = .any
        popover?.backgroundColor = .clear
        popover?.delegate = self
        
        var topVC = UIApplication.shared.windows.first?.rootViewController
        while let presented = topVC?.presentedViewController {
            topVC = presented
        }
        topVC?.present(self, animated: true)
    }
}

// MARK: - UITableViewDataSource
extension PopoverController: UITableViewDataSource {
    
    public func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return items.count
    }
    
    public func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cellIdentifier = "Cell"
        var cell = tableView.dequeueReusableCell(withIdentifier: cellIdentifier)
        if cell == nil {
            cell = UITableViewCell(style: .subtitle, reuseIdentifier: cellIdentifier)
            cell?.textLabel?.textColor = .systemBlue
            cell?.backgroundColor = .clear
            let selectedBg = UIView()
            selectedBg.backgroundColor = UIColor.color(light: 0.7, dark: 0.3)
            cell?.selectedBackgroundView = selectedBg
        }
        
        let item = items[indexPath.row]
        cell?.imageView?.image = item.image
        cell?.textLabel?.text = item.title
        return cell!
    }
}

// MARK: - UITableViewDelegate
extension PopoverController: UITableViewDelegate {
    
    public func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        tableView.deselectRow(at: indexPath, animated: true)
        let item = items[indexPath.row]
        
        if item.afterDismis {
            dismiss(animated: true) {
                item.handler?(item)
            }
        } else {
            item.handler?(item)
            dismiss(animated: true)
        }
    }
}

// MARK: - UIPopoverPresentationControllerDelegate
extension PopoverController: UIPopoverPresentationControllerDelegate {
    
    public func adaptivePresentationStyle(for controller: UIPresentationController) -> UIModalPresentationStyle {
        // 让 iPhone 也用 popover 样式
        return .none
    }
}
