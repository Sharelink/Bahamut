//
//  MainViewTabBarController.swift
//  Bahamut
//
//  Created by AlexChow on 15/8/18.
//  Copyright © 2015年 GStudio. All rights reserved.
//

import UIKit
import MBProgressHUD

let ALERT_ACTION_OK = [UIAlertAction(title: NSLocalizedString("OK", comment: ""), style:.Cancel, handler: nil)]
let ALERT_ACTION_I_SEE = [UIAlertAction(title: NSLocalizedString("I_SEE", comment: ""), style:.Cancel, handler: nil)]


var toastActivityMap = [UIViewController:MBProgressHUD]()
extension UIViewController:MBProgressHUDDelegate
{
    func hideToastActivity()
    {
        if let hud = toastActivityMap.removeValueForKey(self)
        {
            dispatch_async(dispatch_get_main_queue(), { () -> Void in
                hud.hide(true)
            })
            
        }
    }
    
    public func hudWasHidden(hud: MBProgressHUD!) {
        dispatch_async(dispatch_get_main_queue(), { () -> Void in
            hud.removeFromSuperview()
        })
        
    }
    
    func makeToastActivity()
    {
        self.makeToastActivityWithMessage("", message: "")
    }
    
    func makeToastActivityWithMessage(title:String!,message:String!)
    {
        dispatch_async(dispatch_get_main_queue(), { () -> Void in
            let HUD = MBProgressHUD(view: self.navigationController!.view)
            self.navigationController!.view.addSubview(HUD)
            
            HUD.delegate = self
            HUD.labelText = title
            HUD.detailsLabelText = message
            HUD.square = true
            HUD.show(true)
            toastActivityMap[self] = HUD
        })
        
    }
    
    func showToast(msg:String)
    {
        dispatch_async(dispatch_get_main_queue()) { () -> Void in
            let hud = MBProgressHUD.showHUDAddedTo(self.navigationController?.view, animated: true)
            // Configure for text only and offset down
            hud.mode = MBProgressHUDMode.Text
            hud.labelText = msg
            hud.margin = 10;
            hud.delegate = self
            hud.removeFromSuperViewOnHide = true
            hud.hide(true, afterDelay: 1)
        }
        
    }
    
    func showCheckMark(msg:String)
    {
        dispatch_async(dispatch_get_main_queue()) { () -> Void in
            let HUD = MBProgressHUD(view: self.navigationController!.view)
            self.navigationController?.view.addSubview(HUD)
            
            HUD.customView = UIImageView(image: UIImage(named: "Checkmark"))
            
            // Set custom view mode
            HUD.mode = MBProgressHUDMode.CustomView
            
            HUD.delegate = self
            HUD.labelText = msg
            HUD.square = true
            HUD.show(true)
            HUD.hide(true, afterDelay: 1)
        }
    }
    
    func showAlert(title:String!,msg:String!,actions:[UIAlertAction] = [UIAlertAction(title: NSLocalizedString("OK", comment: ""), style:.Cancel, handler: nil)])
    {
        let controller = UIAlertController(title: title, message: msg, preferredStyle: .Alert)
        for ac in actions
        {
            controller.addAction(ac)
        }
        showAlert(controller)
    }
    
    func showAlert(alertController:UIAlertController) -> Bool
    {
        if let vc = MainViewTabBarController.currentRootViewController
        {
            dispatch_async(dispatch_get_main_queue(), { () -> Void in
                vc.presentViewController(alertController, animated: true, completion: nil)
            })
            return true
        }else if let vc = MainViewTabBarController.currentNavicationController
        {
            dispatch_async(dispatch_get_main_queue(), { () -> Void in
                vc.presentViewController(alertController, animated: true, completion: nil)
            })
            return true
        }
        return false
    }
}

class MainViewTabBarController: UITabBarController ,OrientationsNavigationController,UITabBarControllerDelegate
{
    private(set) static var currentTabBarViewController:MainViewTabBarController!
    
    static var currentNavicationController:UINavigationController!{
        if let mc = currentTabBarViewController.selectedViewController as? UINavigationController
        {
            return mc
        }
        return nil
    }
    
    static var currentRootViewController:UIViewController!{
        if let mc = currentTabBarViewController.selectedViewController?.presentingViewController as? MainNavigationController
        {
            return mc.presentedViewController
        }
        return nil
    }
    
    private var notificationService:NotificationService!
    private var messageService:MessageService!
    private var shareService:ShareService!
    private var userService:UserService!
    
    func supportedViewOrientations() -> UIInterfaceOrientationMask
    {
        if let pvc = self.selectedViewController as? OrientationsNavigationController
        {
            return pvc.supportedViewOrientations()
        }
        return UIInterfaceOrientationMask.Portrait
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        self.view.backgroundColor = UIColor.whiteColor()
        notificationService = ServiceContainer.getService(NotificationService)
        shareService = ServiceContainer.getService(ShareService)
        userService = ServiceContainer.getService(UserService)
        messageService = ServiceContainer.getService(MessageService)
        self.delegate = self
    }
    
    override func viewWillAppear(animated: Bool) {
        super.viewWillAppear(animated)
        initBadges()
        MainViewTabBarController.currentTabBarViewController = self
        initObserver()
    }
    
