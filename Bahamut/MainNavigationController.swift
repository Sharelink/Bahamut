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
            ServiceContainer.instance.userLogin(accountService.userId)
            performSegueWithIdentifier(SegueIdentifier.ShowMainView, sender: self)
        }else
        {
            performSegueWithIdentifier(SegueIdentifier.ShowSignView, sender: self)
        }
    }
    
    private static func instanceFromStoryBoard() -> MainNavigationController
    {
        return instanceFromStoryBoard("Main", identifier: "mainNavigationController") as! MainNavigationController
    }
    
    static func start(currentController:UIViewController,msg:String)
    {
        let mainController = instanceFromStoryBoard();
        currentController.presentViewController(mainController, animated: false) { () -> Void in
            mainController.view.makeToast(message: msg)
        }
    }
}
