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
            headIconImageView.layer.cornerRadius = 3
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
            shareContent.mediaPlayer.fileFetcher = ServiceContainer.getService(FileService).getFileFetcher(FileType.Video)
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
        let alert = UIAlertController(title: "Share To Your Linkers", message: nil, preferredStyle: UIAlertControllerStyle.Alert)
        alert.addAction(UIAlertAction(title: "Share", style: UIAlertActionStyle.Default){ aa in
            let textField = alert.textFields?.first
            self.reshare(textField?.text ?? nil)
        })
        alert.addAction(UIAlertAction(title: "Cancel", style: UIAlertActionStyle.Cancel){ _ in self.cancelShare()})
        alert.addTextFieldWithConfigurationHandler { (textField) -> Void in
            textField.placeholder = "Say something to your linkers"
        }
    }
    
    private func cancelShare()
    {
        
    }
    
    private func reshare(message:String! = nil)
    {
        let shareService = ServiceContainer.getService(ShareService)
        shareService.reshare(self.shareThingModel.shareId, message: message)
    }
    
    @IBAction func reply()
    {
        print("reply")
    }
    
    func showUserProfile(_:UIGestureRecognizer)
    {
        let userTags = ServiceContainer.getService(SharelinkTagService).getAUsersTags(shareThingModel.userId)
        ServiceContainer.getService(UserService).showUserProfileViewController(self.rootController.navigationController!, userId: self.shareThingModel.userId,userTags: userTags)
    }

    func update()
    {
        replyButton.titleLabel?.text = "\(shareThingModel.notReadReply)"
        shareDesc.text = shareThingModel.title
        shareDateTime.text = shareThingModel.postDateString
        userVoteDetail.text = shareThingModel.userVotesDetail.isEmpty ? "" : Constants.VotePrefixEmoji + shareThingModel.userVotesDetail
        userReShareDetail.text = shareThingModel.userReShareDetail.isEmpty ? "" : Constants.SharePrefixEmoji + shareThingModel.userReShareDetail
        shareContent.model = shareThingModel.shareContent
        updateHeadIcon()
        updateUserNick()
    }
    
    private func updateUserNick()
    {
        if let nick = shareThingModel.userNick
        {
            userNicknameLabel.text = nick
        }else{
            userNicknameLabel.text = "I Am Sharelinker"
        }
    }
    
    private func updateHeadIcon()
    {
        let fileService = ServiceContainer.getService(FileService)
        fileService.setHeadIcon(self.headIconImageView, iconFileId: shareThingModel.headIconImageId)
    }
    
    func showHeadIcon(_:UIGestureRecognizer)
    {
        let imageFileFetcher = ServiceContainer.getService(FileService).getFileFetcher(FileType.Image)
        UIImagePlayerController.showImagePlayer(self.rootController, imageUrls: ["defaultView"],imageFileFetcher: imageFileFetcher)
    }
    
}

/// 添加UI需要的属性
extension ShareThing
{
    
    var notReadReply:UInt32{
        return ServiceContainer.getService(ReplyService).getShareIdNotReadMessageCount(self.shareId)
    }
    
    var userVotesDetail:String{
        if let users = self.voteUsers
        {
            let userIds = users.map{$0}
            let userNicks = ServiceContainer.getService(UserService).getUsers(userIds).map{$0.noteName!}
            return userNicks.joinWithSeparator(",")
        }
        return ""
    }
    
    var userReShareDetail:String{
        
        if let reshares = reShares
        {
            let userIds = reshares.map{$0.userId!}
            let userNicks = ServiceContainer.getService(UserService).getUsers(userIds).map{$0.noteName!}
            return userNicks.joinWithSeparator(",")
        }
        return ""
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

