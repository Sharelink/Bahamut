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
    @IBOutlet weak var signText: UITextField!
    
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
        model.signText = signText.text
        ServiceContainer.getService(UserService).registNewUser(self.registModel, newUser: model){ isSuc,msg,validateResult in
            if isSuc
            {
                ServiceContainer.getService(AccountService).setLogined(validateResult)
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
        let accountService = ServiceContainer.getService(AccountService)
        ServiceContainer.instance.userLogin(accountService.userId)
        service.addObserver(self, selector: "initUsers:", name: UserService.userListUpdated, object: service)
        view.makeToastActivityWithMessage(message: "Refreshing")
        service.refreshMyLinkedUsers()
    }
    
    func initUsers(_:AnyObject)
    {
        let service = ServiceContainer.getService(UserService)
        service.removeObserver(self)
        self.view.hideToastActivity()
        if service.myLinkedUsers.count > 0
        {
            MainNavigationController.start("Regist Success")
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
