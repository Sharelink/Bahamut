//
//  AppDelegate.swift
//  Bahamut
//
//  Created by AlexChow on 16/1/22.
//  Copyright © 2016年 GStudio. All rights reserved.
//

import Foundation
import UIKit

@UIApplicationMain
class AppDelegate: SharelinkAppDelegate {
    override var isSDKVersion:Bool {
        return false
    }
}

class EntryController: UINavigationController
{
    override func viewDidLoad() {
        super.viewDidLoad()
        let launchScr = Sharelink.mainBundle.loadNibNamed("LaunchScreen", owner: nil, options: nil).filter{$0 is UIView}.first as! UIView
        launchScr.frame = self.view.bounds
        self.view.backgroundColor = UIColor.blackColor()
        self.view.addSubview(launchScr)
        MainNavigationController.start()
    }
    
    override func viewDidAppear(animated: Bool) {
        super.viewDidAppear(animated)
        
    }
}