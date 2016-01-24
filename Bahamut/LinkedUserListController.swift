//
//  LinkedUserListController.swift
//  Bahamut
//
//  Created by AlexChow on 15/8/8.
//  Copyright (c) 2015年 GStudio. All rights reserved.
//

import UIKit


//MARK: LinkedUserListController
class LinkedUserListController: UITableViewController
{

    var userListModel:[(latinLetter:String , items:[Sharelinker])] = [(latinLetter:String , items:[Sharelinker])](){
        didSet{
            self.tableView.reloadData()
        }
    }
    
    var linkMessageModel:[LinkMessage] = [LinkMessage]()
    
    private(set) var userService:UserService!{
        didSet{
            userService.addObserver(self, selector: "myLinkedUsersUpdated:", name: UserService.userListUpdated, object: nil)
            userService.addObserver(self, selector: "linkMessageUpdated:", name: UserService.linkMessageUpdated, object: nil)
            userService.addObserver(self, selector: "myLinkedUsersUpdated:", name: UserService.myUserInfoRefreshed, object: nil)
        }
    }
    
    private var userGuide:UserGuide!
    private var isShowing:Bool = false
    
    private(set) var notificationService:NotificationService!
    
    private func initUserGuide()
    {
        self.userGuide = UserGuide()
        let guideImgs = UserGuideAssetsConstants.getViewGuideImages(SharelinkSetting.lang, viewName: "User")
        self.userGuide.initGuide(self, userId: UserSetting.userId, guideImgs: guideImgs)
    }
    
    //MARK: notify
    func myLinkedUsersUpdated(sender:AnyObject)
    {
        dispatch_async(dispatch_get_main_queue()){()->Void in
            let newValues = self.userService.myLinkedUsers
            let dict = self.userService.getUsersDivideWithLatinLetter(newValues)
            self.userListModel = dict
        }
        
    }
    
    func linkMessageUpdated(sender:AnyObject)
    {
        dispatch_async(dispatch_get_main_queue()){()->Void in
            self.linkMessageModel = self.userService.linkMessageList
            self.tableView.reloadData()
        }
        
    }
    
    func refresh()
    {
        userService.refreshMyLinkedUsers()
        userService.refreshLinkMessage()
        myLinkedUsersUpdated(userService)
    }
    
    deinit
    {
        if userService != nil
        {
            userService.removeObserver(self)
        }
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        changeNavigationBarColor()
        self.initUserGuide()
        tableView.estimatedRowHeight = tableView.rowHeight
        tableView.rowHeight = UITableViewAutomaticDimension
        let uiview = UIView()
        uiview.backgroundColor = UIColor.clearColor()
        tableView.tableFooterView = uiview
        self.userService = ServiceContainer.getService(UserService)
        self.notificationService = ServiceContainer.getService(NotificationService)
        refresh()
    }
    
    override func viewWillAppear(animated: Bool) {
        super.viewWillAppear(animated)
        isShowing = true
        if let nc = self.navigationController as? UIOrientationsNavigationController
        {
            nc.lockOrientationPortrait = false
        }
        MobClick.beginLogPageView("SharelinkerList")
    }
    
    override func viewWillDisappear(animated: Bool) {
        super.viewWillDisappear(animated)
        isShowing = false
        MobClick.endLogPageView("SharelinkerList")
    }
    
    override func viewDidAppear(animated: Bool) {
        super.viewDidAppear(animated)
        if UserSetting.isAppstoreReviewing == false
        {
            userGuide.showGuideControllerPresentFirstTime()
        }
        tableView.reloadData()
    }
    
    //MARK: new linker
    
    @IBAction func addNewLink(sender: AnyObject)
    {
        let userService = ServiceContainer.getService(UserService)
        let user = userService.myUserModel
        let userHeadIconPath = PersistentManager.sharedInstance.getImageFilePath(user.avatarId)
        let contentMsg = String(format: NSLocalizedString("ASK_LINK_MSG", comment: "%@ want to link with you in Sharelink!"),user.nickName)
        let title = "Sharelink"
        
        let linkMeCmd = userService.generateSharelinkLinkMeCmd()
        let url = "\(SharelinkConfig.bahamutConfig.sharelinkOuterExecutorUrlPrefix)\(linkMeCmd)"
        
        let contentWithUrl = "\(contentMsg)\n\(url)"
        
        var img:ISSCAttachment!
        if let qrImage = QRCode.generateImage(url, avatarImage: nil)
        {
            let imgData = UIImageJPEGRepresentation(qrImage, 1.0)
            img = ShareSDK.imageWithData(imgData, fileName: nil, mimeType: nil)
        }
        if img == nil
        {
            img = ShareSDK.imageWithPath(userHeadIconPath ?? ImageAssetsConstants.defaultAvatarPath)
        }
        let publishContent = ShareSDK.content(contentWithUrl, defaultContent: nil, image: img, title: title, url: url, description: nil, mediaType: SSPublishContentMediaTypeImage)
        
        publishContent.addWeixinSessionUnitWithType(5, content: contentMsg, title: title, url: url, thumbImage: nil, image: img, musicFileUrl: nil, extInfo: nil, fileData: nil, emoticonData: nil)
        
        publishContent.addWeixinTimelineUnitWithType(5, content: contentMsg, title: title, url: url, thumbImage: nil, image: img, musicFileUrl: nil, extInfo: nil, fileData: nil, emoticonData: nil)
        
        publishContent.addQQUnitWithType(3, content: contentMsg, title: title, url: url, image: img)
        
        publishContent.addSMSUnitWithContent(contentWithUrl)
        
        publishContent.addFacebookWithContent(contentWithUrl, image: img)
        
        publishContent.addMailUnitWithSubject(title, content: contentWithUrl, isHTML: false, attachments: nil, to: nil, cc: nil, bcc: nil)
        
        publishContent.addWhatsAppUnitWithContent(contentWithUrl, image: img, music: nil, video: nil)
        
        let container = ShareSDK.container()
        container.setIPadContainerWithView(self.view, arrowDirect: .Down)
        container.setIPhoneContainerWithViewController(self)
        ShareSDK.showShareActionSheet(container, shareList: nil, content: publishContent, statusBarTips: true, authOptions: nil, shareOptions: nil) { (type, state, statusInfo, error, end) -> Void in
            if (state == SSResponseStateSuccess)
            {
                self.showToast( NSLocalizedString("SHARE_SUC", comment: "Share Success!"))
            }
            else if (state == SSResponseStateFail)
            {
                self.showToast( NSLocalizedString("SHARE_FAILED", comment: "Share Failed."))
                NSLog("share fail:%ld,description:%@", error.errorCode(), error.errorDescription());
            }
        }
    }
    
