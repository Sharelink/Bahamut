//
//  MyDetailViewController.swift
//  Bahamut
//
//  Created by AlexChow on 15/9/18.
//  Copyright © 2015年 GStudio. All rights reserved.
//

import UIKit
import ChatFramework


extension UserService
{
    func showMyDetailView(currentViewController:UIViewController)
    {
        dispatch_async(dispatch_get_main_queue()) { () -> Void in
            if let myInfo = self.myUserModel
            {
                let controller = MyDetailViewController.instanceFromStoryBoard()
                controller.accountId = UserSetting.lastLoginAccountId
                controller.myInfo = myInfo
                currentViewController.navigationController?.pushViewController(controller, animated: true)
            }else
            {
                currentViewController.showToast( NSLocalizedString("USER_DATA_NOT_READY_RETRY", comment: "User Data Not Ready,Retry Later"))
            }
        }
        
    }
}

class MyDetailTextPropertyCell:UITableViewCell
{
    static let reuseIdentifier = "MyDetailTextPropertyCell"
    var info:MyDetailCellModel!{
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


struct MyDetailCellModel {
    var propertySet:UIEditTextPropertySet!
    var editable:Bool = false
    var selector:Selector!
}

//MARK:MyDetailViewController
class MyDetailViewController: UIViewController,UITableViewDataSource,UIEditTextPropertyViewControllerDelegate,UITableViewDelegate,UIImagePickerControllerDelegate,UINavigationControllerDelegate,ProgressTaskDelegate
{
    static let aboutSharelinkReuseId = "aboutsharelink"
    static let clearCacheCellReuseId = "clearCache"
    struct InfoIds
    {
        static let nickName = "nickname"
        static let level = "level"
        static let levelScore = "levelScore"
        static let motto = "signtext"
        static let createTime = "createtime"
        static let changePsw = "changePsw"
        static let useTink = "useTink"
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
        textPropertyCells.append(MyDetailCellModel(propertySet: propertySet, editable: true, selector: "tapTextProperty:"))
        
        propertySet = UIEditTextPropertySet()
        propertySet.propertyIdentifier = InfoIds.level
        propertySet.propertyLabel = NSLocalizedString("LEVEL", comment:"Level")
        propertySet.propertyValue = "Lv.\(myInfo.level ?? 1)"
        //TODO: cancel hidden when level model completed
        //textPropertyCells.append(MyDetailCellModel(propertySet:propertySet,editable:false, selector: nil))
        
        propertySet = UIEditTextPropertySet()
        propertySet.propertyIdentifier = InfoIds.levelScore
        propertySet.propertyLabel = NSLocalizedString("SHARELINK_SCORE", comment:"Sharelink Score")
        propertySet.propertyValue = "\(myInfo.levelScore ?? 1)"
        //TODO: cancel hidden when level model completed
        //textPropertyCells.append(MyDetailCellModel(propertySet:propertySet,editable:false, selector: nil))
        
        propertySet = UIEditTextPropertySet()
        propertySet.propertyIdentifier = InfoIds.createTime
        propertySet.propertyLabel = NSLocalizedString("JOIN", comment: "Join")
        propertySet.propertyValue = myInfo.createTimeOfDate.toDateString()
        textPropertyCells.append(MyDetailCellModel(propertySet:propertySet,editable:false, selector: nil))
        
        propertySet = UIEditTextPropertySet()
        propertySet.propertyIdentifier = "accountId"
        propertySet.propertyLabel = NSLocalizedString("ACCOUNT_ID", comment: "Sharelink ID")
        propertySet.propertyValue = accountId
        textPropertyCells.insert(MyDetailCellModel(propertySet:propertySet,editable:false, selector: nil), atIndex: 2)
        
        propertySet = UIEditTextPropertySet()
        propertySet.propertyIdentifier = InfoIds.motto
        propertySet.propertyLabel = NSLocalizedString("MOTTO", comment: "Motto")
        propertySet.propertyValue = myInfo.motto
        propertySet.isOneLineValue = false
        textPropertyCells.append(MyDetailCellModel(propertySet:propertySet,editable:true, selector: "tapTextProperty:"))
        
        propertySet = UIEditTextPropertySet()
        propertySet.propertyIdentifier = InfoIds.changePsw
        propertySet.propertyLabel = NSLocalizedString("CHANGE_PSW", comment: "Change Password")
        propertySet.propertyValue = ""
        textPropertyCells.append(MyDetailCellModel(propertySet:propertySet,editable:true, selector: "changePassword:"))
        
        propertySet = UIEditTextPropertySet()
        propertySet.propertyIdentifier = InfoIds.useTink
        propertySet.propertyLabel = NSLocalizedString("TINK_TINK_TINK", comment: "")
        propertySet.propertyValue = ""
        textPropertyCells.append(MyDetailCellModel(propertySet:propertySet,editable:true, selector: "useTinkTinkTink:"))
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        changeNavigationBarColor()
        initPropertySet()
        tableView.estimatedRowHeight = tableView.rowHeight
        tableView.rowHeight = UITableViewAutomaticDimension
        let uiview = UIView()
        tableView.backgroundColor = UIColor.footerColor
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
        self.presentViewController(alert, animated: true, completion: nil)
    }
    
    func cancelLogout()
    {
        
    }
    
    func logout()
    {
        ServiceContainer.instance.userLogout()
        MainNavigationController.start()
    }
    
    //MARK: table view delegate
    
    func tableView(tableView: UITableView, heightForHeaderInSection section: Int) -> CGFloat {
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
        //user infos + about sharelink + clear tmp file
        return 3
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
        }else if indexPath.section == 1
        {
            let cell = tableView.dequeueReusableCellWithIdentifier(MyDetailViewController.clearCacheCellReuseId,forIndexPath: indexPath)
            cell.addGestureRecognizer(UITapGestureRecognizer(target: self, action: "clearTempDir:"))
            return cell
        }else
        {
            let cell = tableView.dequeueReusableCellWithIdentifier(MyDetailViewController.aboutSharelinkReuseId,forIndexPath: indexPath)
            cell.addGestureRecognizer(UITapGestureRecognizer(target: self, action: "aboutSharelink:"))
            return cell
        }
    }
    
    //MARK: change password
    func changePassword(_:UITapGestureRecognizer)
    {
        self.navigationController?.pushViewController(ChangePasswordViewController.instanceFromStoryBoard(), animated: true)
    }
    
    func useTinkTinkTink(_:UITapGestureRecognizer)
    {
        self.navigationController?.pushViewController(UseTinkViewController.instanceFromStoryBoard(), animated: true)
    }
    
    //MARK: Clear User Tmp Dir
    func clearTempDir(_:UITapGestureRecognizer)
    {
        let actions =
        [
            UIAlertAction(title: NSLocalizedString("YES", comment: ""), style: .Default, handler: { (action) -> Void in
                PersistentManager.sharedInstance.clearFileCacheFiles()
                PersistentManager.sharedInstance.resetTmpDir()
                self.showAlert(NSLocalizedString("CLEAR_CACHE_SUCCESS", comment: ""), msg: "")
            }),
            UIAlertAction(title: NSLocalizedString("CANCEL", comment: ""), style: .Cancel, handler: nil)
        ]
        showAlert(NSLocalizedString("CONFIRM_CLEAR_CACHE_TITLE", comment: "Sure To Clear Cache Files?"), msg: nil, actions: actions)
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
    private var taskFileMap = [String:FileAccessInfo]()
    func imagePickerController(picker: UIImagePickerController, didFinishPickingImage image: UIImage, editingInfo: [String : AnyObject]?)
    {
        imagePickerController.dismissViewControllerAnimated(true)
        {
            self.avatarImageView.image = image
            let fService = ServiceContainer.getService(FileService)
            let imageData = UIImageJPEGRepresentation(image, 0.7)
            let localPath = fService.createLocalStoreFileName(FileType.Image)
            if PersistentFileHelper.storeFile(imageData!, filePath: localPath)
            {
                fService.sendFileToAliOSS(localPath, type: FileType.Image, callback: { (taskId, fileKey) -> Void in
                    ProgressTaskWatcher.sharedInstance.addTaskObserver(taskId, delegate: self)
                    if let fk = fileKey
                    {
                        self.taskFileMap[taskId] = fk
                    }
                })
            }else
            {
                self.showToast(NSLocalizedString("SET_AVATAR_FAILED", comment: ""))
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
                    self.showCheckMark(NSLocalizedString("SET_AVATAR_SUC", comment: ""))
                }
            })
        }
    }
    
