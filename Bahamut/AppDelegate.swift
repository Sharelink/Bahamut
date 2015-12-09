//
//  AppDelegate.swift
//  Bahamut
//
//  Created by AlexChow on 15/7/27.
//  Copyright (c) 2015年 GStudio. All rights reserved.
//

import UIKit
import CoreData
import EVReflection

@UIApplicationMain
class AppDelegate: UIResponder, UIApplicationDelegate {

    var window: UIWindow?


    func application(application: UIApplication, didFinishLaunchingWithOptions launchOptions: [NSObject: AnyObject]?) -> Bool {
        configContryAndLang()
        initService()
        loadUI()
        configureUMessage(launchOptions)
        configureUmeng()
        configureShareSDK()
        initQuPai()
        return true
    }
    
    private func initService()
    {
        ServiceContainer.instance.initContainer()
    }
    
    private func initQuPai()
    {
        TaeSDK.sharedInstance().asyncInit({ () -> Void in
            NSLog("TaeSDK Inited")
        }) { (error) -> Void in
            fatalError(error.description)
        }
    }
    
    private func loadUI()
    {
        ChatViewController.instanceFromStoryBoard()
        UserProfileViewController.instanceFromStoryBoard()
        UIEditTextPropertyViewController.instanceFromStoryBoard()
    }
    
    private func configureUMessage(launchOptions: [NSObject: AnyObject]?)
    {
        UMessage.startWithAppkey(BahamutConfig.umengAppkey, launchOptions: launchOptions)
        UMessage.setAutoAlert(false)
        //register remoteNotification types
        let action1 = UIMutableUserNotificationAction()
        action1.identifier = "action1_identifier"
        action1.title="Accept";
        action1.activationMode = UIUserNotificationActivationMode.Foreground //当点击的时候启动程序
        
        let action2 = UIMutableUserNotificationAction()  //第二按钮
        action2.identifier = "action2_identifier"
        action2.title="Reject"
        action2.activationMode = UIUserNotificationActivationMode.Background //当点击的时候不启动程序，在后台处理
        action2.authenticationRequired = true //需要解锁才能处理，如果action.activationMode = UIUserNotificationActivationModeForeground;则这个属性被忽略；
        action2.destructive = true;
        
        let categorys = UIMutableUserNotificationCategory()
        categorys.identifier = "category1" //这组动作的唯一标示
        categorys.setActions([action1,action2], forContext: .Default)
        
        let userSettings = UIUserNotificationSettings(forTypes: [.Sound,.Badge,.Alert], categories: [categorys])
        UMessage.registerRemoteNotificationAndUserNotificationSettings(userSettings)
    }
    
    private func configureUmeng()
    {
        MobClick.startWithAppkey(BahamutConfig.umengAppkey, reportPolicy: BATCH, channelId: nil)
        if let infoDic = NSBundle.mainBundle().infoDictionary
        {
            let version = infoDic["CFBundleShortVersionString"] as! String
            MobClick.setAppVersion(version)
        }
        MobClick.setEncryptEnabled(true)
        MobClick.setLogEnabled(true)
    }

    private func configureShareSDK()
    {
        ShareSDK.registerApp(BahamutConfig.shareSDKAppkey)
        if(SharelinkSetting.contry == "CN")
        {
            connectChinaApps()
            connectGlobalApps()
        }else{
            connectGlobalApps()
            connectChinaApps()
        }
        
        //SMS Mail
        ShareSDK.connectSMS()
        ShareSDK.connectMail()
        
        ShareSDK.ssoEnabled(true)
        
    }
    
    private func configContryAndLang()
    {
        let countryCode = NSLocale.currentLocale().objectForKey(NSLocaleCountryCode)
        SharelinkSetting.contry = countryCode!.description
        if(countryCode!.description == "CN")
        {
            SharelinkSetting.lang = "ch"
        }else{
            SharelinkSetting.lang = "en"
        }
    }
    
    private func connectGlobalApps()
    {
        //Facebook
        ShareSDK.connectFacebookWithAppKey(BahamutConfig.facebookAppkey, appSecret: BahamutConfig.facebookAppScrect)
        
        //WhatsApp
        ShareSDK.connectWhatsApp()
    }
    
    private func connectChinaApps()
    {
        //微信登陆的时候需要初始化
        ShareSDK.connectWeChatSessionWithAppId(BahamutConfig.wechatAppkey, appSecret: BahamutConfig.wechatAppScrect, wechatCls: WXApi.classForCoder())
        ShareSDK.connectWeChatTimelineWithAppId(BahamutConfig.wechatAppkey, appSecret: BahamutConfig.wechatAppScrect, wechatCls: WXApi.classForCoder())
        
        //添加QQ应用  注册网址   http://mobile.qq.com/api/
        ShareSDK.connectQQWithAppId(BahamutConfig.qqAppkey, qqApiCls: QQApiInterface.classForCoder())
        
        //Weibo
//        ShareSDK.connectSinaWeiboWithAppKey(BahamutConfig.weiboAppkey, appSecret: BahamutConfig.weiboAppScrect, redirectUri: "https://api.weibo.com/oauth2/default.html",weiboSDKCls: WeiboSDK.classForCoder())
        
    }
    
