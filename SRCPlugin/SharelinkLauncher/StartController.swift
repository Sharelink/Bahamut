//
//  ViewController.swift
//  CSRCPluginTemplate
//
//  Created by AlexChow on 16/1/23.
//  Copyright © 2016年 Sharelink. All rights reserved.
//

import UIKit
import SharelinkKernel

class StartController: UINavigationController {

    override func viewDidLoad() {
        super.viewDidLoad()
        self.initWaitingScreen()
        SharelinkAppDelegate.startSharelink()
    }
    
    func initWaitingScreen()
    {
        let storyBoard = UIStoryboard(name: "LaunchScreen", bundle: NSBundle.mainBundle())
        let controller = storyBoard.instantiateViewControllerWithIdentifier("LaunchScreen")
        let launchScr = controller.view
        launchScr.frame = self.view.bounds
        self.view.backgroundColor = UIColor.blackColor()
        self.view.addSubview(launchScr)
    }
}

