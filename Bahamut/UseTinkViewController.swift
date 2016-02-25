//
//  UseTinkViewController.swift
//  Bahamut
//
//  Created by AlexChow on 16/1/5.
//  Copyright © 2016年 GStudio. All rights reserved.
//

import UIKit

let TinkTinkTinkSetting = "TinkTinkTinkSetting"

class UseTinkViewController: UIViewController {

    @IBOutlet weak var enableTinkSwitch: UISwitch!
    override func viewDidLoad() {
        super.viewDidLoad()
        self.hidesBottomBarWhenPushed = true
        enableTinkSwitch.on = UserSetting.isSettingEnable(TinkTinkTinkSetting)
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
    @IBAction func onTinkSwitch(sender: AnyObject) {
        UserSetting.setSetting(TinkTinkTinkSetting, enable: enableTinkSwitch.on)
    }
    
    static func instanceFromStoryBoard()->UseTinkViewController{
        return instanceFromStoryBoard("Component", identifier: "UseTinkViewController",bundle: Sharelink.mainBundle()) as! UseTinkViewController
    }
}