    @IBAction func showMyQRCode(sender: AnyObject)
    {
        let alert = UIAlertController(title: NSLocalizedString("QRCODE", comment: "QRCode"), message: nil, preferredStyle: .ActionSheet)
        alert.addAction(UIAlertAction(title: NSLocalizedString("SCAN_QRCODE", comment: "Scan QRCode"), style: .Destructive) { _ in
            self.userService.showScanQRViewController(self.navigationController!)
            })
        alert.addAction(UIAlertAction(title:NSLocalizedString("MY_QRCODE", comment: "My QRCode"), style: .Destructive) { _ in
            self.userService.showMyQRViewController(self.navigationController!,sharelinkUserId: self.userService.myUserId ,avataImage: nil)
            })
        alert.addAction(UIAlertAction(title: NSLocalizedString("CANCEL", comment: ""), style: .Cancel){ _ in})
        presentViewController(alert, animated: true, completion: nil)
        
    }
    
    //MARK: actions
    func scrollTableViewToTop()
    {
        if userListModel.count > 0 || linkMessageModel.count > 0
        {
            self.tableView.scrollToRowAtIndexPath(NSIndexPath(forRow: 0, inSection: 0), atScrollPosition: .Top, animated: true)
        }
    }
    
    //MARK: table view delegate
    
    var indexOfUserList:Int{
        return linkMessageModel.count > 0 ? 1 : 0
    }
    
    override func numberOfSectionsInTableView(tableView: UITableView) -> Int
    {
        //asking list,talking list + userlist.count
        return indexOfUserList + userListModel.count
    }
    
    override func tableView(tableView: UITableView, numberOfRowsInSection section: Int) -> Int
    {
        if section == 0 && linkMessageModel.count > 0
        {
            return linkMessageModel.count
        }else
        {
            return userListModel[section - indexOfUserList].items.count
        }
        
    }
    
    override func tableView(tableView: UITableView, viewForHeaderInSection section: Int) -> UIView? {
        let headerView = UIView(frame: CGRectMake(0, 0, 23, 23))
        headerView.backgroundColor = UIColor.headerColor
        let label = UILabel(frame: CGRectMake(7, 0, 23, 23))
        headerView.addSubview(label)
        
        if section == 0 && linkMessageModel.count > 0
        {
            label.text = NSLocalizedString("LINK_MESSAGE", comment: "")
        }else
        {
            label.text = userListModel[section - indexOfUserList].latinLetter
        }
        label.sizeToFit()
        return headerView
    }
    
    override func tableView(tableView: UITableView, cellForRowAtIndexPath indexPath: NSIndexPath) -> UITableViewCell
    {
        if indexPath.section == 0 && linkMessageModel.count > 0
        {
            let model = linkMessageModel[indexPath.row]
            if model.type == LinkMessageType.AskLink.rawValue
            {
                let cell = tableView.dequeueReusableCellWithIdentifier(UIUserListAskingLinkCell.cellIdentifier, forIndexPath: indexPath) as! UIUserListAskingLinkCell
                cell.model = model
                cell.rootController = self
                return cell
            }else
            {
                let cell = tableView.dequeueReusableCellWithIdentifier(UIUserListMessageCell.cellIdentifier, forIndexPath: indexPath) as! UIUserListMessageCell
                cell.model = model
                cell.rootController = self
                return cell
            }
        }else
        {
            let cell = tableView.dequeueReusableCellWithIdentifier(UIUserListCell.cellIdentifier, forIndexPath: indexPath)
            let userModel = userListModel[indexPath.section - indexOfUserList].items[indexPath.row] as Sharelinker
            
            if let userCell = cell as? UIUserListCell
            {
                userCell.userModel = userModel
                userCell.rootController = self
            }
            return cell
        }
    }
    
    override func tableView(tableView: UITableView, canEditRowAtIndexPath indexPath: NSIndexPath) -> Bool {
        if indexPath.section == 0 && linkMessageModel.count > 0
        {
            return true
        }else
        {
            return false
        }
    }
    
    override func tableView(tableView: UITableView, editActionsForRowAtIndexPath indexPath: NSIndexPath) -> [UITableViewRowAction]? {
        if indexPath.section == 0 && linkMessageModel.count > 0
        {
            let model = linkMessageModel[indexPath.row]
            var actionTitle = NSLocalizedString("I_SEE", comment: "")
            if model.type == LinkMessageType.AskLink.rawValue
            {
                actionTitle = NSLocalizedString("IGNORE", comment: "Ignore")
            }
            let action = UITableViewRowAction(style: .Default, title: actionTitle, handler: { (ac, indexPath) -> Void in
                self.userService.deleteLinkMessage(model.id)
            })
            return [action]
        }else
        {
            return nil
        }
    }
}