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
        self.setBackgroundView()
        AppDelegate.startSharelink()
    }

    private func setBackgroundView()
    {
        let launchScr = MainNavigationController.getLaunchScreen(self.view.bounds)
        self.view.addSubview(launchScr)
    }
}