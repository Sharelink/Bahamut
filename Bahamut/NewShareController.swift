//
//  NewShareController.swift
//  Bahamut
//
//  Created by AlexChow on 15/11/18.
//  Copyright © 2015年 GStudio. All rights reserved.
//

import Foundation
import UIKit

//MARK: ShareService extension
extension ShareService
{
    func showReshareController(currentNavigationController:UINavigationController,reShareModel:ShareThing)
    {
        let controller = NewShareController.instanceFromStoryBoard()
        controller.isReshare = true
        controller.shareModel = ShareThing()
        controller.shareModel.pShareId = reShareModel.shareId
        controller.shareModel.shareId = reShareModel.shareId
        controller.shareModel.shareContent = reShareModel.shareContent
        controller.shareModel.shareType = reShareModel.shareType
        controller.shareModel.forTags = reShareModel.forTags
        controller.shareModel.message = reShareModel.message
        controller.hidesBottomBarWhenPushed = true
        currentNavigationController.pushViewController(controller, animated: true)
    }
}

//MARK: new share task entity

class NewShareTask : ShareLinkObject
{
    var id:String!
    var share:ShareThing!
    var shareTags:[SharelinkTag]!
    var sendFileKey:FileAccessInfo!
}

//MARK: NewShareCellBase
class NewShareCellBase : UITableViewCell
{
    var fileService:FileService!{
        return rootController.fileService
    }
    
    var shareService:ShareService!{
        return rootController.shareService
    }
    
    var userService:UserService!{
        return rootController.userService
    }
    
    var isReshare:Bool{
        return rootController.isReshare
    }
    var shareModel:ShareThing!{
        return rootController.shareModel
    }
    var rootView:UIView!{
        return rootController?.view
    }
    var rootController:NewShareController!
    func initCell()
    {
        
    }
    
    func clear()
    {
        
    }
}

//MARK:NewShareController
class NewShareController: UITableViewController,ProgressTaskDelegate
{
    var fileService:FileService!
    var shareService:ShareService!
    var userService:UserService!
    
    var isReshare:Bool = false
    var shareModel:ShareThing! = {
        let st = ShareThing()
        st.shareType = ShareThingType.shareFilm.rawValue
        return st
    }()
    
    private var userGuide:UserGuide!

