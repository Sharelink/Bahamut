//
//  MainViewTabBarController.swift
//  Bahamut
//
//  Created by AlexChow on 15/8/18.
//  Copyright © 2015 GStudio. All rights reserved.
//

import UIKit

class MainViewTabBarController: UITabBarController ,OrientationsNavigationController,UITabBarControllerDelegate,SRCMenuManagerDelegate
{
    private(set) static var currentTabBarViewController:MainViewTabBarController!
    
    private var notificationService:NotificationService!
    private var messageService:ChatService!
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
        messageService = ServiceContainer.getService(ChatService)
        configureSRCMenuItem()
        self.delegate = self
    }
    
    private func configureSRCMenuItem()
    {
        let srcMenu = self.tabBar.items![2]
        let img = UIImage.namedImageInSharelink("src_menu_item")!.imageWithRenderingMode(.AlwaysOriginal)
        let sImg = UIImage.namedImageInSharelink("src_menu_item_s")!.imageWithRenderingMode(.AlwaysOriginal)
        srcMenu.image = img
        srcMenu.selectedImage = sImg
    }
    
    override func viewWillAppear(animated: Bool) {
        super.viewWillAppear(animated)
        initBadges()
        MainViewTabBarController.currentTabBarViewController = self
        initObserver()
    }
    
    override func viewDidAppear(animated: Bool) {
        super.viewDidAppear(animated)
        self.initSRCMenuManager()
        refreshBadges()
    }
    
    func tabBarController(tabBarController: UITabBarController, shouldSelectViewController viewController: UIViewController) -> Bool
    {
        if viewController is SRCMenuViewController
        {
            if self.srcMenuManager.isMenuShown
            {
                self.srcMenuManager.hideMenu()
            }else
            {
                self.beforeShownMenuTabBarIndex = self.selectedIndex
                self.tabBar.backgroundColor = UIColor.clearColor()
                
                self.srcMenuManager.showMenu()
                self.tabBar.superview?.bringSubviewToFront(self.tabBar)
            }
            return true
        }else
        {
            self.srcMenuManager.hideMenu()
        }
        return true
    }
    
    func tabBarController(tabBarController: UITabBarController, didSelectViewController viewController: UIViewController)
    {
        if badgeValue[self.selectedIndex] > 0
        {
            if let nvc = viewController as? UINavigationController
            {
                if let controller = nvc.topViewController as? ShareThingsListController
                {
                    controller.scrollTableViewToTop()
                }else if let controller = nvc.topViewController as? LinkedUserListController
                {
                    controller.scrollTableViewToTop()
                }
            }
        }
        setTabItemBadge(self.selectedIndex, badge: 0)
        refreshBadgeAt(self.selectedIndex)
        if UserSetting.isSettingEnable(TinkTinkTinkSetting)
        {
            SystemSoundHelper.keyTink()
        }
        
    }
    
    //MARK: SRCMenu
    private var beforeShownMenuTabBarIndex = 0
    private var srcMenuManager:SRCMenuManager!
    private func initSRCMenuManager()
    {
        if self.srcMenuManager == nil
        {
            self.srcMenuManager = SRCMenuManager()
            let menuTopInset:CGFloat = 23
            let menuBottomInset:CGFloat = self.tabBar.frame.height
            self.srcMenuManager.initManager(self.view,menuTopInset: menuTopInset,menuBottomInset:menuBottomInset)
            self.srcMenuManager.menuBackgroundImage = UIImage.namedImageInSharelink("defaultView")
            self.srcMenuManager.delegate = self
        }
    }
    
    //MARK: SRCMenuManagerDelegate
    func srcMenuDidHidden() {
        if selectedIndex == 2
        {
            self.selectedIndex = beforeShownMenuTabBarIndex
        }
    }
    
    func srcMenuDidShown() {
    }
    
    func srcMenuItemDidClick(itemView: SRCMenuItemView) {
        let share = ShareThing()
        share.shareType = itemView.srcPlugin.shareType
        let nvController = self.viewControllers![beforeShownMenuTabBarIndex] as! UINavigationController
        ServiceContainer.getService(ShareService).showNewShareController(nvController, shareModel: share, isReshare: false)
    }
    
    //MARK: message observer
    private func initObserver()
    {
        messageService.addObserver(self, selector: #selector(MainViewTabBarController.newChatMessageReceived(_:)), name: ChatService.messageServiceNewMessageReceived, object: nil)
        shareService.addObserver(self, selector: #selector(MainViewTabBarController.shareUpdatedMsgReceived(_:)), name: ShareService.newShareMessagesUpdated, object: nil)
        userService.addObserver(self, selector: #selector(MainViewTabBarController.newLinkMessageUpdated(_:)), name: UserService.newLinkMessageUpdated, object: nil)
        ServiceContainer.instance.addObserver(self, selector: #selector(MainViewTabBarController.onServiceLogout(_:)), name: ServiceContainer.OnServicesWillLogout, object: nil)
    }
    
    func onServiceLogout(sender:AnyObject)
    {
        if userService != nil
        {
            MainViewTabBarController.currentTabBarViewController = nil
            ServiceContainer.instance.removeObserver(self)
            userService.removeObserver(self)
            shareService.removeObserver(self)
            messageService.removeObserver(self)
            userService = nil
        }
    }
    
    func newChatMessageReceived(aNotification:NSNotification)
    {
        if let messages = aNotification.userInfo?[ChatServiceNewMessageEntities] as? [MessageEntity]
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
                    SystemSoundHelper.vibrate()
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
            self.setTabItemBadge(MainViewTabBarController.SharelinkerTabItemIndex, badge: badgeValue[MainViewTabBarController.SharelinkerTabItemIndex] + newMsgs.count)
            self.notificationService.playHintSound()
            refreshBadgeAt(MainViewTabBarController.SharelinkerTabItemIndex)
        }
    }
    
    //MARK: badge
    private static let badgeKeys = ["ShareTabItemBadge","ThemeTabItemBadge","SRCMenuTabItemBadge","SharelinkerTabItemBadge","NewTabItemBadge"]
    static let ShareTabItemBadgeIndex = 0
    static let NewShareTabItemIndex = 4
    static let SharelinkerTabItemIndex = 3
    private var badgeValue = [0,0,0,0,0]
    
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
        badgeValue[index] = badge > 0 ? badge : 0
        NSUserDefaults.standardUserDefaults().setInteger(badgeValue[index], forKey: badgeKey)
    }
    
    private func generateBadgeKey(index:Int) -> String
    {
        let badgeKey = "\(UserSetting.lastLoginAccountId)\(MainViewTabBarController.badgeKeys[index])"
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

//MARK: SRCMenuViewController
class SRCMenuViewController:UIViewController
{
}
