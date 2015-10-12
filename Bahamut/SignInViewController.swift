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
        loginAccountId = BahamutConfig.lastLoginAccountId
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
    
    func registNewUser(accountId:String,registApi:String,accessToken:String)
    {
        let registModel = RegistModel()
        registModel.accessToken = accessToken
        registModel.registUserServer = registApi
        registModel.accountId = accountId
        ServiceContainer.getService(UserService).showRegistNewUserController(self.navigationController!, registModel:registModel)
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
    
    //MARK: implements jsProtocol
    func validateToken(result:String)
    {
        var params = result.componentsSeparatedByString("#p")
        self.validateToken(params[0], accountId: params[1], accessToken: params[2])
    }
    
    func makeToast(msg:String){
        view.makeToast(message: msg)
    }
    
    func showToastActivity(msg:String? = nil){
        if msg == nil
        {
            view.makeToastActivity()
        }else{
            view.makeToastActivityWithMessage(message: msg!)
        }
    }
    func hideToastActivity(){
        view.hideToastActivity()
    }
    
    private func authenticate()
    {
        var url = authenticationURL
        if let aId = loginAccountId
        {
            url = "\(url)?accountId=\(aId)"
        }
        webViewUrl = url
    }
    
    func signCallback()
    {
        let service = ServiceContainer.getService(UserService)
        let accountService = ServiceContainer.getService(AccountService)
        ServiceContainer.instance.userLogin(accountService.userId)
        service.addObserver(self, selector: "initUsers:", name: UserService.userListUpdated, object: service)
        view.makeToastActivityWithMessage(message: "Refreshing")
        service.refreshMyLinkedUsers() 
    }
    
    func initUsers(_:AnyObject)
    {
        let service = ServiceContainer.getService(UserService)
        service.removeObserver(self)
        self.view.hideToastActivity()
        if service.myLinkedUsers != nil
        {
            self.performSegueWithIdentifier(SegueConstants.ShowMainView, sender: self)
        }else
        {
            self.authenticate()
            self.view.makeToast(message: "Server Failed")
        }
    }
}
