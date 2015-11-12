//
//  MyDetailViewController.swift
//  Bahamut
//
//  Created by AlexChow on 15/9/18.
//  Copyright © 2015年 GStudio. All rights reserved.
//

import UIKit
import ChatFramework
import SharelinkSDK

extension UserService
{
    func showMyDetailView(currentNavigationController:UINavigationController)
    {
        if let myInfo = self.myUserModel
        {
            let controller = MyDetailViewController.instanceFromStoryBoard()
            controller.accountId = BahamutSetting.lastLoginAccountId
            controller.myInfo = myInfo
            currentNavigationController.pushViewController(controller, animated: true)
        }else
        {
            currentNavigationController.view.makeToast(message:NSLocalizedString("USER_DATA_NOT_READY_RETRY", comment: "User Data Not Ready,Retry Later"))
        }
    }
}

class MyDetailTextPropertyCell:UITableViewCell
{
    static let reuseIdentifier = "MyDetailTextPropertyCell"
    var info:(propertySet:UIEditTextPropertySet!,editable:Bool)!{
        didSet{
            if propertyNameLabel != nil
            {
                propertyNameLabel.text = info?.propertySet?.propertyLabel
            }
            
            if propertyValueLabel != nil
            {
                propertyValueLabel.text = info?.propertySet?.propertyValue
            }
            
            if editableMark != nil
            {
                editableMark.hidden = !info!.editable
            }
        }
    }
    @IBOutlet weak var propertyNameLabel: UILabel!{
        didSet{
            propertyNameLabel.text = info?.propertySet?.propertyLabel
        }
    }
    @IBOutlet weak var propertyValueLabel: UILabel!{
        didSet{
            propertyValueLabel.text = info?.propertySet?.propertyValue
        }
    }
    @IBOutlet weak var editableMark: UIImageView!{
        didSet{
            if let i = info
            {
                editableMark.hidden = !i.editable
            }
        }
    }
    
}

class MyDetailAvatarCell:UITableViewCell
{
    static let reuseIdentifier = "MyDetailAvatarCell"
    
    @IBOutlet weak var avatarImageView: UIImageView!{
        didSet{
            avatarImageView.layer.cornerRadius = 7
        }
    }
}

//MARK:MyDetailViewController
class MyDetailViewController: UIViewController,UITableViewDataSource,UIEditTextPropertyViewControllerDelegate,UITableViewDelegate,UIImagePickerControllerDelegate,UINavigationControllerDelegate,ProgressTaskDelegate
{
    static let aboutSharelinkReuseId = "aboutsharelink"
    struct InfoIds
    {
        static let nickName = "nickname"
        static let level = "level"
        static let levelScore = "levelScore"
        static let motto = "signtext"
        static let createTime = "createtime"
    }
    
    override func viewWillAppear(animated: Bool) {
        super.viewWillAppear(animated)
        MobClick.beginLogPageView("MyDetailView")
    }
    
    override func viewWillDisappear(animated: Bool) {
        super.viewWillDisappear(animated)
        MobClick.endLogPageView("MyDetailView")
    }
    
    var myInfo:Sharelinker!
    var accountId:String!
    
