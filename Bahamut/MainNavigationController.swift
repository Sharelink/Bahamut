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
        SharelinkCmdManager.sharedInstance.registHandler(self)
        self.view.backgroundColor = UIColor.whiteColor()
        
    }
    
    override func viewDidAppear(animated: Bool) {
        super.viewDidAppear(animated)
        go()
    }
    
    private func go()
    {
        if BahamutSetting.isUserLogined
        {
            performSegueWithIdentifier(SegueIdentifier.ShowMainView, sender: self)
            //login get message
            ServiceContainer.getService(UserService).getNewLinkMessageFromServer()
            ServiceContainer.getService(ShareService).getNewShareMessageFromServer()
            ServiceContainer.getService(MessageService).getMessageFromServer()
        }else
        {
            performSegueWithIdentifier(SegueIdentifier.ShowSignView, sender: self)
        }
    }
    
    private static func instanceFromStoryBoard() -> MainNavigationController
    {
        return instanceFromStoryBoard("Main", identifier: "mainNavigationController") as! MainNavigationController
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
    
    static func start()
    {
        dispatch_async(dispatch_get_main_queue(), { () -> Void in
            UIApplication.sharedApplication().delegate?.window!?.rootViewController = instanceFromStoryBoard()
        })
    }
}
