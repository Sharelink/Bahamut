//
//  SignInViewController.swift
//  Bahamut
//
//  Created by AlexChow on 15/7/29.
//  Copyright (c) 2015年 GStudio. All rights reserved.
//

import UIKit
import JavaScriptCore
import MBProgressHUD

@objc protocol SignInViewControllerJSProtocol : JSExport
{
    func makeToast(msg:String)
    func showToastActivity(msg:String?)
    func hideActivity()
    func validateToken(result:String)
    func finishRegist(accountId:String)
    func alert(msg:String)
    func showPrivacy()
    func isShowDeveloperPanel(idpsw:String) -> Bool
}

class SignInViewController: UIViewController,UIWebViewDelegate,SignInViewControllerJSProtocol
{
    
    private var webPageView: UIWebView!{
        didSet{
            webPageView.hidden = true
            webPageView.scrollView.showsHorizontalScrollIndicator = false
            webPageView.scrollView.showsVerticalScrollIndicator = false
            webPageView.scrollView.scrollEnabled = false
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
        ServiceContainer.instance.addObserver(self, selector: "allServicesReady:", name: ServiceContainer.AllServicesReady, object: nil)
        loginAccountId = UserSetting.lastLoginAccountId
        refreshWebView()
    }
    
    func allServicesReady(_:NSNotification)
    {
        self.view.backgroundColor = UIColor.blackColor()
        if let hud = self.refreshingHud
        {
            hud.hideAsync(false)
        }
        self.webPageView.hidden = true
        self.view.backgroundColor = UIColor.blackColor()
        ServiceContainer.instance.removeObserver(self)
    }
    
    private func refreshWebView()
    {
        if loginAccountId != nil{
            authenticate()
        }else
        {
            registAccount()
        }
    }
    
    override func viewWillAppear(animated: Bool) {
        super.viewWillAppear(animated)
        NSNotificationCenter.defaultCenter().addObserver(self, selector:"keyboardWillShow:", name:UIKeyboardWillShowNotification, object:nil)
        NSNotificationCenter.defaultCenter().addObserver(self, selector:"keyboardWillHide:", name:UIKeyboardWillHideNotification, object:nil)
        if developerShown
        {
            developerShown = false
            refreshWebView()
        }
    }
    
    func keyboardWillHide(_:NSNotification)
    {
        webPageView.scrollView.scrollEnabled = false
    }
    
    func keyboardWillShow(_:NSNotification)
    {
        webPageView.scrollView.scrollEnabled = true
    }
    
    override func viewWillDisappear(animated: Bool) {
        super.viewWillAppear(animated)
        NSNotificationCenter.defaultCenter().removeObserver(self)
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
        self.playToast("JS_ERROR".localizedString())
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
    
    private var refreshingHud:MBProgressHUD!
    func validateToken(serverUrl:String, accountId:String, accessToken: String)
    {
        let accountService = ServiceContainer.getService(AccountService)
        let hud = self.showActivityHudWithMessage("",message: "LOGINING".localizedString() )
        accountService.validateAccessToken(serverUrl, accountId: accountId, accessToken: accessToken, callback: { (loginSuccess, message) -> Void in
            hud.hideAsync(true)
            if loginSuccess{
                self.refreshingHud = self.showActivityHudWithMessage("",message:"REFRESHING".localizedString())
            }else{
                self.playToast( message)
            }
            
            }) { (registApiServer) -> Void in
                self.registNewUser(accountId,registApi: registApiServer,accessToken:accessToken)
        }
    }
    
    
    private var refreshHud:MBProgressHUD!
    
    func registNewUser(accountId:String,registApi:String,accessToken:String)
    {
        let registModel = RegistModel()
        registModel.accessToken = accessToken
        registModel.registUserServer = registApi
        registModel.accountId = accountId
        registModel.userName = registedAccountName ?? "Sharelinker"
        registModel.region = SharelinkSetting.contry.lowercaseString
        
        let newUser = Sharelinker()
        newUser.motto = "Sharelink"
        newUser.nickName = registedAccountName ?? "Sharelinker"
        
        let hud = self.showActivityHudWithMessage("",message:"REGISTING".localizedString())
        ServiceContainer.getService(AccountService).registNewUser(registModel, newUser: newUser){ isSuc,msg,validateResult in
            hud.hideAsync(true)
            if isSuc
            {
                self.refreshHud = self.showActivityHudWithMessage("",message:"REFRESHING".localizedString())
            }else
            {
                self.playToast(msg)
            }
        }
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
            self.playToast( msg.localizedString())
        }
    }
    
    private var toastHud:MBProgressHUD!
    func showToastActivity(msg:String? = nil){
        dispatch_async(dispatch_get_main_queue()) { () -> Void in
            if let hud = self.toastHud
            {
                hud.hideAsync(true)
            }
            if msg == nil
            {
                self.toastHud = self.showActivityHud()
            }else{
                self.toastHud = self.showActivityHudWithMessage("",message: msg!.localizedString())
            }
        }
        
    }
    
    func hideActivity(){
        dispatch_async(dispatch_get_main_queue()) { () -> Void in
            if let hud = self.toastHud
            {
                hud.hideAsync(true)
            }
        }
    }
    
    func showPrivacy() {
        SimpleBrowser.openUrl(self.navigationController!, url: SharelinkConfig.bahamutConfig.sharelinkPrivacyPage)
    }
    
    //MARK: Developer Panel
    private var developerShown = false
    func isShowDeveloperPanel(idpsw: String) -> Bool{
        if idpsw == "godbestyybest"
        {
            dispatch_async(dispatch_get_main_queue()) { () -> Void in
                UserSetting.isAppstoreReviewing = false
                DeveloperMainPanelController.showDeveloperMainPanel(self)
                self.developerShown = true
            }
            return true
        }else
        {
            return false
        }
    }
}
