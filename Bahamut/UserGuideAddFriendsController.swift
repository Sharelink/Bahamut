//
//  UserGuideAddFriendsController.swift
//  Sharelink
//
//  Created by AlexChow on 16/1/29.
//  Copyright © 2016年 GStudio. All rights reserved.
//

import Foundation
import UIKit

class UserGuideAddFriendsController: UIViewController
{
    override func viewDidAppear(animated: Bool) {
        super.viewDidAppear(animated)
        ServiceContainer.getService(UserService).shareAddLinkMessageToSNS(self)
    }
    @IBAction func done(sender: AnyObject) {
        UserSetting.setSetting(NewUserStartGuided, enable: true)
        self.dismissViewControllerAnimated(true) { () -> Void in
            MainViewTabBarController.currentTabBarViewController.selectedIndex = 3
        }
    }
}