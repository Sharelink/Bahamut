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
    
    func showRegistNewUserController(currentController:UIViewController,registModel:RegistModel)
    {
        let profileViewNvController = NewUserProfileViewController.instanceFromStoryBoard()
        profileViewNvController.registModel = registModel
        currentController.presentViewController(profileViewNvController, animated: false) { () -> Void in
        }
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
    let model:ShareLinkUser! = ShareLinkUser()
    @IBOutlet weak var nickNameTextfield: UITextField!
    @IBOutlet weak var motto: UITextField!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        changeNavigationBarColor()
        if let nvc = self.navigationController as? NewUserProfileViewNVController
        {
            self.registModel = nvc.registModel
        }
    }

    @IBAction func saveProfile()
    {
        model.nickName = nickNameTextfield.text
        model.motto = motto.text
        ServiceContainer.getService(AccountService).registNewUser(self.registModel, newUser: model){ isSuc,msg,validateResult in
            if isSuc
            {
                self.signCallback()
            }else
            {
                self.view.makeToast(message: msg)
            }
        }
    }
    
    func signCallback()
    {
        let service = ServiceContainer.getService(UserService)
        service.addObserver(self, selector: "initUsers:", name: UserService.myUserInfoRefreshed, object: service)
        view.makeToastActivityWithMessage(message: "Refreshing")
    }
    
    func initUsers(_:AnyObject)
    {
        let service = ServiceContainer.getService(UserService)
        service.removeObserver(self)
        self.view.hideToastActivity()
        if service.myUserModel != nil
        {
            MainNavigationController.start()
        }else
        {
            self.view.makeToast(message: "Server Failed")
        }
    }
    
    static func instanceFromStoryBoard()->NewUserProfileViewNVController{
        return instanceFromStoryBoard("UserAccount", identifier: "NewUserProfileViewNVController") as! NewUserProfileViewNVController
    }
}

class NewUserProfileViewNVController: UINavigationController
{
    var registModel:RegistModel!
}
