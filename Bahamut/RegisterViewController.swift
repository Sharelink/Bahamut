//
//  RegisterViewController.swift
//  Bahamut
//
//  Created by AlexChow on 15/7/28.
//  Copyright (c) 2015年 GStudio. All rights reserved.
//

import UIKit

class RegisterViewController: UIViewController,UITextFieldDelegate,UIWebViewDelegate
{
    private struct Constants
    {
        static let SegueNextToProfile:String = "Next To Profile"
    }

    private weak var accountService:AccountService!
    private weak var userService:UserService!
    var signInViewController:SignInViewController!
    
    var registerWebPageUrl:String!{
        didSet{
            if registerWebPageView != nil && self.registerWebPageUrl != nil
            {
                let req = NSURLRequest(URL: NSURL(string: self.registerWebPageUrl)!)
                registerWebPageView.loadRequest(req)
            }
        }
    }
    
    @IBOutlet weak var registerWebPageView: UIWebView!{
        didSet{
            registerWebPageView.delegate = self
        }
    }
    
    func webView(webView: UIWebView, didFailLoadWithError error: NSError?) {
        
        view.hideToastActivity()
    }
    
    func webViewDidFinishLoad(webView: UIWebView) {
        
        view.hideToastActivity()
        let uc = NSURLComponents(string: (webView.request?.URLString)!)
        var dict = [String:String]()
        for item in (uc?.queryItems)!
        {
            dict[item.name] = item.value
        }
        if dict["FinishRegist"] != nil && dict["AccountID"] != nil
        {
            webView.stopLoading();
            webView.hidden = true;
            finishRegist(dict["AccountID"]!)
        }
    }
    
    func webViewDidStartLoad(webView: UIWebView) {
        
        view.makeToastActivityWithMessage(message: "Loading")
    }
    
    func regist(){
        registerWebPageUrl = "\(AccountService.registAccountURL)?appkey=\(ShareLinkSDK.appkey)"
    }
    
    func finishRegist(accountId:String)
    {
        self.navigationController?.popViewControllerAnimated(true)
        if let sivc = self.signInViewController
        {
            sivc.loginAccountId = accountId
        }
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        accountService = ServiceContainer.getService(AccountService)
        userService = ServiceContainer.getService(UserService)
        regist()
    }
    
}
