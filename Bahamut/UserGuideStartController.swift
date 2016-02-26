//
//  UserGuideStartController.swift
//  Sharelink
//
//  Created by AlexChow on 16/1/29.
//  Copyright © 2016年 GStudio. All rights reserved.
//

import Foundation

let NewUserStartGuided = "NewUserStartGuidedV2"

class UserGuideStartController: UIViewController {
    
    private var hotThemes:[String]!
    @IBOutlet weak var helloMessageLabel: UILabel!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        self.getHotThemes()
        let userNick = ServiceContainer.getService(UserService).myUserModel.nickName
        let helloMsg = String(format: "HELLO_MESSAGE_FORMAT".localizedString(), userNick)
        helloMessageLabel.text = helloMsg
    }
    
    private func getHotThemes()
    {
        let req = GetHotThemesRequest()
        SharelinkSDK.sharedInstance.getShareLinkClient().execute(req) { (result:SLResult<GetHotThemesRequest.HotThemes>) -> Void in
            if let result = result.returnObject
            {
                if let themes = result.themes
                {
                    self.hotThemes = themes
                }
            }
        }
    }
    
    override func prepareForSegue(segue: UIStoryboardSegue, sender: AnyObject?) {
        if let dvc = segue.destinationViewController as? UserGuideThemeController
        {
            MobClick.event("UserGuide_ToTheme")
            if let ht = self.hotThemes
            {
                dvc.hotThemes = ht
            }
        }
    }
    
    static func startUserGuide(viewController:UIViewController) -> Bool
    {
        if !UserSetting.isSettingEnable(NewUserStartGuided)
        {
            let controller = instanceFromStoryBoard("UserGuide", identifier: "UserGuideStartController", bundle: Sharelink.mainBundle())
            let navController = UINavigationController(rootViewController: controller)
            navController.navigationBar.barStyle = viewController.navigationController!.navigationBar.barStyle
            navController.changeNavigationBarColor()
            navController.modalTransitionStyle = .FlipHorizontal
            viewController.navigationController!.presentViewController(navController, animated: true, completion: { () -> Void in
            })
            return true
        }
        return false
    }
}