    private func initPropertySet()
    {
        var propertySet = UIEditTextPropertySet()
        propertySet.propertyIdentifier = InfoIds.nickName
        propertySet.propertyLabel = NSLocalizedString("NICK", comment: "Nick")
        propertySet.propertyValue = myInfo.nickName
        //propertySet.valueRegex = "^?{1,23}$"
        //propertySet.illegalValueMessage = NSLocalizedString("NICK_REGEX_TIPS", comment: "At least 1 character,less than 23 character")
        textPropertyCells.append((propertySet:propertySet,editable:true))
        
        propertySet = UIEditTextPropertySet()
        propertySet.propertyIdentifier = InfoIds.level
        propertySet.propertyLabel = NSLocalizedString("LEVEL", comment:"Level")
        propertySet.propertyValue = "Lv.\(myInfo.level ?? 1)"
        textPropertyCells.append((propertySet:propertySet,editable:false))
        
        propertySet = UIEditTextPropertySet()
        propertySet.propertyIdentifier = InfoIds.levelScore
        propertySet.propertyLabel = NSLocalizedString("SHARELINK_SCORE", comment:"Sharelink Score")
        propertySet.propertyValue = "\(myInfo.levelScore ?? 1)"
        textPropertyCells.append((propertySet:propertySet,editable:false))
        
        propertySet = UIEditTextPropertySet()
        propertySet.propertyIdentifier = InfoIds.createTime
        propertySet.propertyLabel = NSLocalizedString("JOIN", comment: "Join")
        propertySet.propertyValue = myInfo.createTimeOfDate.toDateString()
        textPropertyCells.append((propertySet:propertySet,editable:false))
        
        propertySet = UIEditTextPropertySet()
        propertySet.propertyIdentifier = "accountId"
        propertySet.propertyLabel = NSLocalizedString("ACCOUNT_ID", comment: "Sharelink ID")
        propertySet.propertyValue = accountId
        textPropertyCells.insert((propertySet:propertySet,editable:false), atIndex: 2)
        
        propertySet = UIEditTextPropertySet()
        propertySet.propertyIdentifier = InfoIds.motto
        propertySet.propertyLabel = NSLocalizedString("MOTTO", comment: "Motto")
        propertySet.propertyValue = myInfo.motto
        propertySet.isOneLineValue = false
        textPropertyCells.append((propertySet:propertySet,editable:true))
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        changeNavigationBarColor()
        initPropertySet()
        tableView.estimatedRowHeight = tableView.rowHeight
        tableView.rowHeight = UITableViewAutomaticDimension
        let uiview = UIView()
        uiview.backgroundColor = UIColor.footerColor
        tableView.tableFooterView = uiview
    }
    
    @IBAction func logout(sender: AnyObject)
    {
        let alert = UIAlertController(title: NSLocalizedString("LOGOUT_CONFIRM_TITLE", comment: "Sure To Logout Sharelink?"),
            message: NSLocalizedString("USER_DATA_WILL_SAVED", comment:""), preferredStyle: .Alert)
        alert.addAction(UIAlertAction(title: NSLocalizedString("YES", comment: ""), style: .Default) { _ in
            self.logout()
            })
        alert.addAction(UIAlertAction(title: NSLocalizedString("NO", comment: ""), style: .Cancel) { _ in
            self.cancelLogout()
            })
        presentViewController(alert, animated: true, completion: nil)
    }
    
    func cancelLogout()
    {
        
    }
    
    func logout()
    {
        ServiceContainer.instance.userLogout()
        self.dismissViewControllerAnimated(true) { () -> Void in
            MainNavigationController.start()
        }
        
    }
    
    //MARK: table view delegate
    func tableView(tableView: UITableView, estimatedHeightForHeaderInSection section: Int) -> CGFloat
    {
        return 21
    }
    
    @IBOutlet weak var tableView: UITableView!{
        didSet{
            tableView.estimatedRowHeight = tableView.rowHeight
            tableView.rowHeight = UITableViewAutomaticDimension
            tableView.dataSource = self
            tableView.delegate = self
            let uiview = UIView()
            uiview.backgroundColor = UIColor.clearColor()
            tableView.tableFooterView = uiview
        }
    }
    
    func tableView(tableView: UITableView, heightForRowAtIndexPath indexPath: NSIndexPath) -> CGFloat {
        if indexPath.section == 0 && indexPath.row == 0
        {
            return 84
        }
        return UITableViewAutomaticDimension
        
    }
    
    func numberOfSectionsInTableView(tableView: UITableView) -> Int {
        //user infos + about sharelink
        return 2
    }
    
