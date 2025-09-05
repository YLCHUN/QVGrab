//
//  UrlInputView.swift
//  iOS
//
//  Created by Cityu on 2025/7/24.
//  Copyright © 2025 Cityu. All rights reserved.
//

import UIKit
import LithUI


class UrlInputView: UIView {
    
    var url: String = "" {
        didSet {
            updateTextField()
        }
    }
    
    var title: String = "" {
        didSet {
            updateTextField()
        }
    }
    
    private(set) var editing: Bool = false
    
    var onInput: ((String) -> Void)?
    var onReload: (() -> Void)?
    var onLeft: (() -> Void)?
    var onRespond: ((Bool) -> Void)?
    
    var searchEngine: String = ""
    private(set) var searchEngines: [String] = []
    
    private let inputButton : InputButton
    private let textField : UITextField
    private let leftView : InputLeftView
    
    private let kSEName = "kSEName"
    private let kSEUrl = "kSEUrl"
    private let kSearchEngine = "kSearchEngine"
    
    override init(frame: CGRect) {
        textField = UITextField()
        inputButton = InputButton(coreInput: textField)
        leftView = InputLeftView()
        super.init(frame: frame)
        setupUI()
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    

    
    private func setupUI() {
        setupTextField()
        setupInputAccessoryView()
        setupInputLeftView()
        setupInputButton()
    }
    
    private func setupTextField() {
        textField.frame = bounds
        textField.autoresizingMask = [.flexibleWidth, .flexibleHeight]
        textField.borderStyle = .none
        textField.placeholder = "请输入网页地址"
        textField.delegate = self
        textField.clearButtonMode = .whileEditing
        textField.returnKeyType = .go
        textField.keyboardType = .URL
        textField.backgroundColor = UIColor.defaultBackgroundColor()
        textField.textColor = UIColor.color(lightHex: "#000000", darkHex: "#FFFFFF")
        textField.leftViewMode = .always
    }
    
    private func setupInputButton() {
        inputButton.layer.cornerRadius = 5
        inputButton.layer.masksToBounds = true
        inputButton.layer.borderWidth = 1
        inputButton.chouyeBlock = { view in
            view.layer.borderColor = UIColor.color(lightHex: "#CCCCCC", darkHex: "#333333")?.cgColor
        }
        inputButton.frame = bounds
        inputButton.autoresizingMask = [.flexibleWidth, .flexibleHeight]
        inputButton.setTarget(self, action: #selector(handleInputButtonDoubleTap))
        addSubview(inputButton)
    }
    
    private func setupInputAccessoryView() {
        let cancelBtn = UIButton(type: .system)
        cancelBtn.setTitle("取消", for: .normal)
        cancelBtn.titleLabel?.font = UIFont.boldSystemFont(ofSize: 15)
        cancelBtn.addTarget(self, action: #selector(cancelAction), for: .touchUpInside)
        let cancelItem = UIBarButtonItem(customView: cancelBtn)
        
        let flexibleSpace = UIBarButtonItem(barButtonSystemItem: .flexibleSpace, target: nil, action: nil)
        
        let toolbar = UIToolbar(frame: CGRect(x: 0, y: 0, width: 0, height: 30))
        toolbar.barStyle = .default
        toolbar.items = [flexibleSpace, cancelItem]
        textField.inputAccessoryView = toolbar
    }
    
    private func setupInputLeftView() {
        let searchEngine = UserDefaults.standard.string(forKey: kSearchEngine)
        let searchEngineObjs = searchEngineObjs()
        
        var selectedEngine = searchEngine
        if let searchEngine = searchEngine {
            if searchEngineObjs[searchEngine] == nil {
                selectedEngine = nil
            }
        }
        
        let searchEngines = Array(searchEngineObjs.keys)
        self.searchEngines = searchEngines
        
        var items: [InputLeftItem] = []
        for se in searchEngines {
            guard let seObj = searchEngineObjs[se] else { continue }
            let imgName = "favicon_\(se)"
            let image = UIImage(named: imgName)
            let item = InputLeftItem()
            item.image = image
            item.idf = se
            item.name = seObj[kSEName] as? String
            item.url = seObj[kSEUrl] as? String ?? ""
            items.append(item)
        }
        
        leftView.items = items
        leftView.itemIdf = selectedEngine ?? searchEngines.first ?? ""
        
        leftView.callback = { item in
            UserDefaults.standard.set(item.idf, forKey: self.kSearchEngine)
            UserDefaults.standard.synchronize()
        }
    }
    
    func updateTextField() {
        let text = textField.isEditing ? url : (title.isEmpty ? url : title)
        textField.text = text
    }
    
    @objc private func handleInputButtonDoubleTap() {
        onReload?()
    }
    
    @objc private func leftViewAction() {
        onLeft?()
    }
    
    @objc private func cancelAction() {
        textField.endEditing(false)
    }
    
    private func searchEngineObjs() -> [String: [String: Any]] {
        return [
            "baidu": [kSEName: "百度", kSEUrl: "https://www.baidu.com/s?wd=%@"],
            "sogou": [kSEName: "搜狗", kSEUrl: "https://www.sogou.com/web?query=%@"],
            "360": [kSEName: "360", kSEUrl: "https://www.so.com/s?q=%@"],
            "bing": [kSEName: "必应", kSEUrl: "https://www.bing.com/search?q=%@"],
            "google": [kSEName: "谷歌", kSEUrl: "https://www.google.com/search?q=%@"]
        ]
    }
    
    private func isValidURL(_ urlString: String) -> Bool {
        // 参数容错处理
        guard !urlString.isEmpty else { return false }
        
        // 更完善的URL正则表达式模式，支持IP地址和多种URL格式
        let urlPattern = "^(https?|ftp|file)://([\\w-]+\\.)+[\\w-]+(:\\d+)?(/[\\w-./?%&=]*)?$|^(https?|ftp|file)://(\\d{1,3}\\.){3}\\d{1,3}(:\\d+)?(/[\\w-./?%&=]*)?$"
        
        do {
            let regex = try NSRegularExpression(pattern: urlPattern, options: .caseInsensitive)
            let range = NSRange(location: 0, length: urlString.utf16.count)
            let match = regex.firstMatch(in: urlString, options: [], range: range)
            return match != nil
        } catch {
            print("正则表达式创建失败: \(error.localizedDescription)")
            return false
        }
    }
    
    private func checkUrl(_ url: String) -> String {
        if !isValidURL(url) {
            let encodedUrl = url.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed) ?? url
            let engineUrl = leftView.item?.url ?? ""
            return String(format: engineUrl, encodedUrl)
        }
        return url
    }
}

// MARK: - UITextFieldDelegate

extension UrlInputView: UITextFieldDelegate {
    func textFieldShouldReturn(_ textField: UITextField) -> Bool {
        url = textField.text ?? ""
        let checkedUrl = checkUrl(url)
        onInput?(checkedUrl)
        textField.resignFirstResponder()
        return true
    }
    
    func textFieldDidEndEditing(_ textField: UITextField) {
        editing = false
        updateTextField()
        textField.leftView = nil
        onRespond?(false)
    }
    
    func textFieldDidBeginEditing(_ textField: UITextField) {
        editing = true
        updateTextField()
        textField.leftView = leftView
        onRespond?(true)
    }
}
