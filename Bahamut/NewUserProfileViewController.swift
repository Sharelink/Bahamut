//
//  ProfileViewController.swift
//  Bahamut
//
//  Created by AlexChow on 15/7/28.
//  Copyright (c) 2015年 GStudio. All rights reserved.
//

import UIKit


extension AccountService
{
    
    func showRegistNewUserController(nvController:UINavigationController,registModel:RegistModel)
    {
        let profileViewController = NewUserProfileViewController.instanceFromStoryBoard()
        let pnvController = UINavigationController(rootViewController: profileViewController)
        profileViewController.registModel = registModel
        nvController.presentViewController(pnvController, animated: true, completion: nil)
    }
}

class RegistModel {
    var registUserServer:String!
    var accountId:String!
    var accessToken:String!
    var userName:String!
    var region:String!
}

class NewUserProfileViewController: UIViewController
{
    var registModel:RegistModel!
    let model:Sharelinker! = Sharelinker()
    @IBOutlet weak var nickNameTextfield: UITextField!
    @IBOutlet weak var motto: UITextField!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        changeNavigationBarColor()
    }

    override func viewWillAppear(animated: Bool) {
        super.viewWillAppear(animated)
        self.nickNameTextfield.text = registModel.userName
    }
    
    @IBAction func saveProfile()
    {
        model.nickName = nickNameTextfield.text
        model.motto = motto.text
        let hud = self.showActivityHudWithMessage("",message:"REGISTING".localizedString())
        ServiceContainer.getService(AccountService).registNewUser(self.registModel, newUser: model){ isSuc,msg,validateResult in
            hud.hideAsync(true)
            if isSuc
            {
                self.showActivityHudWithMessage("",message:"REFRESHING".localizedString())
            }else
            {
                ServiceContainer.instance.removeObserver(self)
                self.playToast( msg)
            }
        }
    }
    
    static func instanceFromStoryBoard()->NewUserProfileViewController{
        return instanceFromStoryBoard("UserAccount", identifier: "NewUserProfileViewController",bundle: Sharelink.mainBundle()) as! NewUserProfileViewController
    }
}