    func tableView(tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        if section == 0
        {
            //Avatar(1) + textPropertyCells.count
            return 1 + textPropertyCells.count
        }else
        {
            return 1
        }
    }
    
    
    func tableView(tableView: UITableView, cellForRowAtIndexPath indexPath: NSIndexPath) -> UITableViewCell {
        if indexPath.section == 0
        {
            if indexPath.row == 0
            {
                return getAvatarCell()
            }else if indexPath.row > 0 && indexPath.row <= textPropertyCells.count
            {
                return getTextPropertyCell(indexPath.row - 1)
            }
            let cell = tableView.dequeueReusableCellWithIdentifier(MyDetailTextPropertyCell.reuseIdentifier, forIndexPath: indexPath)
            return cell
        }else
        {
            let cell = tableView.dequeueReusableCellWithIdentifier(MyDetailViewController.aboutSharelinkReuseId,forIndexPath: indexPath)
            cell.addGestureRecognizer(UITapGestureRecognizer(target: self, action: "aboutSharelink:"))
            return cell
        }
        
    }
    
    //MARK: Avatar
    var avatarImageView:UIImageView!
    func getAvatarCell() -> MyDetailAvatarCell
    {
        let cell = tableView.dequeueReusableCellWithIdentifier(MyDetailAvatarCell.reuseIdentifier) as! MyDetailAvatarCell
        
        let tapCell = UITapGestureRecognizer(target: self, action: "tapAvatarCell:")
        cell.addGestureRecognizer(tapCell)
        ServiceContainer.getService(FileService).setAvatar(cell.avatarImageView, iconFileId: myInfo.avatarId)
        let tapIcon = UITapGestureRecognizer(target: self, action: "tapAvatar:")
        cell.avatarImageView?.addGestureRecognizer(tapIcon)
        cell.avatarImageView.userInteractionEnabled = true
        avatarImageView = cell.avatarImageView
        return cell
    }
    
    func tapAvatar(_:UITapGestureRecognizer)
    {
        UUImageAvatarBrowser.showImage(avatarImageView)
    }
    
    func tapAvatarCell(aTap:UITapGestureRecognizer)
    {
        let alert = UIAlertController(title: NSLocalizedString("CHANGE_AVATAR", comment: "Change Avatar"), message: nil, preferredStyle: .ActionSheet)
        alert.addAction(UIAlertAction(title: NSLocalizedString("TAKE_NEW_PHOTO", comment: "Take A New Photo"), style: .Destructive) { _ in
            self.newPictureWithCamera()
            })
        alert.addAction(UIAlertAction(title:NSLocalizedString("SELECT_PHOTO", comment: "Select A Photo From Album"), style: .Destructive) { _ in
            self.selectPictureFromAlbum()
            })
        alert.addAction(UIAlertAction(title: NSLocalizedString("CANCEL", comment: ""), style: .Cancel){ _ in})
        presentViewController(alert, animated: true, completion: nil)
    }
    
    private var imagePickerController:UIImagePickerController! = UIImagePickerController()
    {
        didSet{
            imagePickerController.delegate = self
        }
    }
    
    func newPictureWithCamera()
    {
        imagePickerController.sourceType = .Camera
        imagePickerController.allowsEditing = true
        self.presentViewController(imagePickerController, animated: true, completion: nil)
    }
    
    func selectPictureFromAlbum()
    {
        imagePickerController.sourceType = .PhotoLibrary
        imagePickerController.allowsEditing = true
        imagePickerController.delegate = self
        self.presentViewController(imagePickerController, animated: true, completion: nil)
    }
    
    //MARK: upload avatar
    private var taskFileMap = [String:SendFileKey]()
    func imagePickerController(picker: UIImagePickerController, didFinishPickingImage image: UIImage, editingInfo: [String : AnyObject]?)
    {
        imagePickerController.dismissViewControllerAnimated(true)
        {
            self.avatarImageView.image = image
            let fService = ServiceContainer.getService(FileService)
            let imageData = UIImageJPEGRepresentation(image, 0.7)
            let localPath = fService.createLocalStoreFileName(FileType.Image)
            if PersistentManager.sharedInstance.storeFile(imageData!, filePath: localPath)
            {
                fService.sendFile(localPath, type: FileType.Image, callback: { (taskId, fileKey) -> Void in
                    if let tId = taskId
                    {
                        self.taskFileMap[tId] = fileKey
                        ProgressTaskWatcher.sharedInstance.addTaskObserver(taskId, delegate: self)
                        self.makeRootViewToast(NSLocalizedString("SET_AVATAR_SUC", comment: ""))
                        
                    }else
                    {
                        self.makeRootViewToast(NSLocalizedString("SET_AVATAR_FAILED", comment: ""))
                    }
                    
                })
            }else
            {
                self.makeRootViewToast(NSLocalizedString("SET_AVATAR_FAILED", comment: ""))
            }
        }
    }
    
