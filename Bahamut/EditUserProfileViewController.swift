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
        let profileViewController = EditUserProfileViewController.instanceFromStoryBoard()
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

class EditUserProfileViewController: UIViewController
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
        let alert = UIAlertController(title: "Change HeadIcon", message: nil, preferredStyle: .ActionSheet)
        alert.addAction(UIAlertAction(title: "Take A Photo", style: .Destructive) { _ in
            self.takePhoto()
            })
        alert.addAction(UIAlertAction(title: "Select A Photo From Album", style: .Destructive) { _ in
            self.selectPhoto()
            })
        alert.addAction(UIAlertAction(title: "Cancel", style: .Cancel){ _ in})
        presentViewController(alert, animated: true, completion: nil)
    }
    
    func takePhoto()
    {
        
    }
    
    func selectPhoto()
    {
        
    }
    
    static func instanceFromStoryBoard()->EditUserProfileViewController{
        return instanceFromStoryBoard("UserAccount", identifier: "EditUserProfileViewController") as! EditUserProfileViewController
    }
}
