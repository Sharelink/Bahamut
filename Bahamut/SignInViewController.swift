//
//  SignInViewController.swift
//  Bahamut
//
//  Created by AlexChow on 15/7/29.
//  Copyright (c) 2015年 GStudio. All rights reserved.
//

import UIKit
import JavaScriptCore

@objc protocol SignInViewControllerJSProtocol : JSExport
{
    func makeToast(msg:String)
    func showToastActivity(msg:String?)
    func hideActivity()
    func validateToken(result:String)
    func finishRegist(accountId:String)
    func alert(msg:String)
    func switchDevMode()
    func showPrivacy()
}

class SignInViewController: UIViewController,UIWebViewDelegate,SignInViewControllerJSProtocol
{
    
    private var webPageView: UIWebView!{
        didSet{
            webPageView.hidden = true
            webPageView.scrollView.showsHorizontalScrollIndicator = false
            webPageView.scrollView.showsVerticalScrollIndicator = false
            webPageView.scrollView.scrollEnabled = true
            webPageView.scalesPageToFit = true
            webPageView.delegate = self
            self.view.addSubview(webPageView)
        }
    }
    
    private var launchScr:UIView!
    private func setBackgroundView()
    {
        launchScr = MainNavigationController.getLaunchScreen(self.view.bounds)
        self.view.addSubview(launchScr)
        self.view.bringSubviewToFront(launchScr)
    }
    
    private func launchScrEaseOut()
    {
        UIView.animateWithDuration(1, animations: { () -> Void in
            self.launchScr.alpha = 0
            }) { (flag) -> Void in
                self.launchScr.removeFromSuperview()
        }
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        changeNavigationBarColor()
        self.view.backgroundColor = UIColor.whiteColor()
        webPageView = UIWebView(frame: self.view.bounds)
        setBackgroundView()
        loginAccountId = UserSetting.lastLoginAccountId
        if loginAccountId != nil{
            authenticate()
        }else
        {
            registAccount()
        }
    }
    
    private var registAccountUrl:String{
        let url = Sharelink.mainBundle().pathForResource("register_\(SharelinkSetting.lang)", ofType: "html", inDirectory: "WebAssets/Sharelink")
        return url!
    }
    
    private var authenticationURL: String {
        let url = Sharelink.mainBundle().pathForResource("login_\(SharelinkSetting.lang)", ofType: "html", inDirectory: "WebAssets/Sharelink")
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
        if self.webPageView.hidden
        {
            self.webPageView.hidden = false
            launchScrEaseOut()
        }
        if let jsContext:JSContext = webView.valueForKeyPath("documentView.webView.mainFrame.javaScriptContext") as? JSContext
        {
            jsContext.setObject(self, forKeyedSubscript: "controller")
            jsContext.exceptionHandler = jsExceptionHandler
        }
    }
    
    func jsExceptionHandler(context:JSContext!,value:JSValue!) {
        self.showToast("JS_ERROR".localizedString())
    }
    
    var registedAccountName:String!
    func finishRegist(result:String)
    {
        let arrs = result.split("#p")
        let accountId = arrs[0]
        let accountName = arrs[1]
        alert(String(format: "REGIST_SUC_MSG".localizedString(), accountId))
        self.loginAccountId = accountId
        self.registedAccountName = accountName
        authenticate()
    }
    