    func taskCompleted(taskIdentifier: String, result: AnyObject!) {
        if let fileKey = taskFileMap.removeValueForKey(taskIdentifier)
        {
            let uService = ServiceContainer.getService(UserService)
            uService.setMyAvatar(fileKey.fileId, setProfileCallback: { (isSuc, msg) -> Void in
                if isSuc
                {
                    self.myInfo.avatarId = fileKey.accessKey
                    self.myInfo.saveModel()
                    self.avatarImageView.image = PersistentManager.sharedInstance.getImage(fileKey.accessKey)
                }else
                {
                    self.makeRootViewToast(NSLocalizedString("SET_AVATAR_FAILED", comment: ""))
                }
            })
        }
    }
    
    func taskFailed(taskIdentifier: String, result: AnyObject!) {
        taskFileMap.removeValueForKey(taskIdentifier)
        self.makeRootViewToast(NSLocalizedString("SET_AVATAR_FAILED", comment: ""))
    }
    
    func aboutSharelink(_:UITapGestureRecognizer)
    {
        AboutViewController.showAbout(self)
    }
    
    //MARK: Property Cell
    var textPropertyCells:[(propertySet:UIEditTextPropertySet!,editable:Bool)] = [(propertySet:UIEditTextPropertySet!,editable:Bool)]()
    
    func getTextPropertyCell(index:Int) -> MyDetailTextPropertyCell
    {
        let info = textPropertyCells[index]
        
        let cell = tableView.dequeueReusableCellWithIdentifier(MyDetailTextPropertyCell.reuseIdentifier) as! MyDetailTextPropertyCell
        cell.addGestureRecognizer(UITapGestureRecognizer(target: self, action: "tapTextProperty:"))
        cell.info = info
        return cell
    }
    
    func tapTextProperty(aTap:UITapGestureRecognizer)
    {
        let cell = aTap.view as! MyDetailTextPropertyCell
        if cell.info!.editable
        {
            let propertySet = cell.info!.propertySet
            UIEditTextPropertyViewController.showEditPropertyViewController(self.navigationController!, propertySet:propertySet, controllerTitle: propertySet.propertyLabel, delegate: self)
        }
    }
    
    func editPropertySave(propertyIdentifier: String!, newValue: String!)
    {
        let userService = ServiceContainer.getService(UserService)
        let ppt = self.textPropertyCells.filter{$0.propertySet.propertyIdentifier == propertyIdentifier}.first!
        ppt.propertySet.propertyValue = newValue
        switch propertyIdentifier
        {
            
            case InfoIds.nickName:
                userService.setProfileNick(newValue){ isSuc,msg in
                    if isSuc
                    {
                        self.myInfo.nickName = newValue
                        self.myInfo.saveModel()
                        self.tableView.reloadData()
                    }else
                    {
                        self.view.makeToast(message: msg)
                    }
                    
                }
            case InfoIds.motto:
                userService.setProfileMotto(newValue){ isSuc,msg in
                    if isSuc
                    {
                        self.myInfo.motto = newValue
                        self.myInfo.saveModel()
                        self.tableView.reloadData()
                    }else
                    {
                        self.view.makeToast(message: msg)
                    }
                }
        default: break
        }
    }
    
    static func instanceFromStoryBoard()->MyDetailViewController{
        return instanceFromStoryBoard("UserAccount", identifier: "MyDetailViewController") as! MyDetailViewController
    }
}
