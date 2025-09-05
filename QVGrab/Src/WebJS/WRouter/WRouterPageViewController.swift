//
//  WRouterPageViewController.swift
//  iOS
//
//  Created by Cityu on 2025/6/2.
//  Copyright © 2025 Cityu. All rights reserved.
//

import UIKit


class WRouterPageViewController: UIPageViewController {
    
    private var historyVC: WRouterViewController!
    private var bookmarkVC: WRouterViewController!
    private var segmentedControl: UISegmentedControl!
    private var selectedCallback: ((String, Bool) -> Void)?
    
    override init(transitionStyle style: UIPageViewController.TransitionStyle, navigationOrientation: UIPageViewController.NavigationOrientation, options: [UIPageViewController.OptionsKey : Any]? = nil) {
        super.init(transitionStyle: .scroll, navigationOrientation: .horizontal, options: nil)
        dataSource = nil  // 禁用滑动
        delegate = self
    }
    
    required init?(coder: NSCoder) {
        super.init(coder: coder)
        dataSource = nil  // 禁用滑动
        delegate = self
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        // 设置分段控制器
        segmentedControl = UISegmentedControl(items: ["历史", "书签"])
        segmentedControl.selectedSegmentIndex = 0
        segmentedControl.addTarget(self, action: #selector(segmentedControlValueChanged(_:)), for: .valueChanged)
        navigationItem.titleView = segmentedControl
        
        setViewControllers([historyVC], direction: .forward, animated: false)
        
        // 设置初始导航栏右侧按钮
        updateNavigationBarItems(for: historyVC)
    }
    
    private func updateNavigationBarItems(for viewController: UIViewController) {
        if let routerVC = viewController as? WRouterViewController {
            navigationItem.rightBarButtonItems = routerVC.navigationItem.rightBarButtonItems
        }
    }
    
    @objc private func segmentedControlValueChanged(_ sender: UISegmentedControl) {
        guard let targetVC = sender.selectedSegmentIndex == 0 ? historyVC : bookmarkVC else { return }
        let direction: UIPageViewController.NavigationDirection = sender.selectedSegmentIndex == 0 ? .reverse : .forward
        setViewControllers([targetVC], direction: direction, animated: true) { finished in
            if finished {
                self.updateNavigationBarItems(for: targetVC)
            }
        }
    }
    
    private var historyViewController: WRouterViewController {
        if historyVC == nil {
            historyVC = WRouterViewController()
            historyVC.title = "历史"
            historyVC.routerDBM = WRouterDBM.historyDBM()
            historyVC.setSelectedCallback(selectedCallback ?? { _, _ in })
        }
        return historyVC
    }
    
    private var bookmarkViewController: WRouterViewController {
        if bookmarkVC == nil {
            bookmarkVC = WRouterViewController()
            bookmarkVC.title = "书签"
            bookmarkVC.routerDBM = WRouterDBM.bookmarkDBM()
            bookmarkVC.setSelectedCallback(selectedCallback ?? { _, _ in })
        }
        return bookmarkVC
    }
    
    func setSelectedCallback(_ callback: @escaping (String, Bool) -> Void) {
        selectedCallback = callback
        historyViewController.setSelectedCallback(callback)
        bookmarkViewController.setSelectedCallback(callback)
    }
}

// MARK: - UIPageViewControllerDataSource

extension WRouterPageViewController: UIPageViewControllerDataSource {
    func pageViewController(_ pageViewController: UIPageViewController, viewControllerBefore viewController: UIViewController) -> UIViewController? {
        if viewController == bookmarkViewController {
            return historyViewController
        }
        return nil
    }
    
    func pageViewController(_ pageViewController: UIPageViewController, viewControllerAfter viewController: UIViewController) -> UIViewController? {
        if viewController == historyViewController {
            return bookmarkViewController
        }
        return nil
    }
}

// MARK: - UIPageViewControllerDelegate

extension WRouterPageViewController: UIPageViewControllerDelegate {
    func pageViewController(_ pageViewController: UIPageViewController, didFinishAnimating finished: Bool, previousViewControllers: [UIViewController], transitionCompleted completed: Bool) {
        if completed {
            let currentVC = pageViewController.viewControllers?.first
            segmentedControl.selectedSegmentIndex = (currentVC == historyViewController) ? 0 : 1
            updateNavigationBarItems(for: currentVC!)
        }
    }
}
