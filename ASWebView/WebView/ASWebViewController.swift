//
//  ASWebViewController.swift
//  qianDianDian
//
//  Created by 李晟 on 2018/1/15.
//  Copyright © 2018年 qdd. All rights reserved.
//
 

import UIKit
import WebKit

enum WebLoadType {
    case LoadWebURLString
    case LoadWebHTMLString
}

class ASWebViewController: UIViewController{

    var  loadType:WebLoadType!
    var URLString:String!
    var PostData:String!
    var addBottomSafeSpace:Bool! =  false // iphone X 底物 safe 区域添加空白
    
    
    lazy var webView:WKWebView = {
        () -> WKWebView in
        
        let Configuration = WKWebViewConfiguration()
        Configuration.allowsInlineMediaPlayback = true// 允许在线播放
        Configuration.processPool = WKProcessPool()// web内容处理池
        Configuration.suppressesIncrementalRendering = true// 是否支持记忆读取
        if #available(iOS 9.0, *) {
            Configuration.allowsAirPlayForMediaPlayback = true
            Configuration.allowsPictureInPictureMediaPlayback = true
        }
        
        var navigationHeight:CGFloat = UIScreen.main.bounds.height == 812.0 ? 88.0 : 64.0
        var fixTopSpace:CGFloat = navigationHeight
        
        if self.navigationController?.navigationBar.isTranslucent == false {
            navigationHeight = 0.0
        }
        
        let webView = WKWebView(frame:CGRect(x: 0, y: navigationHeight, width: UIScreen.main.bounds.size.width, height: self.view.bounds.size.height - fixTopSpace), configuration: Configuration)

        if UIScreen.main.bounds.height == 812.0 && addBottomSafeSpace { // 是否需要 iphoneX 底部安全区域空白
            let safeBottom:CGFloat = UIScreen.main.bounds.height == 812.0 ? 34.0 : 0.0
            webView.scrollView.contentInset = UIEdgeInsetsMake(0, 0, safeBottom, 0)
            
            let bottomBlackView = UIImageView(frame: CGRect(x: 0, y: self.view.bounds.size.height - navigationHeight - safeBottom, width: UIScreen.main.bounds.size.width, height: safeBottom))
            bottomBlackView.backgroundColor = UIColor.white
            webView.addSubview(bottomBlackView)
        }
        
        // 顶部 空白试图 （为了好看）
        let topBlackView = UIImageView(frame: CGRect(x: 0, y: 0, width: UIScreen.main.bounds.size.width, height: fixTopSpace))
        topBlackView.backgroundColor = UIColor.white
        self.view.insertSubview(topBlackView, at: 0)
        
        //js 注入 
        webView.configuration.userContentController.add(WeakScriptMessageDelegate(delegate: self), name: "NativeMethod")
        
        webView.scrollView.showsVerticalScrollIndicator = false
        webView.scrollView.showsHorizontalScrollIndicator = false
        webView.scrollView.backgroundColor = UIColor.white
        webView.allowsBackForwardNavigationGestures = true
     
