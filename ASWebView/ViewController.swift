//
//  ViewController.swift
//  ASWebView
//
//  Created by 李晟 on 2018/1/18.
//  Copyright © 2018年 breeze. All rights reserved.
//

import UIKit

class ViewController: UIViewController {

    override func viewDidLoad() {
        super.viewDidLoad()
        // Do any additional setup after loading the view, typically from a nib.
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
    @IBAction func baidu(_ sender: Any) {
        
        let WebView = ASWebViewController()
        WebView.loadType = .LoadWebURLString
        WebView.loadWebURLSring(URLString: "http://www.baidu.com")
        WebView.addBottomSafeSpace = true
//        WebView.backButton.setImage(UIImage(named: ""), for: .normal)
//        WebView.backButton.setImage(UIImage(named: ""), for: .highlighted)
//        WebView.backButton.setTitle("修改", for: .normal)
        self.navigationController?.pushViewController(WebView, animated: true)
        
    }
    
    @IBAction func nativeJs(_ sender: Any) {

        let WebView = ASWebViewController()
        WebView.loadType = .LoadWebHTMLString
        WebView.loadWebHTMLSring(URLString: "index.html")
        self.navigationController?.pushViewController(WebView, animated: true)
        
    }
}

