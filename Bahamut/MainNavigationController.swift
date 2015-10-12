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
    
    override func viewDidLoad() {
        super.viewDidLoad()
        self.view.backgroundColor = UIColor.whiteColor()
        
    }
    
    override func viewDidAppear(animated: Bool) {
        super.viewDidAppear(animated)
        let accountService = ServiceContainer.getService(AccountService)
        if BahamutConfig.isUserLogined
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
    
    static func start(msg:String)
    {
        let mainController = instanceFromStoryBoard();
        UIApplication.sharedApplication().delegate?.window!?.rootViewController?.removeFromParentViewController()
        UIApplication.sharedApplication().delegate?.window!?.rootViewController = mainController
    }
}
