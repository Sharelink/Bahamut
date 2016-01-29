//
//  ShareThing.swift
//  Bahamut
//
//  Created by AlexChow on 15/7/28.
//  Copyright (c) 2015年 GStudio. All rights reserved.
//

import UIKit

class UIShareThing: UIShareCell
{
    static let ShareThingCellIdentifier = "ShareThing"
    struct Constants
    {
        static let VotePrefixEmoji = "💙"

    }

    override var shareModel:ShareThing!
    {
        didSet
        {
            if shareModel == nil
            {
                return
            }
            postUser = rootController.userService.getUser(shareModel.userId)
            shareContent.delegate = UIShareContentTypeDelegateGenerator.getDelegate(shareModel.shareType)
            shareContent.delegate.initContent(self, share: shareModel)
            shareContent.share = shareModel
        }
    }
    
    override init(style: UITableViewCellStyle, reuseIdentifier: String?) {
        super.init(style: style, reuseIdentifier: reuseIdentifier)
        
    }

    required init!(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
        
    }
    
    deinit
    {
    }
    @IBOutlet weak var sendingIndicator: UIActivityIndicatorView!{
        didSet{
            sendingIndicator.stopAnimating()
            sendingIndicator.hidden = true
        }
    }
    
    @IBOutlet weak var themeLabel: UILabel!
    @IBOutlet weak var avatarImageView: UIImageView!{
        didSet{
            avatarImageView.layer.cornerRadius = 7
            avatarImageView.userInteractionEnabled = true
            avatarImageView.addGestureRecognizer(UITapGestureRecognizer(target: self, action: "showAvatar:"))
        }
    }
    @IBOutlet weak var userNicknameLabel: UILabel!{
        didSet{
            userNicknameLabel.userInteractionEnabled = true
            userNicknameLabel.addGestureRecognizer(UITapGestureRecognizer(target: self, action: "showUserProfile:"))
        }
    }
    @IBOutlet weak var shareButton: UIButton!{
        didSet{
            shareButton.tintColor = UIColor.themeColor
        }
    }
    @IBOutlet weak var shareDateTime: UILabel!
    @IBOutlet weak var contentWidth: NSLayoutConstraint!{
        didSet{
        }
    }
    @IBOutlet weak var contentHeight: NSLayoutConstraint!{
        didSet{
        }
    }
    @IBOutlet weak var shareContent: UIShareContent!{
        didSet{
            shareContent.backgroundColor = UIColor.whiteColor()
            shareContent.shareCell = self
        }
    }
    
    @IBOutlet weak var userVoteDetail: UILabel!{
        didSet{
            userVoteDetail.textColor = UIColor.themeColor
        }
    }
    @IBOutlet weak var replyButton: UIButton!{
        didSet{
            replyButton.tintColor = UIColor.themeColor
        }
    }
    @IBOutlet weak var shareDesc: UILabel!
    
    private static var voteOriginColor:UIColor!
    private static var voteButtonVotedColor:UIColor!
    @IBOutlet weak var voteButton: UIButton!{
        didSet{
            if UIShareThing.voteOriginColor == nil{
                UIShareThing.voteOriginColor = voteButton.tintColor
                UIShareThing.voteButtonVotedColor = UIColor.themeColor
            }
        }
    }
    
    @IBAction func vote(sender: AnyObject)
    {
        if let btn = sender as? UIButton
        {
            btn.animationMaxToMin(0.1,maxScale: 1.3){
                if self.voted
                {
                    let alert = UIAlertController(title: "UNVOTE_SHARE_CONFIRM".localizedString(), message: nil, preferredStyle: UIAlertControllerStyle.Alert)
                    alert.addAction(UIAlertAction(title: "YES".localizedString(), style: UIAlertActionStyle.Default){ aa in
                        ServiceContainer.getService(ShareService).unVoteShareThing(self.shareModel,updateCallback: self.updateVote)
                        })
                    alert.addAction(UIAlertAction(title: "CANCEL".localizedString(), style: UIAlertActionStyle.Cancel){ _ in })
                    self.rootController.presentViewController(alert, animated: true, completion: nil)
                }else{
                    
                    ServiceContainer.getService(ShareService).voteShareThing(self.shareModel,updateCallback: self.updateVote)
                    MobClick.event("Vote")
                }
            }
        }
        
    }
    
    @IBAction func shareToFriends(sender: AnyObject)
    {
        if let btn = sender as? UIButton
        {
            btn.animationMaxToMin(0.1,maxScale: 1.3){
                if self.shareModel.canReshare()
                {
                    MobClick.event("Reshare")
                    self.rootController.shareService.showReshareController(self.rootController.navigationController!, reShareModel: self.shareModel)
                }else
                {
                    let alert = UIAlertController(title: nil, message: "RESHARELESS_TIPS".localizedString(), preferredStyle: UIAlertControllerStyle.Alert)
                    alert.addAction(UIAlertAction(title: "I_SEE".localizedString(), style: UIAlertActionStyle.Cancel ,handler:nil))
                    self.rootController.presentViewController(alert, animated: true, completion: nil)
                }
            }
        }
    }
    
