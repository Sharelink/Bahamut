//
//  MainViewTabBarController.swift
//  Bahamut
//
//  Created by AlexChow on 15/8/18.
//  Copyright © 2015年 GStudio. All rights reserved.
//

import UIKit

class MainViewTabBarController: UITabBarController ,OrientationsNavigationController
{
    func supportedViewOrientations() -> UIInterfaceOrientationMask
    {
        if let pvc = self.selectedViewController as? OrientationsNavigationController
        {
            return pvc.supportedViewOrientations()
        }
        return UIInterfaceOrientationMask.Portrait
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        self.view.backgroundColor = UIColor.whiteColor()
    }
}