        if #available(iOS 9.0, *) {
            webView.allowsLinkPreview = true
            
        }
        webView.sizeToFit()
        
        //kvo 添加进度监控
        webView.addObserver(self, forKeyPath: "estimatedProgress", options: .new, context:nil )
        webView.addObserver(self, forKeyPath: "title", options: .new, context:nil ) //h5 类似 react Vue 这种 一次性加载 状态控制页面的 是不会重复触发 didFinish 故 曲线救'国'
        
        return webView
    }() //
    
    lazy var progressLine:UIProgressView = {
        () -> UIProgressView in
        
        var safeTopHeight = CGFloat(UIScreen.main.bounds.height == 812.0 ? 88.0 : 64.0)
        if self.navigationController?.navigationBar.isTranslucent == false {
            safeTopHeight = 0
        }

        let progressLine = UIProgressView(frame: CGRect(x: 0, y: safeTopHeight, width: UIScreen.main.bounds.size.width, height: 3))
        progressLine.trackTintColor = UIColor.clear
        progressLine.progressTintColor = self.navigationController?.navigationBar.barTintColor == UIColor.white ?  UIColor(red: 222.0/255.0, green: 222.0/255.0, blue: 222.0/255.0, alpha: 1) : self.navigationController?.navigationBar.barTintColor
        return progressLine
    }() //
    
    
    
    lazy var backButton:UIButton = {
        () -> UIButton in
        
        let backButton = UIButton(type: UIButtonType.system)
        backButton.setImage(UIImage(named: "ASWebViewController.bundle/nav_icon_back"), for: .normal)
        backButton.setImage(UIImage(named: "ASWebViewController.bundle/nav_icon_back"), for: .highlighted)
        backButton.addTarget(self, action: #selector(ASWebViewController.backBarItemClicked), for: .touchUpInside)
        backButton.setTitle(" 返回", for: .normal)
        backButton.contentHorizontalAlignment = UIControlContentHorizontalAlignment.left;
        backButton.titleLabel?.font = UIFont.systemFont(ofSize: 17.0)
        backButton.frame = CGRect(x: 0, y: 0, width: 50, height: 44)
        backButton.titleLabel?.sizeToFit()
        if #available(iOS 11.0, *) {
            backButton.contentEdgeInsets = UIEdgeInsetsMake(0, -5, 0, 0)
        }
        backButton.clipsToBounds = false
        return backButton
    }() //
    
    lazy private var backBarButtonItem:UIBarButtonItem = { // 返回按钮
        () -> UIBarButtonItem in
        let backBarButtonItem = UIBarButtonItem(customView: self.backButton)
        return backBarButtonItem
    }() //
    
    lazy private var closeBarButtonItem:UIBarButtonItem = { // 关闭按钮
        () -> UIBarButtonItem in
        
        let closeButton = UIButton(type: UIButtonType.system)
        closeButton.addTarget(self, action: #selector(ASWebViewController.closeBarItemClicked), for: .touchUpInside)
        closeButton.setTitle("关闭 ", for: .normal)
        closeButton.contentHorizontalAlignment = UIControlContentHorizontalAlignment.left;
        closeButton.titleLabel?.font = UIFont.systemFont(ofSize: 17.0)
        closeButton.frame = CGRect(x: 0, y: 0, width: 44, height: 44)
        if #available(iOS 11.0, *) {
            closeButton.contentEdgeInsets = UIEdgeInsetsMake(0, -5, 0, 0)
        }
        closeButton.titleLabel?.sizeToFit()
        closeButton.clipsToBounds = false
        let closeBarButtonItem = UIBarButtonItem(customView: closeButton)
        
        return closeBarButtonItem
    }() //
    
    override func viewDidLoad() {
        super.viewDidLoad()
        self.WebViewloadURLType()
        self.view.addSubview(webView)
        self.view.addSubview(progressLine)
        self.updateNavigationItems()
        self.navigationController?.interactivePopGestureRecognizer?.isEnabled = true;
    
    }
    
    var NavTranslucent:Bool!
    
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)

        webView.navigationDelegate = self
        webView.uiDelegate = self
        self.navigationController?.interactivePopGestureRecognizer?.delegate = self
    }
    
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)

    }
    
    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)

        webView.navigationDelegate = nil
        webView.uiDelegate = nil
        self.navigationController?.interactivePopGestureRecognizer?.delegate = nil
        
    }
    
    deinit {
        webView.configuration.userContentController.removeScriptMessageHandler(forName: "NativeMethod")
        print("销毁了" + String(describing: type(of: self)))
        webView.removeObserver(self, forKeyPath: "estimatedProgress")
        webView.removeObserver(self, forKeyPath: "title")
    }
    
}


extension ASWebViewController:UIGestureRecognizerDelegate{
    
    func gestureRecognizerShouldBegin(_ gestureRecognizer: UIGestureRecognizer) -> Bool {
        return true
    }
}
// MARK: -   Naive - js
extension ASWebViewController{
    
    func closeWebView(){
        self.closeBarItemClicked()
    }
}


// MARK: -   WKScriptMessageHandler
extension ASWebViewController:WKScriptMessageHandler {
    
    func userContentController(_ userContentController: WKUserContentController, didReceive message: WKScriptMessage) {
        // 判断是否是调用原生的
        if "NativeMethod" == message.name {
            
            let conentStr = String(describing: type(of: message.body))
            if !(conentStr.contains("String")){// 传入的参数 非字符串类型
                return
            }
            
            // 判断message的内容，然后做相应的操作
            if "close" == message.body as! String {
                self.closeWebView()
            }
        }
    }
}

// MARK: -  webView WKNavigationDelegate
extension ASWebViewController:WKNavigationDelegate{
    
    func webView(_ webView: WKWebView, didStartProvisionalNavigation navigation: WKNavigation!) {//开始加载
        self.progressLine.isHidden = false;
    }
    
    func webView(_ webView: WKWebView, didFinish navigation: WKNavigation!) {//内容加载完成
        
        self.title = self.webView.title;
        self.updateNavigationItems()
    }
    
    func webView(_ webView: WKWebView, didReceiveServerRedirectForProvisionalNavigation navigation: WKNavigation!) { //服务器开始请求的时候调用
        
    }
    
    func webView(_ webView: WKWebView, didCommit navigation: WKNavigation!) {//内容返回时调用
        
    }
}

// MARK: - NavigationItems 的设置
extension ASWebViewController {
    
    func updateNavigationItems(){
        if webView.canGoBack {
            let negativeSpacer = UIBarButtonItem(barButtonSystemItem: .fixedSpace, target: nil, action: nil)
            negativeSpacer.width = -5
            self.navigationItem.setLeftBarButtonItems([negativeSpacer, self.backBarButtonItem, self.closeBarButtonItem], animated: false)
        }else{
            let negativeSpacer = UIBarButtonItem(barButtonSystemItem: .fixedSpace, target: nil, action: nil)
            negativeSpacer.width = -5
            self.navigationItem.setLeftBarButtonItems([negativeSpacer, self.backBarButtonItem], animated: false)
            
        }
    }
    