    @IBAction func reply(sender: AnyObject)
    {
        if let btn = sender as? UIButton
        {
            btn.animationMaxToMin(0.1,maxScale: 1.3){
                let shareChat = self.rootController.messageService.getShareChatHub(self.shareModel.shareId,shareSenderId: self.shareModel.userId)
                MainViewTabBarController.currentTabBarViewController.reduceTabItemBadge(MainViewTabBarController.ShareTabItemBadgeIndex, badgeReduce: self.notReadmsg)
                self.notReadmsg = 0
                ChatViewController.startChat(self.rootController, chatHub: shareChat, callback: { () -> Void in
                    self.replyButton.badgeValue = nil
                })
            }
        }
        
    }
    
    @IBAction func showMoreOperate(sender: AnyObject)
    {
        let alerts = [
            UIAlertAction(title: "HARMFUL_CONTENT".localizedString(), style: .Default, handler: { (action) -> Void in
                self.showHarmfulContentFeedback()
            }),
            UIAlertAction(title: "CANCEL".localizedString(), style: .Cancel, handler: { (action) -> Void in
                
            })
        ]
        let alertController = UIAlertController(title: nil, message: nil, preferredStyle: .ActionSheet)
        for al in alerts
        {
            alertController.addAction(al)
        }
        self.rootController.presentViewController(alertController, animated: true, completion: nil)
    }
    
    
    private func showHarmfulContentFeedback()
    {
        let reportController = HarmfulReportViewController.instanceFromStoryBoard()
        let navController = UINavigationController(rootViewController: reportController)
        self.rootController.presentViewController(navController, animated: true){
            reportController.reporterIdLabel.text = UserSetting.lastLoginAccountId
            let str = self.shareModel.shareId as NSString
            reportController.reportTypeLabel.text = "Harmful Share"
            reportController.reportContentTextView.text = "Share Code:\n\(str.base64String())\n"
        }
    }
    
    func showUserProfile(_:UIGestureRecognizer)
    {
        rootController.userService.showUserProfileViewController(self.rootController.navigationController!, userId: self.shareModel.userId)
    }

    override func layoutSubviews() {
        updateBadge()
        super.layoutSubviews()
    }
    
    override func update()
    {
        shareDesc.text = shareModel.message
        self.backgroundColor = UIColor.clearColor()
        updateBadge()
        updateVote()
        updateSending()
        updateTheme()
        updateAvatar(self.avatarImageView)
        updateUserNoteName(self.userNicknameLabel)
        updateTime(self.shareDateTime)
        updateContent()
    }
    
    private func updateTheme()
    {
        if let firstTheme = shareModel?.forTags?.first
        {
            let stm = SendTagModel(json: firstTheme)
            let theme = SharelinkTheme()
            theme.tagName = stm.name
            theme.type = stm.type
            theme.data = stm.data
            let themeName = theme.getShowName(false)
            themeLabel.text = themeName
        }else
        {
            themeLabel.text = "Sharelink"
        }
    }
    
    private func updateSending()
    {
        if rootController.shareService.sendingShareId.keys.contains(self.shareModel.shareId)
        {
            self.sendingIndicator.hidden = false
            self.sendingIndicator.startAnimating()
        }else
        {
            self.sendingIndicator.hidden = true
            self.sendingIndicator.stopAnimating()
        }
    }
    
    var notReadmsg = 0
    private func updateBadge()
    {
        notReadmsg = rootController.messageService.getShareNewMessageCount(shareModel.shareId)
        replyButton.badgeValue = "\(notReadmsg)"
    }
    
    var voted:Bool
    {
        let myUserId = rootController.userService.myUserId
        if shareModel.voteUsers == nil
        {
            return false
        }
        return self.shareModel.voteUsers.contains{$0 == myUserId}
    }
    
    private func updateVote()
    {
        voteButton.tintColor = voted ?  UIShareThing.voteButtonVotedColor : UIShareThing.voteOriginColor
        var voteString = ""
        if let users = shareModel.voteUsers
        { 
            let userNicks = users.map{rootController.userService.getUserNoteName($0)}.filter{String.isNullOrWhiteSpace($0) == false }
            voteString =  userNicks.joinWithSeparator(",")
        }
        if String.isNullOrWhiteSpace(voteString)
        {
            userVoteDetail.hidden = true
        }else
        {
            userVoteDetail.hidden = false
            userVoteDetail.text = "\(Constants.VotePrefixEmoji)\(voteString)"
        }
    }
    
    func updateContent()
    {
        self.shareContent.update()
        self.updateContantFrame()
    }
    
    private func updateContantFrame()
    {
        if contentHeight != nil && contentWidth != nil && self.shareContent != nil && self.shareContent.delegate != nil{
            let contentFrame = self.shareContent.delegate.getContentFrame(self, share: self.shareModel)
            contentHeight.constant = contentFrame.height
            contentWidth.constant = contentFrame.width
        }
    }
    
    func showAvatar(_:UIGestureRecognizer)
    {
        UUImageAvatarBrowser.showImage(avatarImageView)
    }
    
}
