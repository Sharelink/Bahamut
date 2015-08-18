//
//  ShareThing.swift
//  Bahamut
//
//  Created by AlexChow on 15/7/28.
//  Copyright (c) 2015年 GStudio. All rights reserved.
//

import UIKit

class UIShareThing: UITableViewCell
{

    struct Constants
    {
        static let VotePrefixEmoji = "👍"
        static let SharePrefixEmoji = "🔗"

    }
    
    var rootController:UIViewController!
    
    var shareThingModel:ShareThing!
    {
        didSet
        {
            update()
        }
    }
    
    override init(style: UITableViewCellStyle, reuseIdentifier: String?) {
        super.init(style: style, reuseIdentifier: reuseIdentifier)
        
    }

    required init!(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
        
    }
    
    @IBOutlet weak var headIconImageView: UIImageView!{
        didSet{
            headIconImageView.userInteractionEnabled = true
            headIconImageView.addGestureRecognizer(UITapGestureRecognizer(target: self, action: "showHeadIcon:"))
        }
    }
    @IBOutlet weak var userNicknameLabel: UILabel!{
        didSet{
            userNicknameLabel.userInteractionEnabled = true
            
            userNicknameLabel.addGestureRecognizer(UITapGestureRecognizer(target: self, action: "showUserProfile:"))
        }
    }
    @IBOutlet weak var shareDateTime: UILabel!
    @IBOutlet weak var shareContent: UIShareContent!{
        didSet{
            var gesture = UISwipeGestureRecognizer(target: self, action: "swipeShareThingLeft:")
            gesture.direction = UISwipeGestureRecognizerDirection.Left
            self.addGestureRecognizer(gesture)
            gesture = UISwipeGestureRecognizer(target: self, action: "swipeShareThingRight:")
            gesture.direction = UISwipeGestureRecognizerDirection.Right
            self.addGestureRecognizer(gesture)
        }
    }
    @IBOutlet weak var userReShareDetail: UILabel!
    @IBOutlet weak var userVoteDetail: UILabel!
    @IBOutlet weak var replyButton: UIButton!
    @IBOutlet weak var shareDesc: UILabel!
    
    func swipeShareThingRight(gesture:UISwipeGestureRecognizer)
    {
        print("swipe right")
    }
    
    func swipeShareThingLeft(gesture:UISwipeGestureRecognizer)
    {
        print("swipe left")
    }
    
    @IBAction func vote()
    {
        ServiceContainer.getService(ShareService).voteShareThing(shareThingModel,updateCallback: update)
    }
    
    @IBAction func shareToFriends()
    {
        ServiceContainer.getService(ShareService).showReshareViewController(self.rootController.navigationController!, reShareModel: shareThingModel)
    }
    
    @IBAction func reply()
    {
        print("reply")
    }
    
    func showUserProfile(_:UIGestureRecognizer)
    {
        ServiceContainer.getService(UserService).showUserProfileViewController(self.rootController.navigationController!, userId: self.shareThingModel.userId)
    }

    func update()
    {
        replyButton.titleLabel?.text = "\(shareThingModel.notReadReply)"
        userNicknameLabel.text = shareThingModel.userNick
        shareDesc.text = shareThingModel.title
        shareDateTime.text = shareThingModel.postDateString
        userVoteDetail.text = shareThingModel.userVotesDetail.isEmpty ? "" : Constants.VotePrefixEmoji + shareThingModel.userVotesDetail
        userReShareDetail.text = shareThingModel.userReShareDetail.isEmpty ? "" : Constants.SharePrefixEmoji + shareThingModel.userReShareDetail
        shareContent.model = shareThingModel.content
        ServiceContainer.getService(FileService).getFile(shareThingModel.headIconImageId, returnCallback: { (filePath) -> Void in
            self.headIconImageView.image = PersistentManager.sharedInstance.getImage(self.shareThingModel.headIconImageId, filePath: filePath)
        })
    }
    
    func showHeadIcon(_:UIGestureRecognizer)
    {
        print("showHeadIcon")
    }
    
}

/// 添加UI需要的属性
extension ShareThing
{
    
    var notReadReply:UInt32{
        return ServiceContainer.getService(ReplyService).getShareIdNotReadMessageCount(self.shareId)
    }
    
    var reShareThings:[ShareThing]{
        return ServiceContainer.getService(ShareService).getReShareThingsOfShareThing(self)
    }
    
    var userVotesDetail:String{
        let voteUsers = ServiceContainer.getService(UserService).getUsers(self.voteUserIds)
        let names = voteUsers.map{user->String in
            return user.nickName
        }
        return ",".join(names)
    }
    
    var userReShareDetail:String{
        let reshareUsers = ServiceContainer.getService(UserService).getUsers(self.reShareUserIds)
        let names = reshareUsers.map{user->String in
            return user.nickName
        }
        return ",".join(names)
    }
    
    var replyButtonContent:String{
        let messageCount = ServiceContainer.getService(ReplyService).getShareIdNotReadMessageCount(self.shareId)
        return "\(Int(messageCount))"
    }
    
    var postDateString:String{
        if shareTimeOfDate.timeIntervalSinceNow < 60
        {
            return "newly"
        }
        else if shareTimeOfDate.timeIntervalSinceNow < 3600
        {
            return "\(Int(shareTimeOfDate.timeIntervalSinceNow/60)) minutes ago"
        }else if shareTimeOfDate.timeIntervalSinceNow < 3600 * 24
        {
            return "\(Int(shareTimeOfDate.timeIntervalSinceNow/3600)) hours ago"
        }else if shareTimeOfDate.timeIntervalSinceNow < 3600 * 24 * 7
        {
            return "\(Int(shareTimeOfDate.timeIntervalSinceNow/3600/24)) days ago"
        }else
        {
            return DateHelper.dateToString(self.shareTimeOfDate)
        }
    }
    
}