    @objc func backBarItemClicked(){
        if webView.canGoBack {
            self.webView.goBack()
        }else{
            self.navigationController?.popViewController(animated: true)
        }
    }
    
    @objc func closeBarItemClicked(){
        self.navigationController?.popViewController(animated: true)
    }
    
}

// MARK: - WKUIDelegate
extension ASWebViewController : WKUIDelegate {
    
    func webView(_ webView: WKWebView, runJavaScriptAlertPanelWithMessage message: String, initiatedByFrame frame: WKFrameInfo, completionHandler: @escaping () -> Void) {
        let alert = UIAlertController(title: "提示", message: message, preferredStyle: .alert)
        let confirmAction = UIAlertAction(title: "确定", style: .default) { (handler) in
            completionHandler()
        }
        alert.addAction(confirmAction)
        self.present(alert, animated: true, completion: nil)
        
    }
    
    func webView(_ webView: WKWebView, runJavaScriptConfirmPanelWithMessage message: String, initiatedByFrame frame: WKFrameInfo, completionHandler: @escaping (Bool) -> Void) {
        let alert = UIAlertController(title: "提示", message: message, preferredStyle: .alert)
        let confirmAction = UIAlertAction(title: "确定", style: .default) { (handler) in
            completionHandler(true)
        }
        let cancelAction = UIAlertAction(title: "取消", style: .default) { (handler) in
            completionHandler(false)
        }
        alert.addAction(confirmAction)
        alert.addAction(cancelAction)
        self.present(alert, animated: true, completion: nil)
    }
    
    func webView(_ webView: WKWebView, runJavaScriptTextInputPanelWithPrompt prompt: String, defaultText: String?, initiatedByFrame frame: WKFrameInfo, completionHandler: @escaping (String?) -> Void) {
        
        
        let alert = UIAlertController(title: "提示", message: "", preferredStyle: .alert)
        
        alert.addTextField { (textField) in
            textField.textColor = UIColor.black
        }
        
        let confirmAction = UIAlertAction(title: "确定", style: .default) { (handler) in
            completionHandler(alert.textFields?.last?.text)
        }
        
        alert.addAction(confirmAction)
        self.present(alert, animated: true, completion: nil)
    }
    
}
// MARK: - KVO
extension ASWebViewController { //  KVO
    override func observeValue(forKeyPath keyPath: String?, of object: Any?, change: [NSKeyValueChangeKey : Any]?, context: UnsafeMutableRawPointer?) {
        if (keyPath == "estimatedProgress") {
            progressLine.alpha = 1.0
            let animated = webView.estimatedProgress > Double(progressLine.progress) ? true : false
            progressLine.setProgress(Float(webView.estimatedProgress), animated: animated)
            if webView.estimatedProgress >= 1.0{
                UIView.animate(withDuration: 0.3, delay: 0.3, options: .curveEaseOut, animations: {
                    self.progressLine.alpha = 0.0
                }, completion: { (false) in
                    self.progressLine.setProgress(0.0, animated: false)
                })
            }
        }
        
        if (keyPath == "title") {
           self.updateNavigationItems()
            if (webView.title == "") {
                return;
            }
            self.title = self.webView.title;
        }
    }
}

// MARK: - 加载 类别
extension ASWebViewController{ // 加载 类别
    
    func loadWebURLSring(URLString:String){
        self.URLString = URLString.replacingOccurrences(of: " ", with: "")
        self.loadType = .LoadWebURLString;
    }
    
    func loadWebHTMLSring(URLString:String){
        self.URLString = URLString.replacingOccurrences(of: " ", with: "")
        self.loadType = .LoadWebHTMLString;
    }

    func loadHostPathURL(url:String){
        
        if !url.contains(".html") {
            let path = Bundle.main.path(forResource: url, ofType: "html")
            let html = try! String(contentsOfFile: path!, encoding: String.Encoding.utf8)
            self.webView.loadHTMLString(html, baseURL: Bundle.main.bundleURL)
        }else{
            let path = Bundle.main.path(forResource: url.replacingOccurrences(of: ".html", with: ""), ofType: "html")
            let html = try! String(contentsOfFile: path!, encoding: String.Encoding.utf8)
            self.webView.loadHTMLString(html, baseURL: Bundle.main.bundleURL)
        }
    }

    func WebViewloadURLType(){
        
        switch self.loadType {
            
        case .LoadWebURLString :
            let request_ZSJ = URLRequest(url: URL(string: self.URLString)!)
            self.webView.load(request_ZSJ)
            break
        case .LoadWebHTMLString :
            self.loadHostPathURL(url: self.URLString)
            break
        default: break
        }
    }
}

// MARK: - 解决WKScriptMessageHandler 循环引用
class WeakScriptMessageDelegate: NSObject, WKScriptMessageHandler{
    
    weak var scriptDelegate:WKScriptMessageHandler?
    
    func userContentController(_ userContentController: WKUserContentController, didReceive message: WKScriptMessage) {
        scriptDelegate?.userContentController(userContentController, didReceive: message)
    }
    
    init(delegate:AnyObject) {
        self.scriptDelegate =  delegate as? WKScriptMessageHandler
    }
}
