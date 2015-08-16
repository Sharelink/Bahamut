//
//  UIUser.swift
//  Bahamut
//
//  Created by AlexChow on 15/8/8.
//  Copyright (c) 2015年 GStudio. All rights reserved.
//

import UIKit

class UIUserListCell: UITableViewCell
{
    var userModel:ShareLinkUser!{
        didSet{
            update()
        }
    }
    var rootController:UIViewController!
    @IBOutlet weak var headIconImageView: UIImageView!{
        didSet{
            headIconImageView.addGestureRecognizer(UITapGestureRecognizer(target: self, action: "showHeadIcon:"))
        }
    }
    @IBOutlet weak var userNickTextField: UILabel!{
        didSet{
            userNickTextField.addGestureRecognizer(UITapGestureRecognizer(target: self, action: "showProfile:"))
        }
    }
    
    func showProfile(_:UIGestureRecognizer)
    {
        ServiceContainer.getService(UserService).showUserProfileViewController(rootController.navigationController!, userId: userModel.userId)
    }
    
    func showHeadIcon(_:UIGestureRecognizer)
    {
        
    }
    
    func update()
    {
        userNickTextField.text = userModel.noteName ?? userModel.nickName
        ServiceContainer.getService(FileService).getFile(userModel.headIconId, returnCallback: { (filePath) -> Void in
            self.headIconImageView.image = PersistentManager.sharedInstance.getImage(self.userModel.headIconId, filePath: filePath)
        })
    }
}