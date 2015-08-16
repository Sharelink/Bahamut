//
//  UserProfileViewController.swift
//  Bahamut
//
//  Created by AlexChow on 15/8/15.
//  Copyright © 2015年 GStudio. All rights reserved.
//

import UIKit

extension UserService
{
    func showUserProfileViewController(currentNavigationController:UINavigationController,userId:String)
    {
        let controller = UIStoryboard(name: "Main", bundle: NSBundle.mainBundle()).instantiateViewControllerWithIdentifier("userProfileViewController") as! UserProfileViewController
        let userProfile = self.getUser(userId)
        controller.userProfileModel = userProfile
        currentNavigationController.pushViewController(controller , animated: true)
    }
}

class UserProfileViewController: UIViewController
{
    @IBOutlet weak var userProfileVideo: ShareLinkFilmView!
    @IBOutlet weak var headIconImageView: UIImageView!
    @IBOutlet weak var userSignTextView: UILabel!
    @IBOutlet weak var userNickNameLabelView: UILabel!
    var userProfileModel:ShareLinkUser!
    
    override func viewWillAppear(animated: Bool) {
        super.viewWillAppear(animated)
        update()
    }
    
    @IBAction func editProfileVideo()
    {
        
    }
    
    func update()
    {
        userNickNameLabelView.text = userProfileModel.noteName ?? userProfileModel.nickName
        userSignTextView.text = userProfileModel.signText
        ServiceContainer.getService(FileService).getFile(userProfileModel.headIconId, returnCallback: { (filePath) -> Void in
            self.headIconImageView.image = PersistentManager.sharedInstance.getImage(self.userProfileModel.headIconId, filePath: filePath)
        })
    }
}
