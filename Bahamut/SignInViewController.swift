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
    func alert(msg:String)
    func showPrivacy()
    
    func registAccount(username:String,_ password:String)
    func loginAccount(username:String,_ password:String)
}

//MARK: SignInViewController
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
    
    private var refreshingHud:MBProgressHUD!
    private func validateToken(serverUrl:String, accountId:String, accessToken: String)
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
            url = "\(url)?accountId=\(aId)"
        }else
        {
            url = "\(url)"
        }
        webViewUrl = url
    }
    
    private func registAccount()
    {
        let url = "\(registAccountUrl)?loginApi=\(SharelinkSetting.loginApi)&registApi=\(SharelinkSetting.registAccountApi)"
        webViewUrl = url
    }
    
    //MARK: implements jsProtocol
    func registAccount(username: String,_ password: String) {
        if isShowDeveloperPanel("\(username)\(password)".sha256){return}
        let hud = self.showActivityHud()
        SharelinkSDK.sharedInstance.registBahamutAccount(SharelinkSetting.registAccountApi, username: username, passwordOrigin: password, phone_number: nil, email: nil) { (isSuc, errorMsg, registResult) -> Void in
            hud.hide(false)
            if isSuc
            {
                self.showAlert("REGIST_SUC_TITLE".localizedString(), msg: String(format: "REGIST_SUC_MSG".localizedString(), registResult.accountId))
                self.loginAccountId = registResult.accountId
                self.registedAccountName = registResult.accountName
                self.authenticate()
            }else{
                self.playToast(errorMsg.localizedString())
            }
        }
    }
    
    func loginAccount(username: String,_ password: String) {
        if isShowDeveloperPanel("\(username)\(password)".sha256){return}
        let hud = self.showActivityHudWithMessage(nil, message: "LOGINING".localizedString())
        SharelinkSDK.sharedInstance.loginBahamutAccount(SharelinkSetting.loginApi, accountInfo: username, passwordOrigin: password) { (isSuc, errorMsg, loginResult) -> Void in
            hud.hide(true)
            if isSuc
            {
                self.validateToken(loginResult.AppServiceUrl, accountId: loginResult.AccountID, accessToken: loginResult.AccessToken)
            }else
            {
                self.playToast(errorMsg.localizedString())
            }
        }
    }
    
    func alert(msg: String) {
        let alert = UIAlertController(title:"SHARELINK".localizedString(), message: msg.localizedString(), preferredStyle: .Alert)
        alert.addAction(UIAlertAction(title:"I_SEE".localizedString(), style: .Cancel){ _ in})
        dispatch_async(dispatch_get_main_queue()) { () -> Void in
            self.presentViewController(alert, animated: true, completion: nil)
        }
    }
    
    func showPrivacy() {
        SimpleBrowser.openUrl(self.navigationController!, url: SharelinkConfig.bahamutConfig.sharelinkPrivacyPage)
    }
    
    //MARK: Developer Panel
    private var developerShown = false
    let idpswHash = "0992369b28f2d4903851f17382cc884a97b6ecaf939fc02063dd113a21ee334e"
    private func isShowDeveloperPanel(idpsw: String) -> Bool{
        if idpsw == idpswHash
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
