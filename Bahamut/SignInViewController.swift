//
//  SignInViewController.swift
//  Bahamut
//
//  Created by AlexChow on 15/7/29.
//  Copyright (c) 2015年 GStudio. All rights reserved.
//

import UIKit
import EVReflection
import Alamofire

class SignInViewController: UIViewController,UIWebViewDelegate
{
    struct SegueConstants {
        static let ShowMainView = "ShowMainView"
    }
    
    @IBOutlet weak var loginWebPageView: UIWebView!{
        didSet{
            loginWebPageView.delegate = self
        }
    }
    @IBOutlet weak var reloadButton: UIButton!{
        didSet{
            reloadButton.hidden = true
        }
    }
    override func viewDidLoad() {
        super.viewDidLoad()
        loginAccountId = ServiceContainer.getService(AccountService).lastLoginAccountId
    }
    
    override func viewWillAppear(animated: Bool) {
        authenticate()
    }
    
    @IBAction func testLogin(sender: AnyObject) {
        ShareLinkSDK.sharedInstance.reuse("147258", token: "asdfasdfads", shareLinkApiServer: "http://192.168.0.168:8086", fileApiServer: "http://192.168.0.168:8089")
        ServiceContainer.getService(AccountService).setLogined("147258", token: "asdfasdfads", shareLinkApiServer: "http://192.168.0.168:8086", fileApiServer: "http://192.168.0.168:8089")
        signCallback()

    }
    
    override func prepareForSegue(segue: UIStoryboardSegue, sender: AnyObject?) {
        if segue.identifier == "SignUp"
        {
            if let rvc = segue.destinationViewController as? RegisterViewController
            {
                rvc.signInViewController = self
            }
        }
    }
    
    private var webViewUrl:String!{
        didSet{
            if loginWebPageView != nil{
                let req = NSURLRequest(URL: NSURL(string: webViewUrl)!)
                loginWebPageView.loadRequest(req)
            }
        }
    }
    
    var loginAccountId:String!
    
    func webView(webView: UIWebView, didFailLoadWithError error: NSError?) {
        webView.hidden = false
        reloadButton.hidden = false
        self.view.hideToastActivity()
    }
    
    func webViewDidStartLoad(webView: UIWebView) {
        
        reloadButton.hidden = true
        self.view.makeToastActivityWithMessage(message: "Loading")
    }
    
    func webViewDidFinishLoad(webView: UIWebView) {
        self.view.hideToastActivity()
        let uc = NSURLComponents(string: (webView.request?.URLString)!)
        var dict = [String:String]()
        for item in (uc?.queryItems)!
        {
            dict[item.name] = item.value
        }
        let accountId = dict["AccountID"]
        let accessToken = dict["AccessToken"]
        if accountId != nil && accessToken != nil
        {
            webView.stopLoading();
            webView.hidden = true;
            let isNewUser = dict["NewUser"]?.lowercaseString
            if (isNewUser != nil && (isNewUser == "yes" || isNewUser == "true"))
            {
                if let registApi = dict["RegistAPI"]
                {
                    registNewUser(accountId!,registApi: registApi,accessToken:accessToken!)
                }else
                {
                    self.view.makeToast(message: "Server Data Error")
                    authenticate()
                }
                
            }else if dict["APITokenServer"] != nil && dict["AccessToken"] != nil
            {
                validateToken(dict["APITokenServer"]!, accountId: accountId!, accessToken: dict["AccessToken"]!)
            }
        }
    }
    
    func registNewUser(accountId:String,registApi:String,accessToken:String)
    {
        let profileViewController = UIStoryboard(name: "Main", bundle: NSBundle.mainBundle()).instantiateViewControllerWithIdentifier("profileViewController")
        self.navigationController?.pushViewController(profileViewController, animated: true)
    }
    
    func validateToken(apiTokenServer:String, accountId:String, accessToken: String)
    {
        let accountService = ServiceContainer.getService(AccountService)
        accountService.validateAccessToken(apiTokenServer, accountId: accountId, accessToken: accessToken) { (loginSuccess, message) -> Void in
            if loginSuccess{
                self.signCallback()
            }else{
                self.view.makeToast(message: message)
            }
        }
    }
    
    private func authenticate()
    {
        loginWebPageView.hidden = false
        var url = "\(AccountService.authenticationURL)?appkey=\(ShareLinkSDK.appkey)"
        if let aId = loginAccountId
        {
            url = "\(url)&accountId=\(aId)"
        }
        webViewUrl = url
    }
    
    func signCallback()
    {
        let service = ServiceContainer.getService(UserService)
        let accountService = ServiceContainer.getService(AccountService)
        let userTagService = ServiceContainer.getService(UserTagService)
        let fileService = ServiceContainer.getService(FileService)
        fileService.initUserFoldersWithUserId(accountService.userId)
        view.makeToastActivityWithMessage(message: "Refreshing")
        service.refreshMyLinkedUsers({ (isSuc, msg) -> Void in
            self.view.hideToastActivity()
            if isSuc
            {
                let userService = ServiceContainer.getService(UserService)
                userService.refreshMyLinkedUsers({ (isSuc, msg) -> Void in
                    userTagService.refreshAllLinkedUserTags()
                })
                self.performSegueWithIdentifier(SegueConstants.ShowMainView, sender: self)
            }else
            {
                self.view.makeToast(message: msg)
            }
        })
    }
}
