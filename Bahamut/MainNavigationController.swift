//
//  MainNavigationController.swift
//  Bahamut
//
//  Created by AlexChow on 15/7/29.
//  Copyright (c) 2015年 GStudio. All rights reserved.
//

import UIKit

class MainNavigationController: UINavigationController
{
    struct SegueIdentifier
    {
        static let ShowSignView = "Show Sign View"
        static let ShowMainView = "Show Main Navigation"
    }
    
    override func viewDidAppear(animated: Bool)
    {
        super.viewDidAppear(animated)
        let accountService = ServiceContainer.getService(AccountService)
        if accountService.isUserLogined
        {
            let fService = ServiceContainer.getService(FileService)
            fService.initUserFoldersWithUserId(accountService.userId)
            performSegueWithIdentifier(SegueIdentifier.ShowMainView, sender: self)
        }else
        {
            performSegueWithIdentifier(SegueIdentifier.ShowSignView, sender: self)
        }
    }
    
    static func InstanceFromStoryBoard() -> MainNavigationController
    {
        let storyBorad = UIStoryboard(name: "Main", bundle: NSBundle.mainBundle())
        return storyBorad.instantiateViewControllerWithIdentifier("mainNavigationController") as! MainNavigationController
    }
}
