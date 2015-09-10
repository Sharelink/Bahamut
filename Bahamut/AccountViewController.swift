//
//  InfomationViewController.swift
//  Bahamut
//
//  Created by AlexChow on 15/7/28.
//  Copyright (c) 2015年 GStudio. All rights reserved.
//

import UIKit

class AccountViewController: UIViewController {
    static func instanceFromStoryBoard() -> AccountViewController
    {
        return instanceFromStoryBoard("UserAccount", identifier: "accountViewController") as! AccountViewController
    }
}
