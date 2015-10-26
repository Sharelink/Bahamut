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
import JavaScriptCore

@objc protocol SignInViewControllerJSProtocol : JSExport
{
    func makeToast(msg:String)
    func showToastActivity(msg:String?)
    func hideToastActivity()
    func validateToken(result:String)
    func finishRegist(accountId:String)
    func alert(msg:String)
    func switchDevMode()
}

class SignInViewController: UIViewController,UIWebViewDelegate,SignInViewControllerJSProtocol
{
    struct SegueConstants {
        static let ShowMainView = "ShowMainView"
    }
    
    @IBOutlet weak var webPageView: UIWebView!{
        didSet{
            webPageView.scrollView.scrollEnabled = false
            webPageView.delegate = self
        }
    }

    func alert(msg: String) {
        let alert = UIAlertController(title: "Sharelink", message: msg, preferredStyle: .Alert)
        alert.addAction(UIAlertAction(title: "Ok", style: .Cancel){ _ in})
        presentViewController(alert, animated: true, completion: nil)
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        changeNavigationBarColor()
        loginAccountId = BahamutSetting.lastLoginAccountId
    }
    
    override func viewWillAppear(animated: Bool) {
        authenticate()
    }
    
    private var authenticationURL: String {
        let url = NSBundle.mainBundle().pathForResource("index", ofType: "html", inDirectory: "WebAssets/Sharelink")
        return url!
    }
    
    private var webViewUrl:String!{
        didSet{
            if webPageView != nil{
                let req = NSURLRequest(URL: NSURL(string: webViewUrl)!)
                webPageView.loadRequest(req)
            }
        }
    }
    
    var loginAccountId:String!
    
    func webView(webView: UIWebView, didFailLoadWithError error: NSError?) {
    }
    
    func webViewDidStartLoad(webView: UIWebView) {
        
    }
    
    func webViewDidFinishLoad(webView: UIWebView) {
        if let jsContext:JSContext = webView.valueForKeyPath("documentView.webView.mainFrame.javaScriptContext") as? JSContext
        {
            jsContext.setObject(self, forKeyedSubscript: "controller")
            jsContext.exceptionHandler = jsExceptionHandler
        }
    }
    
    func jsExceptionHandler(context:JSContext!,value:JSValue!) {
        self.view.makeToast(message: "Js Error")
    }
    
    func finishRegist(accountId:String)
    {
        self.loginAccountId = accountId
        authenticate()
    }
    
    func validateToken(serverUrl:String, accountId:String, accessToken: String)
    {
        let accountService = ServiceContainer.getService(AccountService)
        view.makeToastActivityWithMessage(message: "Login")
        accountService.validateAccessToken(serverUrl, accountId: accountId, accessToken: accessToken, callback: { (loginSuccess, message) -> Void in
            self.view.hideToastActivity()
            if loginSuccess{
                self.signCallback()
            }else{
                self.view.makeToast(message: message)
                self.authenticate()
            }
            
            }) { (registApiServer) -> Void in
                self.registNewUser(accountId,registApi: registApiServer,accessToken:accessToken)
        }
    }
    
    func registNewUser(accountId:String,registApi:String,accessToken:String)
    {
        let registModel = RegistModel()
        registModel.accessToken = accessToken
        registModel.registUserServer = registApi
        registModel.accountId = accountId
        ServiceContainer.getService(AccountService).showRegistNewUserController(self, registModel:registModel)
    }
    
    private func authenticate()
    {
        var url = authenticationURL
        if let aId = loginAccountId
        {
            url = "\(url)?accountId=\(aId)&loginApi=\(BahamutConfig.loginApi)&registApi=\(BahamutConfig.registAccountApi)"
        }else
        {
            url = "\(url)?loginApi=\(BahamutConfig.loginApi)&registApi=\(BahamutConfig.registAccountApi)"
        }
        webViewUrl = url
    }
    
    func signCallback()
    {
        let service = ServiceContainer.getService(UserService)
        service.addObserver(self, selector: "initUsers:", name: UserService.myUserInfoRefreshed, object: service)
        view.makeToastActivityWithMessage(message: "Refreshing")
    }
    
    func initUsers(_:AnyObject)
    {
        let service = ServiceContainer.getService(UserService)
        service.removeObserver(self)
        self.view.hideToastActivity()
        if service.myUserModel != nil
        {
            self.performSegueWithIdentifier(SegueConstants.ShowMainView, sender: self)
        }else
        {
            self.authenticate()
            self.view.makeToast(message: "Server Failed")
        }
    }
    
    //MARK: develop mode
    
    @IBOutlet weak var dev_panel: UIView!{
        didSet{
            dev_panel.hidden = true
        }
    }
    
    //MARK: implements jsProtocol
    func validateToken(result:String)
    {
        dispatch_async(dispatch_get_main_queue()) { () -> Void in
            var params = result.componentsSeparatedByString("#p")
            self.validateToken(params[0], accountId: params[1], accessToken: params[2])
        }
        
    }
    
    func makeToast(msg:String){
        dispatch_async(dispatch_get_main_queue()) { () -> Void in
            self.view.makeToast(message: msg)
        }
    }
    
    func showToastActivity(msg:String? = nil){
        dispatch_async(dispatch_get_main_queue()) { () -> Void in
            if msg == nil
            {
                self.view.makeToastActivity()
            }else{
                self.view.makeToastActivityWithMessage(message: msg!)
            }
            self.lockScreen()
        }
        
    }
    func hideToastActivity(){
        dispatch_async(dispatch_get_main_queue()) { () -> Void in
            self.unlockScreen()
            self.view.hideToastActivity()
        }

    }
    
    func switchDevMode() {
        dispatch_async(dispatch_get_main_queue()) { () -> Void in
            self.dev_panel.hidden = !self.dev_panel.hidden
            self.view.bringSubviewToFront(self.dev_panel)
        }
    }
    
}
