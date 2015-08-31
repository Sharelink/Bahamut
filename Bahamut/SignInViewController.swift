//
//  SignInViewController.swift
//  Bahamut
//
//  Created by AlexChow on 15/7/29.
//  Copyright (c) 2015年 GStudio. All rights reserved.
//

import UIKit
import EVReflection

class SignInViewController: UIViewController,UIWebViewDelegate
{
    struct SegueConstants {
        static let ShowMainView = "ShowMainView"
    }
    
    @IBOutlet weak var loginWebPageView: UIWebView!
    @IBOutlet weak var reloadButton: UIButton!{
        didSet{
            reloadButton.hidden = true
        }
    }
    override func viewDidLoad() {
        super.viewDidLoad()
        authenticate()
    }
    
    @IBAction func testLogin(sender: AnyObject) {
        ShareLinkSDK.sharedInstance.reuse("147258", token: "asdfasdfads", shareLinkApiServer: "http://192.168.0.168:8088", fileApiServer: "http://192.168.0.168:8089")
        ServiceContainer.getService(AccountService).logined("147258", token: "asdfasdfads", shareLinkApiServer: "http://192.168.0.168:8088", fileApiServer: "http://192.168.0.168:8089",callback: signCallback)
    }
    
    @IBAction func reload(sender: AnyObject)
    {
        loginWebPageView.reload()
    }
    
    func webView(webView: UIWebView, didFailLoadWithError error: NSError?) {
        
        reloadButton.hidden = false
    }
    
    func webViewDidStartLoad(webView: UIWebView) {
        
        reloadButton.hidden = true
    }
    
    func webViewDidFinishLoad(webView: UIWebView) {
        
        let jsDocHtml = "document.documentElement.innerHTML"
        let innerHtml = webView.stringByEvaluatingJavaScriptFromString(jsDocHtml)
        let json = EVObject(json:innerHtml!)
        if let accountId = json.valueForKey("AccountID") as? String
        {
            let accessToken = json.valueForKey("AccessToken") as? String
            let APITokenServer = json.valueForKey("APITokenServer") as? String
            ShareLinkSDK.sharedInstance.validateToken(APITokenServer!, accountId: accountId, accessToken: accessToken!){ error in
                if error == nil
                {
                    let sdk = ShareLinkSDK.sharedInstance
                    let service = ServiceContainer.getService(AccountService)
                    service.logined(sdk.userId, token: sdk.token, shareLinkApiServer: sdk.shareLinkApiServer, fileApiServer: sdk.fileApiServer,callback: self.signCallback)
                }else{
                    self.view.makeToast(message: "Validate AccessToken Failed")
                }
                
            }
        }
    }
    
    func authenticate()
    {
        let service = ServiceContainer.getService(AccountService)
        let authenticationURL = service.authenticationURL;
        let appkey = ShareLinkSDK.sharedInstance.appkey;
        let req = NSURLRequest(URL: NSURL(string: "\(authenticationURL)?appkey=\(appkey)")!)
        loginWebPageView.delegate = self
        loginWebPageView.loadRequest(req)
    }
    
    
    func signCallback()
    {
        ServiceContainer.getService(ShareService).test()
        let service = ServiceContainer.getService(UserService)
        let accountService = ServiceContainer.getService(AccountService)
        let fileService = ServiceContainer.getService(FileService)
        fileService.initUserFoldersWithUserId(accountService.userId)
        view.makeToastActivityWithMessage(message: "Refreshing LinkedUsers")
        service.refreshMyLinkedUsers({ (isSuc, msg) -> Void in
            self.view.hideToastActivity()
            if isSuc
            {
                let userService = ServiceContainer.getService(UserService)
                userService.refreshMyAllSharelinkTags(){
                    userService.refreshAllLinkedUserTags()
                }
                self.performSegueWithIdentifier(SegueConstants.ShowMainView, sender: self)
            }else
            {
                self.view.makeToast(message: msg)
            }
        })
    }
}
