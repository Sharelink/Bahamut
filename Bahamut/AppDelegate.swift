//
//  AppDelegate.swift
//  Bahamut
//
//  Created by AlexChow on 15/7/27.
//  Copyright (c) 2015年 GStudio. All rights reserved.
//

import UIKit
import CoreData
import SharelinkSDK

@UIApplicationMain
class AppDelegate: UIResponder, UIApplicationDelegate {

    var window: UIWindow?


    func application(application: UIApplication, didFinishLaunchingWithOptions launchOptions: [NSObject: AnyObject]?) -> Bool {
        initService()
        loadUI()
        configureShareSDK()
        return true
    }
    
    private func initService()
    {
        ServiceContainer.instance.initContainer()
        if BahamutSetting.isUserLogined
        {
            ServiceContainer.instance.userLogin(BahamutSetting.userId)
        }
    }
    
    private func loadUI()
    {
        ChatViewController.instanceFromStoryBoard()
        UserProfileViewController.instanceFromStoryBoard()
        UIEditTextPropertyViewController.instanceFromStoryBoard()
    }

    private func configureShareSDK()
    {
        ShareSDK.registerApp(BahamutConfig.shareSDKAppkey)
        let countryCode = NSLocale.currentLocale().objectForKey(NSLocaleCountryCode)
        if(countryCode!.description == "CN")
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
    
    private func connectGlobalApps()
    {
        //Facebook
        ShareSDK.connectFacebookWithAppKey("897418857006645", appSecret: "3c5fbcbc22201f96e1b5e93f7a0a69ff")
        
        //WhatsApp
        ShareSDK.connectWhatsApp()
    }
    
    private func connectChinaApps()
    {
        //微信登陆的时候需要初始化
        ShareSDK.connectWeChatSessionWithAppId("wx661037d16f05eb0b", appSecret: "d4624c36b6795d1d99dcf0547af5443d", wechatCls: WXApi.classForCoder())
        ShareSDK.connectWeChatTimelineWithAppId("wx661037d16f05eb0b", appSecret: "d4624c36b6795d1d99dcf0547af5443d", wechatCls: WXApi.classForCoder())
        
        //添加QQ应用  注册网址   http://mobile.qq.com/api/
        ShareSDK.connectQQWithAppId("1104930500", qqApiCls: QQApiInterface.classForCoder())
        
        //Weibo
//        ShareSDK.connectSinaWeiboWithAppKey("179608154", appSecret: "b79d50fb87ded0d281492b3113f3f988", redirectUri: "https://api.weibo.com/oauth2/default.html",weiboSDKCls: WeiboSDK.classForCoder())
        
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
    }

    func applicationWillEnterForeground(application: UIApplication) {
        // Called as part of the transition from the background to the inactive state; here you can undo many of the changes made on entering the background.
        
    }

    func applicationDidBecomeActive(application: UIApplication) {
        // Restart any tasks that were paused (or not yet started) while the application was inactive. If the application was previously in the background, optionally refresh the user interface.
        if BahamutSetting.isUserLogined
        {
            ServiceContainer.getService(MessageService).getMessageFromServer()
            ServiceContainer.getService(UserService).getNewLinkMessageFromServer()
            ServiceContainer.getService(ShareService).getNewShareMessageFromServer()
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
        self.saveContext()
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

    lazy var managedObjectModel: NSManagedObjectModel = {
        // The managed object model for the application. This property is not optional. It is a fatal error for the application not to be able to find and load its model.
        let modelURL = NSBundle.mainBundle().URLForResource("Bahamut", withExtension: "momd")!
        return NSManagedObjectModel(contentsOfURL: modelURL)!
    }()
    
    private var persistentStoreCoordinator: NSPersistentStoreCoordinator?
    
    private func initPersistentStoreCoordinator(dbFileUrl:NSURL) -> NSPersistentStoreCoordinator{
        // The persistent store coordinator for the application. This implementation creates and returns a coordinator, having added the store for the application to it. This property is optional since there are legitimate error conditions that could cause the creation of the store to fail.
        // Create the coordinator and store
        
        let optionsDictionary = [NSMigratePersistentStoresAutomaticallyOption:NSNumber(bool: true),NSInferMappingModelAutomaticallyOption:NSNumber(bool: true)]
        
        let coordinator = NSPersistentStoreCoordinator(managedObjectModel: self.managedObjectModel)
        let currentPersistentStore = dbFileUrl
        let failureReason = "There was an error creating or loading the application's saved data."
        do {
            try coordinator.addPersistentStoreWithType(NSSQLiteStoreType, configuration: nil, URL: currentPersistentStore, options: optionsDictionary)
        } catch {
            // Report any error we got.
            var dict = [String: AnyObject]()
            dict[NSLocalizedDescriptionKey] = "Failed to initialize the application's saved data"
            dict[NSLocalizedFailureReasonErrorKey] = failureReason
            
            dict[NSUnderlyingErrorKey] = error as NSError
            let wrappedError = NSError(domain: "YOUR_ERROR_DOMAIN", code: 9999, userInfo: dict)
            // Replace this with code to handle the error appropriately.
            // abort() causes the application to generate a crash log and terminate. You should not use this function in a shipping application, although it may be useful during development.
            NSLog("Unresolved error \(wrappedError), \(wrappedError.userInfo)")
            
            abort()
        }
        
        return coordinator
    }
    
    func initmanagedObjectContext(dbFileUrl:NSURL)
    {
        if !BahamutSetting.isUserLogined
        {
            NSLog("user not login")
            abort()
        }else if managedObjectContext != nil
        {
            NSLog("can not reinit")
            abort()
        }
        self.persistentStoreCoordinator = initPersistentStoreCoordinator(dbFileUrl)
        let coordinator = self.persistentStoreCoordinator
        managedObjectContext = NSManagedObjectContext(concurrencyType: .MainQueueConcurrencyType)
        managedObjectContext.persistentStoreCoordinator = coordinator
    }

    func deinitManagedObjectContext()
    {
        saveContext()
        persistentStoreCoordinator = nil
        managedObjectContext = nil
    }
    
    private(set) var managedObjectContext: NSManagedObjectContext!

    // MARK: - Core Data Saving support

    func saveContext () {
        if managedObjectContext.hasChanges {
            do {
                try managedObjectContext.save()
            } catch {
                // Replace this implementation with code to handle the error appropriately.
                // abort() causes the application to generate a crash log and terminate. You should not use this function in a shipping application, although it may be useful during development.
                let nserror = error as NSError
                NSLog("Unresolved error \(nserror), \(nserror.userInfo)")
                abort()
            }
        }
    }

}

