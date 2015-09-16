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
    
    var sharelinkTags:[SharelinkTag]!
    
    @IBOutlet weak var levelLabel: UILabel!
    var rootController:UIViewController!
    @IBOutlet weak var headIconImageView: UIImageView!{
        didSet{
            headIconImageView.layer.cornerRadius = 3.0
            headIconImageView.userInteractionEnabled = true
            headIconImageView.addGestureRecognizer(UITapGestureRecognizer(target: self, action: "showHeadIcon:"))
        }
    }
    
    @IBOutlet weak var userNickTextField: UILabel!{
        didSet{
            userNickTextField.userInteractionEnabled = true
            userNickTextField.addGestureRecognizer(UITapGestureRecognizer(target: self, action: "showProfile:"))
        }
    }
    
    func showProfile(_:UIGestureRecognizer)
    {
        ServiceContainer.getService(UserService).showUserProfileViewController(self.rootController.navigationController!, userProfile: self.userModel, tags: self.sharelinkTags)
    }
    
    func showHeadIcon(_:UIGestureRecognizer)
    {
        let imageFileFetcher = ServiceContainer.getService(FileService).getFileFetcher(FileType.Image)
        UIImagePlayerController.showImagePlayer(self.rootController, imageUrls: [userModel.headIconId ?? ImageAssetsConstants.defaultHeadIcon],imageFileFetcher: imageFileFetcher)
    }
    
    func update()
    {
        userNickTextField.text = userModel.noteName ?? userModel.nickName
        levelLabel.text = "Lv.\(userModel.level ?? 1)"
        updateHeadIcon()
    }
    
    func updateHeadIcon()
    {
        let fileService = ServiceContainer.getService(FileService)
        fileService.setHeadIcon(self.headIconImageView, iconFileId: userModel.headIconId)
    }

}