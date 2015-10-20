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
    func showMyDetailView(currentNavigationController:UINavigationController)
    {
        let controller = MyDetailViewController.instanceFromStoryBoard()
        controller.accountId = BahamutConfig.lastLoginAccountId
        controller.myInfo = self.myUserModel
        currentNavigationController.pushViewController(controller, animated: true)
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

class MyDetailViewController: UIViewController,UITableViewDataSource,UIEditTextPropertyViewControllerDelegate,UITableViewDelegate,UIImagePickerControllerDelegate,UINavigationControllerDelegate
{
    struct InfoIds
    {
        static let nickName = "nickname"
        static let level = "level"
        static let motto = "signtext"
        static let createTime = "createtime"
    }
    
    var myInfo:ShareLinkUser!
    var accountId:String!
    
    private func initPropertySet()
    {
        var propertySet = UIEditTextPropertySet()
        propertySet.propertyIdentifier = InfoIds.nickName
        propertySet.propertyLabel = "Nick"
        propertySet.propertyValue = myInfo.nickName ?? myInfo.noteName
        propertySet.valueRegex = "^?{1,23}$"
        propertySet.illegalValueMessage = "At least 1 character,less than 23 character"
        textPropertyCells.append((propertySet:propertySet,editable:true))
        
        propertySet = UIEditTextPropertySet()
        propertySet.propertyIdentifier = InfoIds.level
        propertySet.propertyLabel = "Level"
        propertySet.propertyValue = "Lv.\(myInfo.level ?? 1)"
        textPropertyCells.append((propertySet:propertySet,editable:false))
        
        propertySet = UIEditTextPropertySet()
        propertySet.propertyIdentifier = InfoIds.createTime
        propertySet.propertyLabel = "Join"
        propertySet.propertyValue = myInfo.createTimeOfDate.toDateString()
        textPropertyCells.append((propertySet:propertySet,editable:false))
        
        propertySet = UIEditTextPropertySet()
        propertySet.propertyIdentifier = "accountId"
        propertySet.propertyLabel = "Sharelink ID"
        propertySet.propertyValue = accountId
        textPropertyCells.insert((propertySet:propertySet,editable:false), atIndex: 2)
        
        propertySet = UIEditTextPropertySet()
        propertySet.propertyIdentifier = InfoIds.motto
        propertySet.propertyLabel = "Motto"
        propertySet.propertyValue = myInfo.motto
        propertySet.isOneLineValue = false
        textPropertyCells.append((propertySet:propertySet,editable:true))
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        initPropertySet()
        tableView.estimatedRowHeight = tableView.rowHeight
        tableView.rowHeight = UITableViewAutomaticDimension
    }
    
    @IBAction func logout(sender: AnyObject)
    {
        let alert = UIAlertController(title: "Sure To Logout?", message: "it will clear all you message data with your sharelinkers", preferredStyle: .Alert)
        alert.addAction(UIAlertAction(title: "Yes", style: .Default) { _ in
            self.logout()
            })
        alert.addAction(UIAlertAction(title: "No", style: .Cancel) { _ in
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
        if indexPath.row == 0
        {
            return 84
        }else
        {
            return UITableViewAutomaticDimension
        }
        
    }
    
    func tableView(tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return 1 + textPropertyCells.count
    }
    
    
    func tableView(tableView: UITableView, cellForRowAtIndexPath indexPath: NSIndexPath) -> UITableViewCell {
        if indexPath.row == 0
        {
            return getAvatarCell()
        }else if indexPath.row > 0 && indexPath.row <= textPropertyCells.count
        {
            return getTextPropertyCell(indexPath.row - 1)
        }
        let cell = tableView.dequeueReusableCellWithIdentifier(MyDetailTextPropertyCell.reuseIdentifier, forIndexPath: indexPath)
        return cell
        
    }
    
    var avatarImageView:UIImageView!
    func getAvatarCell() -> MyDetailAvatarCell
    {
        let cell = tableView.dequeueReusableCellWithIdentifier(MyDetailAvatarCell.reuseIdentifier) as! MyDetailAvatarCell
        
        let tapCell = UITapGestureRecognizer(target: self, action: "tapAvatarCell:")
        cell.addGestureRecognizer(tapCell)
        cell.avatarImageView?.image = PersistentManager.sharedInstance.getImage(myInfo.avatarId ?? ImageAssetsConstants.defaultAvatar)
        let tapIcon = UITapGestureRecognizer(target: self, action: "tapAvatar:")
        cell.avatarImageView?.addGestureRecognizer(tapIcon)
        avatarImageView = cell.avatarImageView
        return cell
    }
    
    func tapAvatar(_:UITapGestureRecognizer)
    {
        UUImageAvatarBrowser.showImage(avatarImageView)
    }
    
    func tapAvatarCell(aTap:UITapGestureRecognizer)
    {
        let alert = UIAlertController(title: "Change Avatar", message: nil, preferredStyle: .ActionSheet)
        alert.addAction(UIAlertAction(title: "Take A New Photo", style: .Destructive) { _ in
            self.newPictureWithCamera()
            })
        alert.addAction(UIAlertAction(title: "Select A Photo From Album", style: .Destructive) { _ in
            self.selectPictureFromAlbum()
            })
        alert.addAction(UIAlertAction(title: "Cancel", style: .Cancel){ _ in})
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
                fService.requestFileId(localPath, type: FileType.Image){ fileKey in
                    if fileKey == nil
                    {
                        self.view.makeToast(message: "Set Avatar failed")
                        return
                    }
                    fService.startSendFile(fileKey.accessKey)
                    let uService = ServiceContainer.getService(UserService)
                    uService.setMyAvatar(fileKey.fileId, setProfileCallback: { (isSuc, msg) -> Void in
                        if isSuc
                        {
                            self.myInfo.avatarId = fileKey.accessKey
                            self.myInfo.saveModel()
                            self.avatarImageView.image = PersistentManager.sharedInstance.getImage(fileKey.accessKey)
                        }else
                        {
                            self.view.makeToast(message: "Set Avatar failed")
                        }
                    })
                }
            }else
            {
                self.view.makeToast(message: "Set Avatar failed")
            }
        }
    }
    
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
        let propertySet = cell.info!.propertySet
        UIEditTextPropertyViewController.showEditPropertyViewController(self.navigationController!, propertySet:propertySet, controllerTitle: propertySet.propertyLabel, delegate: self)
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
