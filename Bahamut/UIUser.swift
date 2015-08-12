//
//  UIUser.swift
//  Bahamut
//
//  Created by AlexChow on 15/8/8.
//  Copyright (c) 2015年 GStudio. All rights reserved.
//

import UIKit

class UIUser: UITableViewCell
{
    var userModel:ShareLinkUser!{
        didSet{
            update()
        }
    }
    @IBOutlet weak var headIconImageView: UIImageView!
    @IBOutlet weak var userNickTextField: UILabel!
    
    func update()
    {
        userNickTextField.text = userModel.nickName
        ServiceContainer.getService(FileService).getFile(userModel.headIconId, returnCallback: { (filePath) -> Void in
            self.headIconImageView.image = PersistentManager.sharedInstance.getImage(self.userModel.headIconId, filePath: filePath)
        })
    }
}