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
        MobClick.event("UserGuide_ToAddFriends")
        dispatch_async(dispatch_get_main_queue()) { () -> Void in
            ServiceContainer.getService(UserService).shareAddLinkMessageToSNS(self)
        }
    }
    
    @IBAction func addMore(sender: AnyObject) {
        MobClick.event("UserGuide_AddFriend")
        ServiceContainer.getService(UserService).shareAddLinkMessageToSNS(self)
    }
    
}