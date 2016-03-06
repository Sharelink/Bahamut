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
import ImagePicker
import CoreMotion

class Sharelink
{
    static func mainBundle() -> NSBundle{
        if isSDKVersion
        {
            if let path = NSBundle.mainBundle().pathForResource("SharelinkKernel", ofType: "bundle")
            {
                if let bundle = NSBundle(path: path)
                {
                    return bundle
                }
                
            }
            fatalError("No Kernel Resource Bundle")
        }else
        {
            return NSBundle.mainBundle()
        }
    }
    private(set) static var isSDKVersion:Bool = false
    static func isProductVersion() -> Bool{
        return !isSDKVersion
    }
}

@objc
public class SharelinkAppDelegate: UIResponder, UIApplicationDelegate {

    public static func startSharelink()
    {
        MainNavigationController.start()
    }
    
    public var window: UIWindow?
    
    public func application(application: UIApplication, didFinishLaunchingWithOptions launchOptions: [NSObject: AnyObject]?) -> Bool {
        configureSharelinkBundle()
        configContryAndLang()
        configureAliOSSManager()
        configureBahamutCmd()
        configureBahamutRFKit()
        configureImagePicker()
        
        #if APP_VERSION
        if Sharelink.isProductVersion()
        {
            configureUMessage(launchOptions)
            configureUmeng()
            configureShareSDK()
            initQuPai()
        }
        #endif
        initService()
        loadUI()
        return true
    }
    
    var isSDKVersion:Bool
    {
        return true
    }
    
    private func configureBahamutCmd()
    {
        BahamutCmd.signBahamutCmdSchema("sharelink")
    }
    
    private func configureAliOSSManager()
    {
        AliOSSManager.sharedInstance.initManager(SharelinkConfig.bahamutConfig.AliOssAccessKey, aliOssSecretKey: SharelinkConfig.bahamutConfig.AliOssSecretKey)
    }
    
    private func configureBahamutRFKit()
    {
        BahamutRFKit.appkey = SharelinkRFAppKey
        BahamutRFKit.setAppVersion(SharelinkVersion)
    }
    
    private func configureSharelinkBundle()
    {
        Sharelink.isSDKVersion = isSDKVersion
        loadBahamutConfig("BahamutConfig")
    }
    
    private func loadBahamutConfig(configName:String)
    {
        if let bahamutConfigPath = Sharelink.mainBundle().pathForResource(configName, ofType: "json")
        {
            if let json = PersistentFileHelper.readTextFile(bahamutConfigPath)
            {
                let config = BahamutConfigObject(json: json)
                SharelinkConfig.bahamutConfig = config
            }else
            {
                fatalError("Load Config File Error!")
            }
        }else
        {
            fatalError("No Config File!")
        }
    }
    
