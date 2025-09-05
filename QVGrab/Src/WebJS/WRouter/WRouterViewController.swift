//
//  WRouterViewController.swift
//  iOS
//
//  Created by Cityu on 2025/6/2.
//  Copyright © 2025 Cityu. All rights reserved.
//

import UIKit

class WRouterViewController: UIViewController {
    
    var routerDBM: WRouterDBM?
    
    private var tableView: UITableView!
    private var selectedCallback: ((String, Bool) -> Void)?
    
    override func viewDidLoad() {
        super.viewDidLoad()
        setupTableView()
        setupNavigationBar()
    }
    
    override var supportedInterfaceOrientations: UIInterfaceOrientationMask {
        return .portrait
    }
    
    private func setupTableView() {
        tableView = UITableView(frame: view.bounds, style: .plain)
        tableView.delegate = self
        tableView.dataSource = self
        tableView.autoresizingMask = [.flexibleWidth, .flexibleHeight]
        view.addSubview(tableView)
        
        // 设置行高以适应两行文本
        tableView.rowHeight = 60
        
        // 添加长按手势
        let longPress = UILongPressGestureRecognizer(target: self, action: #selector(handleLongPress(_:)))
        tableView.addGestureRecognizer(longPress)
    }
    
    private func setupNavigationBar() {
        let clearButton = UIBarButtonItem(title: "清除", style: .plain, target: self, action: #selector(clearAllHistory))
        navigationItem.rightBarButtonItem = clearButton
    }
    
    // MARK: - Actions
    
    @objc private func clearAllHistory() {
        let alert = UIAlertController(title: "清除\(title ?? "数据")", message: "确定要清除所有历\(title ?? "数据")？", preferredStyle: .alert)
        
        let cancelAction = UIAlertAction(title: "取消", style: .cancel)
        
        let confirmAction = UIAlertAction(title: "确定", style: .destructive) { _ in
            self.routerDBM?.cleanAll()
            self.tableView.reloadData()
        }
        
        alert.addAction(cancelAction)
        alert.addAction(confirmAction)
        present(alert, animated: true)
    }
    
    @objc private func handleLongPress(_ gesture: UILongPressGestureRecognizer) {
        guard gesture.state == .began else { return }
        
        let point = gesture.location(in: tableView)
        guard let indexPath = tableView.indexPathForRow(at: point) else { return }
        
        let model = routerDBM!.models[indexPath.row]
        let alert = UIAlertController(title: "操作", message: nil, preferredStyle: .actionSheet)
        
        alert.addAction(UIAlertAction(title: "打开", style: .default) { _ in
            self.selectedCallback?(model.url, false)
        })
        
        alert.addAction(UIAlertAction(title: "后台打开", style: .default) { _ in
            self.selectedCallback?(model.url, true)
        })
        
        alert.addAction(UIAlertAction(title: "编辑", style: .default) { _ in
            self.showEditAlert(for: model, at: indexPath)
        })
        
        alert.addAction(UIAlertAction(title: "复制", style: .default) { _ in
            UIPasteboard.general.string = model.url
            showToast("已复制", in: self.view)
        })
        
        alert.addAction(UIAlertAction(title: "删除", style: .destructive) { _ in
            self.routerDBM?.delUrl(model.url)
            self.tableView.deleteRows(at: [indexPath], with: .fade)
        })
        
        alert.addAction(UIAlertAction(title: "取消", style: .cancel))
        
        present(alert, animated: true)
    }
    
    private func showEditAlert(for model: WRouterModel, at indexPath: IndexPath) {
        let alert = UIAlertController(title: "编辑", message: nil, preferredStyle: .alert)
        
        alert.addTextField { textField in
            textField.placeholder = "标题"
            textField.text = model.title
        }
        
        alert.addTextField { textField in
            textField.placeholder = "地址"
            textField.text = model.url
        }
        
        let cancelAction = UIAlertAction(title: "取消", style: .cancel)
        
        let confirmAction = UIAlertAction(title: "确定", style: .default) { _ in
            guard let newTitle = alert.textFields?[0].text,
                  let newUrl = alert.textFields?[1].text else { return }
            
            if newUrl.isEmpty {
                showToast("地址不能为空", in: self.view)
                return
            }
            
            model.title = newTitle.isEmpty ? "" : newTitle
            model.url = newUrl
            self.routerDBM?.updateModel(model)
            
            self.tableView.reloadRows(at: [indexPath], with: .none)
        }
        
        alert.addAction(cancelAction)
        alert.addAction(confirmAction)
        present(alert, animated: true)
    }
    
    // MARK: - Public Methods
    
    func setSelectedCallback(_ callback: @escaping (String, Bool) -> Void) {
        selectedCallback = callback
    }
}

// MARK: - UITableViewDataSource

extension WRouterViewController: UITableViewDataSource {
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return routerDBM?.models.count ?? 0
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cellIdentifier = "RouterCell"
        var cell = tableView.dequeueReusableCell(withIdentifier: cellIdentifier)
        if cell == nil {
            cell = UITableViewCell(style: .subtitle, reuseIdentifier: cellIdentifier)
        }
        
        let model = routerDBM!.models[indexPath.row]
        
        // 配置cell
        cell?.textLabel?.text = model.title.isEmpty ? model.url : model.title
        cell?.detailTextLabel?.text = model.url
        
        return cell!
    }
}

// MARK: - UITableViewDelegate

extension WRouterViewController: UITableViewDelegate {
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        tableView.deselectRow(at: indexPath, animated: true)
        
        let model = routerDBM!.models[indexPath.row]
        selectedCallback?(model.url, false)
    }
    
    func tableView(_ tableView: UITableView, canEditRowAt indexPath: IndexPath) -> Bool {
        return true
    }
    
    func tableView(_ tableView: UITableView, commit editingStyle: UITableViewCell.EditingStyle, forRowAt indexPath: IndexPath) {
        if editingStyle == .delete {
            let model = routerDBM!.models[indexPath.row]
            routerDBM?.delUrl(model.url)
            tableView.deleteRows(at: [indexPath], with: .fade)
        }
    }
}