    func taskFailed(taskIdentifier: String, result: AnyObject!) {
        taskFileMap.removeValueForKey(taskIdentifier)
        self.showToast(NSLocalizedString("SET_AVATAR_FAILED", comment: ""))
    }
    
    func aboutSharelink(_:UITapGestureRecognizer)
    {
        AboutViewController.showAbout(self)
    }

    
    //MARK: Property Cell
    var textPropertyCells:[MyDetailCellModel] = [MyDetailCellModel]()
    
    func getTextPropertyCell(index:Int) -> MyDetailTextPropertyCell
    {
        let info = textPropertyCells[index]
        
        let cell = tableView.dequeueReusableCellWithIdentifier(MyDetailTextPropertyCell.reuseIdentifier) as! MyDetailTextPropertyCell
        if info.selector != nil
        {
            cell.addGestureRecognizer(UITapGestureRecognizer(target: self, action: info.selector))
        }
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
                userService.setProfileNick(newValue){ isSuc in
                    if isSuc
                    {
                        self.tableView.reloadData()
                        self.showCheckMark(String(format: NSLocalizedString("MODIFY_KEY_SUC", comment: ""), NSLocalizedString("NICK", comment: "")))
                    }else
                    {
                        self.showToast(String(format: NSLocalizedString("SET_KEY_FAILED", comment: ""), NSLocalizedString("NICK", comment: "")))
                    }
                    
                }
            case InfoIds.motto:
                userService.setProfileMotto(newValue){ isSuc in
                    if isSuc
                    {
                        self.tableView.reloadData()
                        self.showCheckMark(String(format: NSLocalizedString("MODIFY_KEY_SUC", comment: ""), NSLocalizedString("MOTTO", comment: "")))
                    }else
                    {
                        self.showToast(String(format: NSLocalizedString("SET_KEY_FAILED", comment: ""), NSLocalizedString("MOTTO", comment: "")))
                    }
                }
        default: break
        }
    }
    
    static func instanceFromStoryBoard()->MyDetailViewController{
        return instanceFromStoryBoard("UserAccount", identifier: "MyDetailViewController",bundle: Sharelink.mainBundle) as! MyDetailViewController
    }
}
