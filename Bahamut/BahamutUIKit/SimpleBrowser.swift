//
//  Browser.swift
//  Bahamut
//
//  Created by AlexChow on 15/10/30.
//  Copyright © 2015年 GStudio. All rights reserved.
//

import Foundation
import UIKit

class SimpleBrowser: UIViewController,UIWebViewDelegate
{
    var webView: UIWebView!{
        didSet{
            webView.delegate = self
            if url != nil{
                loadUrl()
            }
        }
    }
    
    var useCustomTitle = true
    
    var url:String!{
        didSet{
            if url != nil && webView != nil
            {
                loadUrl()
            }
        }
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        webView = UIWebView(frame: self.view.bounds)
        self.view.addSubview(webView)
        self.navigationItem.leftBarButtonItem = UIBarButtonItem(title: "CLOSE".bahamutCommonLocalizedString, style: .plain, target: self, action: #selector(SimpleBrowser.back(_:)))
        let leftSwipe = UISwipeGestureRecognizer(target: self, action: #selector(SimpleBrowser.swipeLeft(_:)))
        leftSwipe.direction = .left
        
        let rightSwipe = UISwipeGestureRecognizer(target: self, action: #selector(SimpleBrowser.swipeRight(_:)))
        rightSwipe.direction = .right
        
        self.webView.addGestureRecognizer(leftSwipe)
        self.webView.addGestureRecognizer(rightSwipe)
    }
    
    func swipeLeft(_:UISwipeGestureRecognizer)
    {
        self.webView.goForward()
    }
    
    func swipeRight(_:UISwipeGestureRecognizer)
    {
        if webView.canGoBack {
            self.webView.goBack()
        }else{
            self.navigationController?.dismiss(animated: true, completion: nil)
        }
    }
    
    func back(_ sender: AnyObject)
    {
        self.navigationController?.dismiss(animated: true, completion: nil)
    }
    
    fileprivate func loadUrl()
    {
        webView.loadRequest(URLRequest(url: URL(string: url)!))
    }
    
    func webViewDidFinishLoad(_ webView: UIWebView) {
        if useCustomTitle {
            if let title = webView.stringByEvaluatingJavaScript(from: "document.title"){
                self.title = title
            }
        }
    }
    
    //"SimpleBrowser"
    @discardableResult
    static func openUrl(_ currentViewController:UIViewController,url:String,title:String?,callback:((_:SimpleBrowser)->Void)? = nil) -> SimpleBrowser
    {
        let controller = SimpleBrowser()
        let navController = UINavigationController(rootViewController: controller)
        
        controller.useCustomTitle = String.isNullOrWhiteSpace(title)
        
        DispatchQueue.main.async { () -> Void in
            if let cnvc = currentViewController as? UINavigationController{
                navController.navigationBar.barStyle = cnvc.navigationBar.barStyle
            }
            controller.title = title
            currentViewController.present(navController, animated: true, completion: {
                controller.url = url;
                if let cb = callback{
                    cb(controller)
                }
            })
        }
        return controller
    }
}