    override func viewWillDisappear(animated: Bool) {
        super.viewWillAppear(animated)
        MainViewTabBarController.currentTabBarViewController = nil
        ServiceContainer.getService(MessageService).removeObserver(self)
        ServiceContainer.getService(ShareService).removeObserver(self)
        ServiceContainer.getService(UserService).removeObserver(self)
    }
    
    override func viewDidAppear(animated: Bool) {
        super.viewDidAppear(animated)
        refreshBadges()
    }
    
    func tabBarController(tabBarController: UITabBarController, didSelectViewController viewController: UIViewController)
    {
        setTabItemBadge(self.selectedIndex, badge: 0)
        refreshBadgeAt(self.selectedIndex)
    }
    
    
    private func initObserver()
    {
        messageService.addObserver(self, selector: "newChatMessageReceived:", name: MessageService.messageServiceNewMessageReceived, object: nil)
        shareService.addObserver(self, selector: "shareUpdatedMsgReceived:", name: ShareService.newShareMessagesUpdated, object: nil)
        userService.addObserver(self, selector: "newLinkMessageUpdated:", name: UserService.newLinkMessageUpdated, object: nil)
    }
    
    func newChatMessageReceived(aNotification:NSNotification)
    {
        if let messages = aNotification.userInfo?[MessageServiceNewMessageEntities] as? [MessageEntity]
        {
            if messages.count > 0
            {
                let chattingShare = messageService.chattingShareId
                let notChattingCount = messages.filter{$0.shareId != chattingShare}.count
                if notChattingCount > 0
                {
                    self.setTabItemBadge(MainViewTabBarController.ShareTabItemBadgeIndex, badge: badgeValue[MainViewTabBarController.ShareTabItemBadgeIndex] + notChattingCount)
                    notificationService.playReceivedMessageSound()
                    refreshBadgeAt(MainViewTabBarController.ShareTabItemBadgeIndex)
                }else
                {
                    notificationService.playVibration()
                }
                
            }
        }
    }
    
    func shareUpdatedMsgReceived(a:NSNotification)
    {
        if let msgs = a.userInfo?[NewShareMessages]
        {
            self.setTabItemBadge(MainViewTabBarController.ShareTabItemBadgeIndex, badge: badgeValue[MainViewTabBarController.ShareTabItemBadgeIndex] + msgs.count)
            self.notificationService.playHintSound()
            refreshBadgeAt(MainViewTabBarController.ShareTabItemBadgeIndex)
        }
    }
    
    func newLinkMessageUpdated(a:NSNotification)
    {
        if let newMsgs = a.userInfo?[UserServiceNewLinkMessage] as? [LinkMessage]
        {
            self.setTabItemBadge(MainViewTabBarController.SharelinkerTabItemBadge, badge: badgeValue[MainViewTabBarController.SharelinkerTabItemBadge] + newMsgs.count)
            self.notificationService.playHintSound()
            refreshBadgeAt(MainViewTabBarController.SharelinkerTabItemBadge)
        }
    }
    
    //MARK: badge
    private static let badgeKeys = ["ShareTabItemBadge","ThemeTabItemBadge","SharelinkerTabItemBadge","NewTabItemBadge"]
    static let ShareTabItemBadgeIndex = 0
    static let SharelinkerTabItemBadge = 2
    private var badgeValue = [0,0,0,0]
    
    func reduceTabItemBadge(tabItemIndex:Int,badgeReduce:Int)
    {
        setTabItemBadge(tabItemIndex, badge: badgeValue[tabItemIndex] - badgeReduce)
        refreshBadgeAt(tabItemIndex)
    }
    
    func addTabItemBadge(tabItemIndex:Int,badgeAdd:Int)
    {
        setTabItemBadge(tabItemIndex, badge: badgeValue[tabItemIndex] + badgeAdd)
        refreshBadgeAt(tabItemIndex)
    }
    
    private func setTabItemBadge(index:Int,badge:Int)
    {
        let badgeKey = generateBadgeKey(index)
        badgeValue[index] = badge
        NSUserDefaults.standardUserDefaults().setInteger(badge, forKey: badgeKey)
    }
    
    private func generateBadgeKey(index:Int) -> String
    {
        let badgeKey = "\(SharelinkSetting.lastLoginAccountId)\(MainViewTabBarController.badgeKeys[index])"
        return badgeKey
    }
    
    private func initBadges()
    {
        for index in 0 ..< badgeValue.count
        {
            badgeValue[index] = NSUserDefaults.standardUserDefaults().integerForKey(generateBadgeKey(index))
        }
    }
    
    private func refreshBadges()
    {
        for index in 0 ..< badgeValue.count
        {
            refreshBadgeAt(index)
        }
    }

    private func refreshBadgeAt(index:Int)
    {
        if let nvc = self.viewControllers?[index] as? UINavigationController
        {
            let badge = badgeValue[index]
            dispatch_async(dispatch_get_main_queue(), { () -> Void in
                nvc.tabBarItem.badgeValue = badge > 0 ? "\(badge)" : nil
            })
        }
    }
}
