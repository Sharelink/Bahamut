//
//  UIShareCell.swift
//  Bahamut
//
//  Created by AlexChow on 15/12/26.
//  Copyright © 2015年 GStudio. All rights reserved.
//

import Foundation
import UIKit

//MARK: UIShareCell
class UIShareCell : UITableViewCell
{
    static let dateFomatter:NSDateFormatter = {
        var formatter = NSDateFormatter()
        formatter.dateFormat = "yyyy-MM-dd"
        formatter.timeZone = NSTimeZone()
        return formatter
    }()
    var rootController:ShareThingsListController!{
        didSet{
            if oldValue == nil{                
                self.userInteractionEnabled = true
                self.addGestureRecognizer(UITapGestureRecognizer(target: self, action: "tapCell:"))
            }
        }
    }
    var shareModel:ShareThing!{
        didSet{
            if shareModel != nil
            {
                postUser = rootController.userService.getUser(shareModel.userId)
            }
        }
    }
    
    var postUser:Sharelinker?
    
    func update()
    {
        
    }
    
    func updateTime(timeLabel:UILabel)
    {
        timeLabel.text = shareModel.shareTimeOfDate.toFriendlyString(UIShareCell.dateFomatter)
    }
    
    func updateUserNoteName(noteLable:UILabel)
    {
        noteLable.text = postUser?.getNoteName() ?? "Sharelinker"
    }
    
    func updateAvatar(avatarImageView:UIImageView)
    {
        rootController.fileService.setAvatar(avatarImageView, iconFileId: postUser?.avatarId ?? shareModel.avatarId)
    }
    
    func tapCell(_:UITapGestureRecognizer)
    {
        
    }
}