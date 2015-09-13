//
//  ProfileViewController.swift
//  Bahamut
//
//  Created by AlexChow on 15/7/28.
//  Copyright (c) 2015年 GStudio. All rights reserved.
//

import UIKit

extension UserService
{
    
    func showRegistNewUserController(navigationController:UINavigationController,registModel:RegistModel)
    {
        let profileViewController = NewUserProfileViewController.instanceFromStoryBoard()
        profileViewController.registModel = registModel
        profileViewController.model = ShareLinkUser()
        navigationController.pushViewController(profileViewController, animated: true)
    }
}

class RegistModel {
    var registUserServer:String!
    var accountId:String!
    var accessToken:String!
}

class NewUserProfileViewController: UIViewController
{
    var registModel:RegistModel!
    var model:ShareLinkUser!
    @IBOutlet weak var nickNameTextfield: UITextField!
    @IBOutlet weak var signText: UITextField!

    @IBOutlet weak var headIconImage: UIImageView!{
        didSet{
            headIconImage.addGestureRecognizer(UITapGestureRecognizer(target: self, action: "takeHeadIconPhoto:"))
        }
    }
    
    override func viewWillAppear(animated: Bool) {
        super.viewWillAppear(animated)
        update()
    }
    
    func update()
    {
        let fService = ServiceContainer.getService(FileService)
        fService.setHeadIcon(headIconImage, iconFileId: model.headIconId)
    }
    
    @IBAction func saveProfile()
    {
        model.nickName = nickNameTextfield.text
        model.signText = signText.text
        ServiceContainer.getService(UserService).registNewUser(self.registModel, newUser: model){ isSuc,msg in
            if isSuc
            {
                MainNavigationController.start(self.navigationController!, msg: "Regist Success")
            }else
            {
                self.view.makeToast(message: msg)
            }
        }
    }
    
    func takeHeadIconPhoto(_:UIGestureRecognizer! = nil)
    {
        print("takeHeadIconPhoto()")
    }
    
    static func instanceFromStoryBoard()->NewUserProfileViewController{
        return instanceFromStoryBoard("UserAccount", identifier: "newUserProfileViewController") as! NewUserProfileViewController
    }
}