    func application(application: UIApplication, didRegisterForRemoteNotificationsWithDeviceToken deviceToken: NSData) {
        UMessage.registerDeviceToken(deviceToken)
        SharelinkSetting.deviceToken = deviceToken.description
            .stringByReplacingOccurrencesOfString("<", withString: "")
            .stringByReplacingOccurrencesOfString(">", withString: "")
            .stringByReplacingOccurrencesOfString(" ", withString: "")
        ChicagoClient.sharedInstance.registDeviceToken(SharelinkSetting.deviceToken)
        NSLog("deviceToken:%@",SharelinkSetting.deviceToken)
    }
    
    func application(application: UIApplication, didReceiveRemoteNotification userInfo: [NSObject : AnyObject]) {
        
        UMessage.didReceiveRemoteNotification(userInfo)
    }
    
    func application(application: UIApplication, didFailToRegisterForRemoteNotificationsWithError error: NSError) {
        NSLog("%@", error.description)
    }
    
    func application(app: UIApplication, openURL url: NSURL, options: [String : AnyObject]) -> Bool {
        if url.scheme == SharelinkCmd.sharelinkUrlSchema
        {
            return handleSharelinkUrl(url)
        }else
        {
            return ShareSDK.handleOpenURL(url, wxDelegate: self)
        }
    }
    
    func application(application: UIApplication, openURL url: NSURL, sourceApplication: String?, annotation: AnyObject) -> Bool {
        if url.scheme == SharelinkCmd.sharelinkUrlSchema
        {
            return handleSharelinkUrl(url)
        }else
        {
            return ShareSDK.handleOpenURL(url, sourceApplication: sourceApplication, annotation: annotation, wxDelegate: self)
        }
    }
    
    func application(application: UIApplication, handleOpenURL url: NSURL) -> Bool {
        return handleSharelinkUrl(url)
    }
    
    
    func handleSharelinkUrl(url:NSURL) -> Bool
    {
        if url.scheme == SharelinkCmd.sharelinkUrlSchema
        {
            let cmd = SharelinkCmd.getCmdFromUrl(url.absoluteString)
            SharelinkCmdManager.sharedInstance.pushCmd(cmd)
        }
        return true
    }
    func applicationWillResignActive(application: UIApplication) {
        // Sent when the application is about to move from active to inactive state. This can occur for certain types of temporary interruptions (such as an incoming phone call or SMS message) or when the user quits the application and it begins the transition to the background state.
        // Use this method to pause ongoing tasks, disable timers, and throttle down OpenGL ES frame rates. Games should use this method to pause the game.
    }

    func applicationDidEnterBackground(application: UIApplication) {
        // Use this method to release shared resources, save user data, invalidate timers, and store enough application state information to restore your application to its current state in case it is terminated later.
        // If your application supports background execution, this method is called instead of applicationWillTerminate: when the user quits.
        PersistentManager.sharedInstance.saveAll()
        ChicagoClient.sharedInstance.inBackground()
    }

    func applicationWillEnterForeground(application: UIApplication) {
        // Called as part of the transition from the background to the inactive state; here you can undo many of the changes made on entering the background.
        
    }

    func applicationDidBecomeActive(application: UIApplication) {
        // Restart any tasks that were paused (or not yet started) while the application was inactive. If the application was previously in the background, optionally refresh the user interface.
        if ServiceContainer.isAllServiceReady
        {
            ServiceContainer.getService(UserService).getNewLinkMessageFromServer()
            ServiceContainer.getService(ShareService).getNewShareMessageFromServer()
            ServiceContainer.getService(MessageService).getMessageFromServer()
            ChicagoClient.sharedInstance.reConnect()
            if UserService.lastRefreshLinkedUserTime == nil || UserService.lastRefreshLinkedUserTime.timeIntervalSinceNow < -1000 * 3600 * 3
            {
                UserService.lastRefreshLinkedUserTime = NSDate()
                ServiceContainer.getService(UserService).refreshMyLinkedUsers()
            }
            SharelinkCmdManager.sharedInstance.handleCmdQueue()
        }
    }

    func applicationWillTerminate(application: UIApplication) {
        // Called when the application is about to terminate. Save data if appropriate. See also applicationDidEnterBackground:.
        // Saves changes in the application's managed object context before the application terminates.
        PersistentManager.sharedInstance.saveAll()
    }

    // MARK: - Core Data stack

    lazy var applicationDocumentsDirectory: NSURL = {
        // The directory the application uses to store the Core Data store file. This code uses a directory named "com.gstudio.Bahamut" in the application's documents Application Support directory.
        let urls = NSFileManager.defaultManager().URLsForDirectory(.DocumentDirectory, inDomains: .UserDomainMask)
        return urls[urls.count-1]
    }()
    
    func application(application: UIApplication, supportedInterfaceOrientationsForWindow window: UIWindow?) -> UIInterfaceOrientationMask
    {
        if let presentedVc = self.window?.rootViewController?.presentedViewController as? OrientationsNavigationController
        {
            return presentedVc.supportedViewOrientations()
        }
        return UIInterfaceOrientationMask.Portrait
    }

}

