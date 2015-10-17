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
        go()
    }
    
    func go()
    {
        if BahamutConfig.isUserLogined
        {
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
    
    static func start()
    {
        //let mainController = instanceFromStoryBoard();
        if let mainController = UIApplication.sharedApplication().delegate?.window!?.rootViewController as? MainNavigationController
        {
            mainController.navigationController?.popToRootViewControllerAnimated(false)
            mainController.go()
        }
    }
}
