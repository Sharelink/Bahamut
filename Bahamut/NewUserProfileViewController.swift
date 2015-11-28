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
        if let nvc = self.navigationController as? NewUserProfileViewNVController
        {
            self.registModel = nvc.registModel
            self.nickNameTextfield.text = registModel.userName
        }
    }

    @IBAction func saveProfile()
    {
        model.nickName = nickNameTextfield.text
        model.motto = motto.text
        setSignSuccessObserver()
        self.makeToastActivityWithMessage("",message:NSLocalizedString("REGISTING", comment: "Registing"))
        ServiceContainer.getService(AccountService).registNewUser(self.registModel, newUser: model){ isSuc,msg,validateResult in
            self.hideToastActivity()
            if isSuc
            {
                self.makeToastActivityWithMessage("",message:NSLocalizedString("REFRESHING", comment: "Refreshing"))
            }else
            {
                self.showToast( msg)
            }
        }
    }
    
    func setSignSuccessObserver()
    {
        let service = ServiceContainer.getService(UserService)
        ServiceContainer.getService(UserService).myLinkedUsersMap.keys
        service.addObserver(self, selector: "initUsers:", name: UserService.baseUserDataInited, object: service)
    }
    
    func initUsers(_:AnyObject)
    {
        self.hideToastActivity()
        let service = ServiceContainer.getService(UserService)
        service.removeObserver(self)
        MainNavigationController.start()
    }
    
    static func instanceFromStoryBoard()->NewUserProfileViewNVController{
        return instanceFromStoryBoard("UserAccount", identifier: "NewUserProfileViewNVController") as! NewUserProfileViewNVController
    }
}

class NewUserProfileViewNVController: UINavigationController
{
    var registModel:RegistModel!
}