    var shareMessageCell:NewShareMessageCell!
    var shareContentCell:NewShareFilmCell!
    var shareThemeCell:NewShareThemeCell!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        self.initUserGuide()
        self.shareService = ServiceContainer.getService(ShareService)
        self.fileService = ServiceContainer.getService(FileService)
        self.userService = ServiceContainer.getService(UserService)
        self.changeNavigationBarColor()
        self.tableView.dataSource = self
    }
    
    override func viewWillAppear(animated: Bool) {
        super.viewWillAppear(animated)
        if let nc = self.navigationController as? UIOrientationsNavigationController
        {
            nc.lockOrientationPortrait = true
        }
        MobClick.beginLogPageView("New")
    }
    
    override func viewWillDisappear(animated: Bool) {
        super.viewWillDisappear(animated)
        if let nc = self.navigationController as? UIOrientationsNavigationController
        {
            nc.lockOrientationPortrait = false
        }
        MobClick.endLogPageView("New")
    }
    
    override func viewDidAppear(animated: Bool) {
        super.viewDidAppear(animated)
        self.userGuide.showGuideControllerPresentFirstTime()
    }
    
    //Init
    private func initUserGuide()
    {
        self.userGuide = UserGuide()
        let guideImgs = UserGuideAssetsConstants.getViewGuideImages(BahamutSetting.lang, viewName: "New")
        self.userGuide.initGuide(self, userId: BahamutSetting.userId, guideImgs: guideImgs)
    }

    func resetShare(type:String)
    {
        shareModel.shareType = type
        shareModel.message = ""
        shareModel.shareContent = ""
    }
    
    //MARK: post new share
    
    func clear()
    {
        shareModel.message = ""
        shareModel.shareContent = ""
        shareMessageCell.clear()
        shareThemeCell.clear()
        shareContentCell.clear()
    }
    
    @IBAction func share()
    {
        if self.shareThemeCell.selectedThemeController.tags == nil || self.shareThemeCell.selectedThemeController.tags.count == 0
        {
            let alert = UIAlertController(title: NSLocalizedString("SHARE", comment:  ""), message: NSLocalizedString("NO_SELECT_TAG_TIPS", comment:  ""),preferredStyle: UIAlertControllerStyle.Alert)
            alert.addAction(UIAlertAction(title: NSLocalizedString("CONTINUE", comment:  ""), style: UIAlertActionStyle.Default, handler: { (ac) -> Void in
                self.isReshare ? self.reshare() : self.prepareShare()
            }))
            alert.addAction(UIAlertAction(title: NSLocalizedString("CANCEL", comment:  ""), style: UIAlertActionStyle.Cancel, handler: nil))
            self.presentViewController(alert, animated: true, completion: nil )
        }else
        {
            self.isReshare ? self.reshare() : self.prepareShare()
        }
        MobClick.event("PostNew")
    }
    
    private func reshare()
    {
        let tags = self.shareThemeCell.selectedThemeController.tags ?? [SharelinkTag]()
        self.makeToastActivityWithMessage("",message: NSLocalizedString("SHARING", comment: "Sharing"))
        self.shareService.reshare(self.shareModel.shareId, message: self.shareMessageCell.shareMessageTextView.text, tags: tags){ isSuc,msg in
            self.hideToastActivity()
            var alert:UIAlertController!
            if isSuc{
                alert = UIAlertController(title: NSLocalizedString("SHARE_SUCCESSED", comment: "Share Successed"), message: nil, preferredStyle: .Alert)
                alert.addAction(UIAlertAction(title: NSLocalizedString("I_SEE", comment: ""), style: .Cancel, handler: { (action) -> Void in
                    self.navigationController?.popViewControllerAnimated(true)
                }))
            }else
            {
                alert = UIAlertController(title: NSLocalizedString("SHARE_FAILED", comment: "Share Failed"), message: msg, preferredStyle: .Alert)
                alert.addAction(UIAlertAction(title: NSLocalizedString("I_SEE", comment: ""), style: .Cancel, handler: { (action) -> Void in
                    
                }))
            }
            self.showAlert(alert)
        }
    }
    
    private func prepareShare()
    {
        if let shareContent = shareModel.shareContent
        {
            let newShare = ShareThing()
            newShare.message = self.shareMessageCell.shareMessageTextView.text
            newShare.shareType = ShareThingType.shareFilm.rawValue
            newShare.shareContent = shareContent
            let me = userService.myUserModel
            newShare.userId = me.userId
            newShare.userNick = me.nickName
            newShare.avatarId = me.avatarId
            newShare.shareTime = NSDate().toDateTimeString()
            newShare.reshareable = "true"
            clear()
            
            self.makeToastActivityWithMessage("",message: NSLocalizedString("SENDING_FILM", comment: "Sending Film"))
            
            dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0)){
                let tags = self.shareThemeCell.selectedThemeController.tags ?? [SharelinkTag]()
                self.postShare(newShare,tags:tags)
            }
            
        }else
        {
            self.showToast(NSLocalizedString("NO_FILM_SELECTED", comment: "must select or capture a film!"))
        }
    }
    
    private func postShare(newShare:ShareThing,tags:[SharelinkTag])
    {
        let filmModel = FilmModel(json: newShare.shareContent)
        self.fileService.sendBahamutFire(filmModel.film, type: FileType.Video) { (taskId, fileKey) -> Void in
            self.hideToastActivity()
            ProgressTaskWatcher.sharedInstance.addTaskObserver(taskId, delegate: self)
            if let fk = fileKey
            {
                filmModel.film = fk.fileId
                newShare.shareContent = filmModel.toJsonString()
                let newShareTask = NewShareTask()
                newShareTask.id = taskId
                newShareTask.shareTags = tags
                newShareTask.share = newShare
                newShareTask.sendFileKey = fk
                newShareTask.saveModel()
            }
        }
    }
    
    func taskCompleted(taskIdentifier: String, result: AnyObject!) {
        if let task = PersistentManager.sharedInstance.getModel(NewShareTask.self, idValue: taskIdentifier)
        {
            self.shareService.postNewShare(task.share, tags: task.shareTags ,callback: { (shareId) -> Void in
                if shareId != nil
                {
                    self.shareService.postNewShareFinish(shareId, isCompleted: true){ (isSuc) -> Void in
                        if isSuc
                        {
                            self.showToast(NSLocalizedString("POST_SHARE_SUC", comment: "Post Share Success"))
                            NewShareTask.deleteObjectArray([task])
                        }else
                        {
                            self.showToast(NSLocalizedString("POST_SHARE_FAILED", comment: "Post Share Error"))
                        }
                    }
                }else
                {
                    self.showToast(NSLocalizedString("POST_SHARE_FAILED", comment: "Post Share Error"))
                }
            })
        }
    }
    
    func taskFailed(taskIdentifier: String, result: AnyObject!) {
        if let task = PersistentManager.sharedInstance.getModel(NewShareTask.self, idValue: taskIdentifier)
        {
            self.showToast( NSLocalizedString("SEND_FILM_FAILED", comment: "Send File Failed"))
            NewShareTask.deleteObjectArray([task])
        }
    }
    
    //MARK: table view delegate
    override func numberOfSectionsInTableView(tableView: UITableView) -> Int {
        return 1
    }
    
    override func tableView(tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return 3
    }
    
    override func tableView(tableView: UITableView, heightForRowAtIndexPath indexPath: NSIndexPath) -> CGFloat {
        let rowHights = [98,211,168]
        return CGFloat(rowHights[indexPath.row])
    }
    
    override func tableView(tableView: UITableView, cellForRowAtIndexPath indexPath: NSIndexPath) -> UITableViewCell {
        var cell:NewShareCellBase!
        if indexPath.row == 0
        {
            self.shareMessageCell = tableView.dequeueReusableCellWithIdentifier(NewShareMessageCell.reuseableId,forIndexPath: indexPath) as! NewShareMessageCell
            cell = self.shareMessageCell
        }else if indexPath.row == 1
        {
            self.shareContentCell = tableView.dequeueReusableCellWithIdentifier(NewShareFilmCell.reuseableId,forIndexPath: indexPath) as! NewShareFilmCell
            cell = self.shareContentCell
        }else
        {
            self.shareThemeCell = tableView.dequeueReusableCellWithIdentifier(NewShareThemeCell.reuseableId,forIndexPath: indexPath) as! NewShareThemeCell
            cell = self.shareThemeCell
        }
        cell.rootController = self
        cell.initCell()
        return cell
    }
    
    //MARK: instance from storyboard
    static func instanceFromStoryBoard() -> NewShareController
    {
        return instanceFromStoryBoard("Main", identifier: "NewShareController") as! NewShareController
    }
}