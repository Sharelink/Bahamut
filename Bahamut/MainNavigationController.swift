//
//  MainNavigationController.swift
//  Bahamut
//
//  Created by AlexChow on 15/7/29.
//  Copyright (c) 2015年 GStudio. All rights reserved.
//

import UIKit

class MainNavigationController: UINavigationController,HandleSharelinkCmdDelegate
{
    struct SegueIdentifier
    {
        static let ShowSignView = "Show Sign View"
        static let ShowMainView = "Show Main Navigation"
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        let launchScr = NSBundle.mainBundle().loadNibNamed("LaunchScreen", owner: nil, options: nil).filter{$0 is UIView}.first as! UIView
        launchScr.frame = self.view.bounds
        self.view.backgroundColor = UIColor.blackColor()
        self.view.addSubview(launchScr)
    }
    
    func deInitController(){

    }
    
    override func viewDidAppear(animated: Bool) {
        super.viewDidAppear(animated)
        go()
    }
    
    
    func allServicesReady(_:AnyObject)
    {
        ServiceContainer.instance.removeObserver(self)
        if let _ = self.presentedViewController
        {
            let notiService = ServiceContainer.getService(NotificationService)
            notiService.setMute(false)
            notiService.setVibration(true)
            MainNavigationController.start()
        }else
        {
            showMainView()
        }
    }
    
    private func go()
    {
        ServiceContainer.instance.addObserver(self, selector: "allServicesReady:", name: ServiceContainer.AllServicesReady, object: nil)
        if SharelinkSetting.isUserLogined
        {
            if ServiceContainer.isAllServiceReady
            {
                ServiceContainer.instance.removeObserver(self)
                showMainView()
            }else
            {
                ServiceContainer.instance.userLogin(SharelinkSetting.userId)
            }
        }else
        {
            showSignView()
        }
    }
    
    private func showSignView()
    {
        NSTimer.scheduledTimerWithTimeInterval(1, target: self, selector: "waitTimeShowSignView:", userInfo: nil, repeats: false)
    }
    
    func waitTimeShowSignView(_:AnyObject?)
    {
        performSegueWithIdentifier(SegueIdentifier.ShowSignView, sender: self)
    }
    
    private func showMainView()
    {
        NSTimer.scheduledTimerWithTimeInterval(1, target: self, selector: "waitTimeShowMainView:", userInfo: nil, repeats: false)
    }
    
    func waitTimeShowMainView(_:AnyObject?)
    {
        SharelinkCmdManager.sharedInstance.registHandler(self)
        self.performSegueWithIdentifier(SegueIdentifier.ShowMainView, sender: self)
    }
    
    //MARK: handle sharelinkMessage
    
    func linkMe(method: String, args: [String],object:AnyObject?)
    {
        if args.count < 3
        {
            self.showAlert("Sharelink", msg: NSLocalizedString("UNKNOW_SHARELINK_CMD", comment: "Unknow Sharelink Command"))
            return
        }
        let sharelinkerId = args[0]
        let sharelinkerNick = args[1]
        let expriedAt = args[2].dateTimeOfString
        if expriedAt.timeIntervalSince1970 < NSDate().timeIntervalSince1970
        {
            self.showAlert("Sharelink", msg: NSLocalizedString("SHARELINK_CMD_TIMEOUT", comment: "Sharelink Command Timeout"))
            return
        }
        let userService = ServiceContainer.getService(UserService)
        if userService.isSharelinkerLinked(sharelinkerId)
        {
            if let navc = MainViewTabBarController.currentNavicationController
            {
                userService.showUserProfileViewController(navc, userId: sharelinkerId)
            }
        }else
        {
            let yes = UIAlertAction(title: NSLocalizedString("YES", comment: ""), style: .Default, handler: { (action) -> Void in
                userService.askSharelinkForLink(sharelinkerId, callback: { (isSuc) -> Void in
                    if isSuc
                    {
                        self.showAlert("Sharelink" ,msg:NSLocalizedString("LINK_REQUEST_SENDED", comment: "Ask for link sended"))
                    }
                })
            })
            let no = UIAlertAction(title: NSLocalizedString("NO", comment: ""), style: .Cancel,handler:nil)
            let title = NSLocalizedString("SHARELINK", comment: "")
            let msg = String(format: NSLocalizedString("SEND_LINK_REQUEST_TO", comment:"Send link request to %@"),sharelinkerNick)
            self.showAlert(title, msg:msg, actions: [yes,no])
        }
    }
    
    func handleSharelinkCmd(method: String, args: [String],object:AnyObject?) {
        switch method
        {
        case "linkMe":linkMe(method, args: args, object: object)
        default:break
        }
    }
    
    private static func instanceFromStoryBoard() -> MainNavigationController
    {
        return instanceFromStoryBoard("Main", identifier: "mainNavigationController") as! MainNavigationController
    }
    
    static func start()
    {
        dispatch_async(dispatch_get_main_queue(), { () -> Void in
            if let mnc = UIApplication.sharedApplication().delegate?.window!?.rootViewController as? MainNavigationController{
                mnc.deInitController()
            }
            UIApplication.sharedApplication().delegate?.window!?.rootViewController = instanceFromStoryBoard()
        })
    }
}