    private func initService()
    {
        ServiceContainer.instance.initContainer(SharelinkConfig.appName, services: ServiceConfig.Services)
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
    
    private func loadUI()
    {
        dispatch_async(dispatch_get_main_queue()) { () -> Void in
            ChatViewController.instanceFromStoryBoard()
            UserProfileViewController.instanceFromStoryBoard()
            UIEditTextPropertyViewController.instanceFromStoryBoard()
        }
    }
    
    private func configureImagePicker()
    {
        dispatch_async(dispatch_get_main_queue()) { () -> Void in
            let mmanger = CMMotionManager()
            if self.isSDKVersion == false
            {
                NSLog("AccelerometerActive:\(mmanger.accelerometerActive)")
            }
            Configuration.cancelButtonTitle = "CANCEL".localizedString()
            Configuration.doneButtonTitle = "DONE".localizedString()
            Configuration.settingsTitle = "SETTING".localizedString()
            Configuration.noCameraTitle = "CAMERA_NOT_AVAILABLE".localizedString()
            Configuration.noImagesTitle = "NO_IMAGES_AVAILABLE".localizedString()
        }
        
    }
    
    //MARK:PRODUCTION ONLY
    #if APP_VERSION
    
    private func configureUMessage(launchOptions: [NSObject: AnyObject]?)
    {
        dispatch_async(dispatch_get_main_queue()) { () -> Void in
            
            UMessage.startWithAppkey(SharelinkConfig.bahamutConfig.umengAppkey, launchOptions: launchOptions)
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
    }
    
    private func initQuPai()
    {
        TaeSDK.sharedInstance().asyncInit({ () -> Void in
            NSLog("TaeSDK Inited")
            }) { (error) -> Void in
                fatalError(error.description)
        }
    }
    
    private func configureUmeng()
    {
        #if RELEASE
            dispatch_async(dispatch_get_main_queue()) { () -> Void in
                MobClick.startWithAppkey(SharelinkConfig.bahamutConfig.umengAppkey, reportPolicy: BATCH, channelId: nil)
                MobClick.setAppVersion(SharelinkVersion)
                MobClick.setEncryptEnabled(true)
                MobClick.setLogEnabled(false)
            }
        #endif
    }

    private func configureShareSDK()
    {
        dispatch_async(dispatch_get_main_queue()) { () -> Void in
            ShareSDK.registerApp(SharelinkConfig.bahamutConfig.shareSDKAppkey)
            if(SharelinkSetting.contry == "CN")
            {
                self.connectChinaApps()
                self.connectGlobalApps()
            }else{
                self.connectGlobalApps()
                self.connectChinaApps()
            }
            
            //SMS Mail
            ShareSDK.connectSMS()
            ShareSDK.connectMail()
            
            ShareSDK.ssoEnabled(true)
        }
        
    }
    
    
    
    private func connectGlobalApps()
    {
        //Facebook
        //ShareSDK.connectFacebookWithAppKey(SharelinkConfig.bahamutConfig.facebookAppkey, appSecret: SharelinkConfig.bahamutConfig.facebookAppScrect)
        
        //WhatsApp
        ShareSDK.connectWhatsApp()
    }
    
    private func connectChinaApps()
    {
        //微信登陆的时候需要初始化
        ShareSDK.connectWeChatSessionWithAppId(SharelinkConfig.bahamutConfig.wechatAppkey, appSecret: SharelinkConfig.bahamutConfig.wechatAppScrect, wechatCls: WXApi.classForCoder())
        ShareSDK.connectWeChatTimelineWithAppId(SharelinkConfig.bahamutConfig.wechatAppkey, appSecret: SharelinkConfig.bahamutConfig.wechatAppScrect, wechatCls: WXApi.classForCoder())
        
        //添加QQ应用  注册网址   http://mobile.qq.com/api/
        ShareSDK.connectQQWithAppId(SharelinkConfig.bahamutConfig.qqAppkey, qqApiCls: QQApiInterface.classForCoder())
        
        //Weibo
//        ShareSDK.connectSinaWeiboWithAppKey(SharelinkConfig.bahamutConfig.weiboAppkey, appSecret: SharelinkConfig.bahamutConfig.weiboAppScrect, redirectUri: "https://api.weibo.com/oauth2/default.html",weiboSDKCls: WeiboSDK.classForCoder())
        
    }
    
    #endif
    
    //MARK: AppDelegate
    
    public func application(application: UIApplication, didRegisterForRemoteNotificationsWithDeviceToken deviceToken: NSData) {
        #if APP_VERSION
            UMessage.registerDeviceToken(deviceToken)
        #endif
        SharelinkSetting.deviceToken = deviceToken.description
            .stringByReplacingOccurrencesOfString("<", withString: "")
            .stringByReplacingOccurrencesOfString(">", withString: "")
            .stringByReplacingOccurrencesOfString(" ", withString: "")
        ChicagoClient.sharedInstance.registDeviceToken(SharelinkSetting.deviceToken)
    }
    
    public func application(application: UIApplication, didReceiveRemoteNotification userInfo: [NSObject : AnyObject]) {
        #if APP_VERSION
            UMessage.didReceiveRemoteNotification(userInfo)
        #endif
    }
    
    public func application(application: UIApplication, didFailToRegisterForRemoteNotificationsWithError error: NSError) {
        NSLog("%@", error.description)
    }
    
    public func application(app: UIApplication, openURL url: NSURL, options: [String : AnyObject]) -> Bool {
        if url.scheme == BahamutCmd.cmdUrlSchema
        {
            return handleSharelinkUrl(url)
        }else
        {
            #if APP_VERSION
                return ShareSDK.handleOpenURL(url, wxDelegate: self)
            #else
                return true
            #endif
        }
    }
    
    public func application(application: UIApplication, openURL url: NSURL, sourceApplication: String?, annotation: AnyObject) -> Bool {
        if url.scheme == BahamutCmd.cmdUrlSchema
        {
            return handleSharelinkUrl(url)
        }else
        {
            #if APP_VERSION
                return ShareSDK.handleOpenURL(url, sourceApplication: sourceApplication, annotation: annotation, wxDelegate: self)
            #else
                return true
            #endif
        }
    }
    
    public func application(application: UIApplication, handleOpenURL url: NSURL) -> Bool {
        return handleSharelinkUrl(url)
    }
    
    
    private func handleSharelinkUrl(url:NSURL) -> Bool
    {
        if url.scheme == BahamutCmd.cmdUrlSchema
        {
            let cmd = BahamutCmd.getCmdFromUrl(url.absoluteString)
            BahamutCmdManager.sharedInstance.pushCmd(cmd)
        }
        return true
    }
    
    public func applicationWillResignActive(application: UIApplication) {
        // Sent when the application is about to move from active to inactive state. This can occur for certain types of temporary interruptions (such as an incoming phone call or SMS message) or when the user quits the application and it begins the transition to the background state.
        // Use this method to pause ongoing tasks, disable timers, and throttle down OpenGL ES frame rates. Games should use this method to pause the game.
    }

    public func applicationDidEnterBackground(application: UIApplication) {
        // Use this method to release shared resources, save user data, invalidate timers, and store enough application state information to restore your application to its current state in case it is terminated later.
        // If your application supports background execution, this method is called instead of applicationWillTerminate: when the user quits.
        PersistentManager.sharedInstance.saveAll()
        ChicagoClient.sharedInstance.inBackground()
    }

    public func applicationWillEnterForeground(application: UIApplication) {
        // Called as part of the transition from the background to the inactive state; here you can undo many of the changes made on entering the background.
        
    }

    public func applicationDidBecomeActive(application: UIApplication) {
        // Restart any tasks that were paused (or not yet started) while the application was inactive. If the application was previously in the background, optionally refresh the user interface.
        if ServiceContainer.isAllServiceReady
        {
            ServiceContainer.getService(UserService).getNewLinkMessageFromServer()
            ServiceContainer.getService(ShareService).getNewShareMessageFromServer()
            ServiceContainer.getService(ChatService).getMessageFromServer()
            ChicagoClient.sharedInstance.reConnect()
            if UserService.lastRefreshLinkedUserTime == nil || UserService.lastRefreshLinkedUserTime.timeIntervalSinceNow < -1000 * 3600 * 3
            {
                UserService.lastRefreshLinkedUserTime = NSDate()
                ServiceContainer.getService(UserService).refreshMyLinkedUsers()
            }
            BahamutCmdManager.sharedInstance.handleCmdQueue()
        }
    }

    public func applicationWillTerminate(application: UIApplication) {
        // Called when the application is about to terminate. Save data if appropriate. See also applicationDidEnterBackground:.
        // Saves changes in the application's managed object context before the application terminates.
        PersistentManager.sharedInstance.saveAll()
    }
    
    public func application(application: UIApplication, supportedInterfaceOrientationsForWindow window: UIWindow?) -> UIInterfaceOrientationMask
    {
        if let presentedVc = self.window?.rootViewController?.presentedViewController as? OrientationsNavigationController
        {
            return presentedVc.supportedViewOrientations()
        }
        return UIInterfaceOrientationMask.Portrait
    }

}

