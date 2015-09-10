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
    func showEditProfileViewController(navigationController:UINavigationController,userModel:ShareLinkUser)
    {
        let profileViewController = EditProfileViewController.instanceFromStoryBoard()
        profileViewController.model = userModel
        profileViewController.isRegistNewUser = false
        navigationController.pushViewController(profileViewController, animated: true)
    }
    
    func showRegistNewUserController(navigationController:UINavigationController,registModel:RegistModel)
    {
        let profileViewController = EditProfileViewController.instanceFromStoryBoard()
        profileViewController.isRegistNewUser = true
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

class EditProfileViewController: UIViewController,UITextFieldDelegate
{
    var isRegistNewUser:Bool = false
    var registModel:RegistModel!
    var model:ShareLinkUser!
    @IBOutlet weak var nickNameTextfield: UITextField!
    @IBOutlet weak var saveProfileButton: UIButton!
    @IBOutlet weak var profileVideoView:UIView!{
        didSet{
            
        }
    }
    @IBOutlet weak var headIconImage: UIImageView!{
        didSet{
            headIconImage.addGestureRecognizer(UITapGestureRecognizer(target: self, action: "takeHeadIconPhoto:"))
        }
    }
    
    private func initProfileVideoPlayer()
    {
        
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
    
    func textFieldDidEndEditing(textField: UITextField) {
        self.model.nickName = textField.text
    }
    
    @IBAction func saveProfile()
    {
        model.nickName = nickNameTextfield.text
        if isRegistNewUser
        {
            ServiceContainer.getService(UserService).registNewUser(self.registModel, newUser: model){ isSuc,msg in
                if isSuc
                {
                    MainNavigationController.start(self.navigationController!, msg: "Regist Success")
                }else
                {
                    self.view.makeToast(message: msg)
                }
            }
        }else{
            ServiceContainer.getService(UserService).setProfileNick(model.nickName)
        }
    }

    
    func captureProfileVideo(_:UIGestureRecognizer! = nil)
    {
        print("captureProfileVideo()")
    }
    
    func takeHeadIconPhoto(_:UIGestureRecognizer! = nil)
    {
        print("takeHeadIconPhoto()")
    }
    
    static func instanceFromStoryBoard()->EditProfileViewController{
        return instanceFromStoryBoard("UserAccount", identifier: "editProfileViewController") as! EditProfileViewController
    }
}
