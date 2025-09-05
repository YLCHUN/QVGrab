//
//  ViewController.swift
//  QVGrab
//
//  Created by Cityu on 2022/6/23.
//

import UIKit
import LithUI
import FileBrowse
import M3U8

class ViewController: UITabBarController {
    
    private var kd: KeyboardDismisser?
    private var singleTapDelay: Bool = false
    
    override func viewDidLoad() {
        super.viewDidLoad()
        view.backgroundColor = UIColor.defaultBackgroundColor()
        tabBar.isTranslucent = false
        delegate = self
        
        setup()
        
        kd = KeyboardDismisser(view: view)
        
        setupTabBarControllers()
    }
    
    func setup() {
        FileBrowseProvider.setup()
        DownloaderProvider.register(AFDownloader.self)
//        DownloaderProvider.register(ADownloader.self)
    }
    
    private func setupTabBarControllers() {
        // Create WebViewController in navigation controller
        let webJSController = WebViewController()
        let webJSNavController = UINavigationController(rootViewController: webJSController)
        webJSNavController.tabBarItem = UITabBarItem(title: "WebJS", image: UIImage(named: "WebB"), tag: 0)
        
        let dmgrController = DownloadingViewController()
        let dmgrNavController = UINavigationController(rootViewController: dmgrController)
        dmgrNavController.tabBarItem = UITabBarItem(title: "Dmgr", image: UIImage(named: "DMgr"), tag: 1)
        
        let documentsPath = NSSearchPathForDirectoriesInDomains(.documentDirectory, .userDomainMask, true).first!
        let resourcePath = Bundle.main.resourcePath!
        let cachesPath = NSSearchPathForDirectoriesInDomains(.cachesDirectory, .userDomainMask, true).first!
        let fileBController = FileBViewController(paths: [documentsPath, resourcePath, cachesPath])
        let fileBNavController = UINavigationController(rootViewController: fileBController)
        fileBNavController.tabBarItem = UITabBarItem(title: "FileB", image: UIImage(named: "FileB"), tag: 2)
        
        // Create WebServiceViewController
        let webSController = WebServiceViewController()
        let webSNavController = UINavigationController(rootViewController: webSController)
        webSNavController.tabBarItem = UITabBarItem(title: "WebS", image: UIImage(named: "WebS"), tag: 3)
        
        let logLController = LogLViewController()
        logLController.tabBarItem = UITabBarItem(title: "LogL", image: UIImage(named: "LogL"), tag: 4)
        
        // Set view controllers
        viewControllers = [webJSNavController, dmgrNavController, fileBNavController, webSNavController, logLController]
    }
    
    override var supportedInterfaceOrientations: UIInterfaceOrientationMask {
        return .portrait
    }
}

// MARK: - UITabBarControllerDelegate

extension ViewController: UITabBarControllerDelegate {
    
    func tabBarController(_ tabBarController: UITabBarController, shouldSelect viewController: UIViewController) -> Bool {
        let selectedIndex = viewControllers?.firstIndex(of: viewController) ?? 0
        let kSingleTapDelay = "singleTapDelay"
        
        // 如果点击的是当前选中的tab
        if selectedIndex == self.selectedIndex {
            // 如果已经有定时器在运行，说明这是双击
            if singleTapDelay {
                NSObject.cancelPreviousPerformRequests(withTarget: self, selector: #selector(handleSingleTapDelayed), object: nil)
                singleTapDelay = false
                // 执行双击操作
                handleDoubleTap()
            } else {
                // 第一次点击，启动定时器
                singleTapDelay = true
                perform(#selector(handleSingleTapDelayed), with: nil, afterDelay: 0.2)
            }
            return false // 阻止切换
        } else {
            // 点击的是其他tab，取消定时器
            NSObject.cancelPreviousPerformRequests(withTarget: self, selector: #selector(handleSingleTapDelayed), object: nil)
            singleTapDelay = false
            
            return true // 允许切换
        }
    }
    
    func tabBarController(_ tabBarController: UITabBarController, didSelect viewController: UIViewController) {
        // Tab切换完成后的处理
        let selectedIndex = viewControllers?.firstIndex(of: viewController) ?? 0
        print("切换到Tab: \(selectedIndex)")
    }
    
    @objc private func handleSingleTapDelayed() {
        singleTapDelay = false
        if let selectedIndex = viewControllers?.firstIndex(of: selectedViewController!), 
           selectedIndex == self.selectedIndex {
            handleSingleTap()
        }
    }
}

// MARK: - 点击处理

extension ViewController {
    
    private var selectedViewControllerTop: UIViewController {
        var vc = selectedViewController!
        if let navController = vc as? UINavigationController {
            vc = navController.topViewController!
        }
        return vc
    }
    
    private func handleSingleTap() {
        if let vc = selectedViewControllerTop as? TabViewControllerAction {
            vc.tabBarSingleAction()
        }
        print("handleSingleTap")
    }
    
    private func handleDoubleTap() {
        if let vc = selectedViewControllerTop as? TabViewControllerAction {
            vc.tabBarDoubleAction()
        }
        print("handleDoubleTap")
    }
}
