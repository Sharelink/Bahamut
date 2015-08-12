//
//  StartSegue.swift
//  Bahamut
//
//  Created by AlexChow on 15/8/5.
//  Copyright (c) 2015年 GStudio. All rights reserved.
//

import UIKit

class StartSegue: UIStoryboardSegue {
    override func perform() {
        self.sourceViewController.presentViewController(self.destinationViewController as! UIViewController,
            animated: false,
            completion: nil)
    }
}
