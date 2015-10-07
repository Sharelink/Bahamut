//
//  MyDetailViewController.swift
//  Bahamut
//
//  Created by AlexChow on 15/9/18.
//  Copyright © 2015年 GStudio. All rights reserved.
//

import UIKit

extension UserService
{
    func showMyDetailView(currentNavigationController:UINavigationController)
    {
        let aService = ServiceContainer.getService(AccountService)
        let controller = MyDetailViewController.instanceFromStoryBoard()
        controller.accountId = aService.lastLoginAccountId
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

class MyDetailHeadIconCell:UITableViewCell
{
    static let reuseIdentifier = "MyDetailHeadIconCell"
    
    @IBOutlet weak var headIconImageView: UIImageView!{
        didSet{
            headIconImageView.layer.cornerRadius = 7
        }
    }
}

class MyDetailViewController: UIViewController,UITableViewDataSource,UIEditTextPropertyViewControllerDelegate,UITableViewDelegate,UIImagePickerControllerDelegate,UINavigationControllerDelegate
{
    struct InfoIds
    {
        static let nickName = "nickname"
        static let level = "level"
        static let signText = "signtext"
        static let createTime = "createtime"
    }
    
    var myInfo:ShareLinkUser!
    var accountId:String!
    
    private func initPropertySet()
    {
        var propertySet = UIEditTextPropertySet()
        propertySet.propertyIdentifier = InfoIds.nickName
        propertySet.propertyLabel = "Nick Name"
        propertySet.propertyValue = myInfo.nickName
        propertySet.valueRegex = "^[a-zA-Z0-9\\u4e00-\\u9fa5]{4,23}$"
        propertySet.illegalValueMessage = "At least 4 character,less than 23 character"
        textPropertyCells.append((propertySet:propertySet,editable:true))
        
        propertySet = UIEditTextPropertySet()
        propertySet.propertyIdentifier = InfoIds.level
        propertySet.propertyLabel = "Level"
        propertySet.propertyValue = "Lv.\(myInfo.level ?? 1)"
        textPropertyCells.append((propertySet:propertySet,editable:false))
        
        propertySet = UIEditTextPropertySet()
        propertySet.propertyIdentifier = InfoIds.createTime
        propertySet.propertyLabel = "Craete At"
        propertySet.propertyValue = DateHelper.stringToDate(myInfo.createTime).toDateString()
        textPropertyCells.append((propertySet:propertySet,editable:false))
        
        propertySet = UIEditTextPropertySet()
        propertySet.propertyIdentifier = "accountId"
        propertySet.propertyLabel = "AccountID"
        propertySet.propertyValue = accountId
        textPropertyCells.insert((propertySet:propertySet,editable:false), atIndex: 2)
        
        propertySet = UIEditTextPropertySet()
        propertySet.propertyIdentifier = InfoIds.signText
        propertySet.propertyLabel = "Sign Text"
        propertySet.propertyValue = myInfo.signText
        propertySet.isOneLineValue = false
        textPropertyCells.append((propertySet:propertySet,editable:true))
    }
    
    override func viewDidLoad() {
        initPropertySet()
        tableView.estimatedRowHeight = tableView.rowHeight
        tableView.rowHeight = UITableViewAutomaticDimension
        super.viewDidLoad()
    }
    
    @IBAction func logout(sender: AnyObject)
    {
        let alert = UIAlertController(title: "Sure To Logout?", message: nil, preferredStyle: .Alert)
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
        let service = ServiceContainer.getService(AccountService)
        service.logout { (msg) -> Void in
            let fileSvr = ServiceContainer.getService(FileService)
            fileSvr.clearUserDatas()
            MainNavigationController.start(msg)
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
            return getHeadIconCell()
        }else if indexPath.row > 0 && indexPath.row <= textPropertyCells.count
        {
            return getTextPropertyCell(indexPath.row - 1)
        }
        let cell = tableView.dequeueReusableCellWithIdentifier(MyDetailTextPropertyCell.reuseIdentifier, forIndexPath: indexPath)
        return cell
        
    }
    
    var headIconImageView:UIImageView!
    func getHeadIconCell() -> MyDetailHeadIconCell
    {
        let cell = tableView.dequeueReusableCellWithIdentifier(MyDetailHeadIconCell.reuseIdentifier) as! MyDetailHeadIconCell
        
        let tapCell = UITapGestureRecognizer(target: self, action: "tapHeadIconCell:")
        cell.addGestureRecognizer(tapCell)
        cell.headIconImageView?.image = PersistentManager.sharedInstance.getImage(myInfo.headIconId ?? ImageAssetsConstants.defaultHeadIcon)
        let tapIcon = UITapGestureRecognizer(target: self, action: "tapHeadIcon:")
        cell.headIconImageView?.addGestureRecognizer(tapIcon)
        headIconImageView = cell.headIconImageView
        return cell
    }
    
    func tapHeadIcon(_:UITapGestureRecognizer)
    {
        let imageFileFetcher = ServiceContainer.getService(FileService).getFileFetcherOfFileId(FileType.Image)
        UIImagePlayerController.showImagePlayer(self, imageUrls: [myInfo.headIconId ?? ImageAssetsConstants.defaultHeadIcon],imageFileFetcher: imageFileFetcher)
    }
    
    func tapHeadIconCell(aTap:UITapGestureRecognizer)
    {
        let alert = UIAlertController(title: "Change Head Icon", message: nil, preferredStyle: .ActionSheet)
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
            if self.headIconImageView != nil
            {
                self.headIconImageView.image = image
                let fService = ServiceContainer.getService(FileService)
                let imageData = UIImageJPEGRepresentation(image, 1)
                let localPath = fService.createLocalStoreFileName(FileType.Image)
                PersistentManager.sharedInstance.storeFile(imageData!, filePath: localPath)
                fService.requestFileId(localPath, type: FileType.Image, callback: { (fileId) -> Void in
                    fService.startSendFile(fileId)
                    let uService = ServiceContainer.getService(UserService)
                    uService.setUserHeadIcon(fileId, setProfileCallback: { (isSuc, msg) -> Void in
                        if isSuc
                        {
                            self.myInfo.headIconId = fileId
                            self.myInfo.saveModel()
                            self.headIconImageView.image = PersistentManager.sharedInstance.getImage(fileId)
                        }else
                        {
                            self.view.makeToast(message: "Set Head Icon failed")
                        }
                    })
                })
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
            case InfoIds.signText:
                userService.setProfileSignText(newValue){ isSuc,msg in
                    if isSuc
                    {
                        self.myInfo.signText = newValue
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