    func validateToken(serverUrl:String, accountId:String, accessToken: String)
    {
        let accountService = ServiceContainer.getService(AccountService)
        self.makeToastActivityWithMessage("",message: "LOGINING".localizedString() )
        accountService.validateAccessToken(serverUrl, accountId: accountId, accessToken: accessToken, callback: { (loginSuccess, message) -> Void in
            self.hideToastActivity()
            if loginSuccess{
                self.makeToastActivityWithMessage("",message:"REFRESHING".localizedString())
            }else{
                self.showToast( message)
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
        registModel.userName = registedAccountName ?? "Sharelinker"
        registModel.region = SharelinkSetting.contry.lowercaseString
        ServiceContainer.getService(AccountService).showRegistNewUserController(self.navigationController!, registModel:registModel)
    }
    
    private func authenticate()
    {
        var url = authenticationURL
        if let aId = loginAccountId
        {
            url = "\(url)?accountId=\(aId)&loginApi=\(SharelinkSetting.loginApi)&registApi=\(SharelinkSetting.registAccountApi)"
        }else
        {
            url = "\(url)?loginApi=\(SharelinkSetting.loginApi)&registApi=\(SharelinkSetting.registAccountApi)"
        }
        webViewUrl = url
    }
    
    private func registAccount()
    {
        let url = "\(registAccountUrl)?loginApi=\(SharelinkSetting.loginApi)&registApi=\(SharelinkSetting.registAccountApi)"
        webViewUrl = url
    }
    
    //MARK: implements jsProtocol
    func alert(msg: String) {
        let alert = UIAlertController(title:"SHARELINK".localizedString(), message: msg.localizedString(), preferredStyle: .Alert)
        alert.addAction(UIAlertAction(title:"I_SEE".localizedString(), style: .Cancel){ _ in})
        dispatch_async(dispatch_get_main_queue()) { () -> Void in
            self.presentViewController(alert, animated: true, completion: nil)
        }
    }
    
    func validateToken(result:String)
    {
        dispatch_async(dispatch_get_main_queue()) { () -> Void in
            var params = result.componentsSeparatedByString("#p")
            self.validateToken(params[0], accountId: params[1], accessToken: params[2])
        }
        
    }
    
    func makeToast(msg:String){
        dispatch_async(dispatch_get_main_queue()) { () -> Void in
            self.showToast( msg.localizedString())
        }
    }
    
    func showToastActivity(msg:String? = nil){
        dispatch_async(dispatch_get_main_queue()) { () -> Void in
            if msg == nil
            {
                self.makeToastActivity()
            }else{
                self.makeToastActivityWithMessage("",message: msg!.localizedString())
            }
        }
        
    }
    
    func hideActivity(){
        dispatch_async(dispatch_get_main_queue()) { () -> Void in
            self.hideToastActivity()
        }
    }
    
    func showPrivacy() {
        SimpleBrowser.openUrl(self.navigationController!, url: SharelinkConfig.bahamutConfig.sharelinkPrivacyPage)
    }
    
    //MARK: develop mode
    @IBAction func hideDevPanel(sender: AnyObject) {
        dev_panel.hidden = true
    }
    
    @IBAction func clearAllData(sender: AnyObject)
    {
        PersistentManager.sharedInstance.clearCache()
        PersistentManager.sharedInstance.clearRootDir()
    }
    
    @IBAction func use168Server(sender: AnyObject)
    {
        SharelinkSetting.loginApi = "http://192.168.1.168:8086/Account/AjaxLogin"
        SharelinkSetting.registAccountApi = "http://192.168.1.168:8086/Account/AjaxRegist"
        authenticate()
    }
    @IBAction func use67Server(sender: AnyObject)
    {
        SharelinkSetting.loginApi = "http://192.168.1.67:8086/Account/AjaxLogin"
        SharelinkSetting.registAccountApi = "http://192.168.1.67:8086/Account/AjaxRegist"
        authenticate()
    }
    
    @IBAction func useRemoteServer(sender: AnyObject)
    {
        SharelinkSetting.loginApi = "http://auth.sharelink.online:8086/Account/AjaxLogin"
        SharelinkSetting.registAccountApi = "http://auth.sharelink.online:8086/Account/AjaxRegist"
        authenticate()
    }
    
    @IBOutlet weak var dev_panel: UIView!{
        didSet{
            dev_panel.hidden = true
        }
    }
    
    func switchDevMode() {
        dispatch_async(dispatch_get_main_queue()) { () -> Void in
            UserSetting.isAppstoreReviewing = false
            self.dev_panel.hidden = !self.dev_panel.hidden
            self.view.bringSubviewToFront(self.dev_panel)
        }
    }
    
}
