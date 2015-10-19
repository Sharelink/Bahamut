//
//  UserProfileViewController.swift
//  Bahamut
//
//  Created by AlexChow on 15/8/15.
//  Copyright © 2015年 GStudio. All rights reserved.
//

import UIKit
import ChatFramework

//MARK: UserService
extension UserService
{
    func showUserProfileViewController(currentNavigationController:UINavigationController,userId:String)
    {
        if let userProfile = self.getUser(userId)
        {
            showUserProfileViewController(currentNavigationController, userProfile: userProfile)
        }
    }
    
    func showUserProfileViewController(currentNavigationController:UINavigationController,userProfile:ShareLinkUser)
    {
        let controller = UserProfileViewController.instanceFromStoryBoard()
        controller.userProfileModel = userProfile
        currentNavigationController.pushViewController(controller , animated: true)
    }
}

class UserProfileViewController: UIViewController,UIEditTextPropertyViewControllerDelegate,UICameraViewControllerDelegate,UIResourceExplorerDelegate,UITagCollectionViewControllerDelegate
{

    private var profileVideoView:ShareLinkFilmView!{
        didSet{
            profileVideoViewContainer.addSubview(profileVideoView)
            profileVideoView.autoLoad = true
            profileVideoView.canSwitchToFullScreen = true
            profileVideoView.isMute = false
            profileVideoViewContainer.sendSubviewToBack(profileVideoView)
        }
    }
    
    @IBOutlet weak var editProfileVideoButton: UIButton!
    @IBOutlet weak var profileVideoViewContainer: UIView!
    
    @IBOutlet weak var avatarImageView: UIImageView!{
        didSet{
            avatarImageView.layer.cornerRadius = 3
            avatarImageView.userInteractionEnabled = true
        }
    }
    @IBOutlet weak var userMottoView: UILabel!{
        didSet{
            userMottoView.userInteractionEnabled = true
        }
    }
    @IBOutlet weak var userNickNameLabelView: UILabel!{
        didSet{
            userNickNameLabelView.userInteractionEnabled = true
        }
    }
    
    let fileService = ServiceContainer.getService(FileService)
    var userProfileModel:ShareLinkUser!
    var isMyProfile:Bool{
        return userProfileModel.userId == ServiceContainer.getService(UserService).myUserId
    }
    override func viewDidLoad() {
        super.viewDidLoad()
        initProfileVideoView()
        initTags()
    }
    
    func initTags()
    {
        tags = ServiceContainer.getService(SharelinkTagService).getUserTags(userProfileModel.userId){ result in
            self.tags = result
        }
    }
    
    override func viewWillAppear(animated: Bool)
    {
        super.viewWillAppear(animated)
        bindTapActions()
        update()
        updateEditVideoButton()
    }
    
    override func viewDidAppear(animated: Bool) {
        super.viewDidAppear(animated)
        updatePersonalFilm()
    }
    
    private func initProfileVideoView()
    {
        if profileVideoView == nil
        {
            profileVideoView = ShareLinkFilmView(frame: profileVideoViewContainer.bounds)
        }
    }
    
    var focusTagController:UITagCollectionViewController!{
        didSet{
            self.addChildViewController(focusTagController)
            focusTagController.delegate = self
        }
    }
    
    func tagDidTap(sender: UITagCollectionViewController, indexPath: NSIndexPath)
    {
        if isMyProfile
        {
            return
        }
        if sender == focusTagController
        {
            showConfirmAddTagAlert(sender.tags[indexPath.row])
        }
    }
    
    func showConfirmAddTagAlert(tag:SharelinkTag)
    {
        let alert = UIAlertController(title: "I'm interest in \(tag.tagName)", message: "Are your sure to focus this tag?", preferredStyle: UIAlertControllerStyle.Alert)
        alert.addAction(UIAlertAction(title: "Yes!", style: .Default){ _ in
            self.addThisTapToMyFocus(tag)
        })
        alert.addAction(UIAlertAction(title: "Ummm!", style: .Cancel){ _ in
            self.cancelAddTap(tag)
        })
        self.presentViewController(alert, animated: true, completion: nil)
    }
    
    func cancelAddTap(tag:SharelinkTag)
    {
        
    }
    
    func addThisTapToMyFocus(tag:SharelinkTag)
    {
        let tagService = ServiceContainer.getService(SharelinkTagService)
        let newTag = SharelinkTag()
        newTag.tagName = tag.tagName
        newTag.tagColor = tag.tagColor
        newTag.isFocus = "\(true)"
        newTag.data = tag.data
        tagService.addSharelinkTag(newTag) { (suc) -> Void in
            let alerttitle = suc ? "Focus \(tag.tagName) successful!" : "focus failed,check your network if is down"
            let alert = UIAlertController(title:alerttitle , message: nil, preferredStyle: UIAlertControllerStyle.Alert)
            alert.addAction(UIAlertAction(title: "OK", style: .Cancel){ _ in
                })
            self.presentViewController(alert, animated: true, completion: nil)
        }
        
    }
    
    override func viewWillLayoutSubviews() {
        super.viewWillLayoutSubviews()
    }
    
    @IBOutlet weak var focusTagViewContainer: UIView!{
        didSet{
            focusTagViewContainer.layer.cornerRadius = 7
            focusTagController = UITagCollectionViewController.instanceFromStoryBoard()
            focusTagViewContainer.addSubview(focusTagController.view)
            
        }
    }
    
    func bindTapActions()
    {
        avatarImageView.addGestureRecognizer(UITapGestureRecognizer(target: self, action: "avatarTapped:"))
    }
    
    func saveProfileVideo()
    {
        let fService = ServiceContainer.getService(FileService)
        fService.requestFileId(profileVideoView.filePath, type: FileType.Video, callback: { (fileKey) -> Void in
            self.view.hideToastActivity()
            if fileKey != nil
            {
                fService.startSendFile(fileKey.accessKey)
                let uService = ServiceContainer.getService(UserService)
                uService.setMyProfileVideo(fileKey.fileId, setProfileCallback: { (isSuc, msg) -> Void in
                    if isSuc
                    {
                        self.userProfileModel.personalVideoId = fileKey.accessKey
                        self.userProfileModel.saveModel()
                        self.updatePersonalFilm()
                    }
                })
            }
        })
    }
    
    @IBAction func editProfileVideo()
    {
        showEditProfileVideoActionSheet()
    }
    
    private func showEditProfileVideoActionSheet()
    {
        let alert = UIAlertController(title: "Change Profile Video", message: nil, preferredStyle: .ActionSheet)
        alert.addAction(UIAlertAction(title: "Record A New Video", style: .Destructive) { _ in
            self.recordVideo()
            })
        alert.addAction(UIAlertAction(title: "Select A Video From Album", style: .Destructive) { _ in
            self.seleteVideo()
            })
        alert.addAction(UIAlertAction(title: "Cancel", style: .Cancel){ _ in})
        presentViewController(alert, animated: true, completion: nil)
    }
    
    private func recordVideo()
    {
        UICameraViewController.showCamera(self.navigationController!, delegate: self)
    }
    
    func cameraCancelRecord(sender: UICameraViewController!)
    {
        view.makeToast(message: "Cancel")
    }
    
    func cameraSaveRecordVideo(sender: UICameraViewController!, destination: String!)
    {
        let fileService = ServiceContainer.getService(FileService)
        let newFilePath = fileService.createLocalStoreFileName(FileType.Video)
        if fileService.moveFileTo(destination, destinationPath: newFilePath)
        {
            profileVideoView.fileFetcher = fileService.getFileFetcherOfFilePath(FileType.Video)
            profileVideoView.filePath = newFilePath
            self.view.makeToast(message: "Video Saved")
            saveProfileVideo()
        }else
        {
            self.view.makeToast(message: "Save Video Failed")
        }
    }
    
    private func seleteVideo()
    {
        let files = ServiceContainer.getService(FileService).getFileModelsOfFileLocalStore(FileType.Video)
        ServiceContainer.getService(FileService).showFileCollectionControllerView(self.navigationController!, files: files,selectionMode:.Single, delegate: self)
    }
    
    func resourceExplorerItemsSelected(itemModels: [UIResrouceItemModel],sender: UIResourceExplorerController!) {
        if itemModels.count > 0
        {
            let fileModel = itemModels.first as! UIFileCollectionCellModel
            profileVideoView.fileFetcher = fileService.getFileFetcherOfFilePath(FileType.Video)
            profileVideoView.filePath = fileModel.filePath
            saveProfileVideo()
        }
    }
    
    func resourceExplorerOpenItem(itemModel: UIResrouceItemModel, sender: UIResourceExplorerController!) {
        let fileModel = itemModel as! UIFileCollectionCellModel
        ShareLinkFilmView.showPlayer(sender, uri: fileModel.filePath, fileFetcer: FilePathFileFetcher.shareInstance)
    }
    
    func updateEditVideoButton()
    {
        editProfileVideoButton.hidden = !isMyProfile
    }
    
    func update()
    {
        updateName()
        userMottoView.text = userProfileModel.motto
        updateAvatar()
        updatePersonalFilm()
    }
    
    func updateName()
    {
        self.navigationItem.title = userProfileModel.noteName ?? userProfileModel.nickName
        userNickNameLabelView.text = userProfileModel.nickName
    }
    
    func updatePersonalFilm()
    {
        if profileVideoView == nil
        {
            return
        }
        profileVideoView.fileFetcher = ServiceContainer.getService(FileService).getFileFetcherOfFileId(FileType.Video)
        if nil == userProfileModel.personalVideoId || userProfileModel.personalVideoId.isEmpty
        {
            profileVideoView.filePath = FilmAssetsConstants.defaultPersonalFilm
        }else
        {
            profileVideoView.filePath = userProfileModel.personalVideoId
        }
    }
    
    func updateAvatar()
    {
        fileService.setAvatar(avatarImageView, iconFileId: userProfileModel.avatarId)
    }
    
    //MARK: user tag
    var tags:[SharelinkTag]!{
        didSet{
            self.focusTagController.tags = tags
        }
    }
    
    @IBAction func editNoteName()
    {
        let propertySet = UIEditTextPropertySet()
        propertySet.propertyIdentifier = "note"
        propertySet.propertyValue = userProfileModel.noteName
        propertySet.propertyLabel = "Note Name"
        UIEditTextPropertyViewController.showEditPropertyViewController(self.navigationController!,propertySet:propertySet, controllerTitle: "Note Name", delegate: self)
    }
    
    func avatarTapped(_:UITapGestureRecognizer)
    {
        UUImageAvatarBrowser.showImage(avatarImageView)
    }
    
    func editPropertySave(propertyId: String!, newValue: String!)
    {
        let userService = ServiceContainer.getService(UserService)
        if propertyId == "note"
        {
            self.view.makeToastActivityWithMessage(message: "Updating")
            userService.setLinkerNoteName(userProfileModel.userId, newNoteName: newValue){ isSuc,msg in
                self.view.hideToastActivity()
                if isSuc
                {
                    self.userProfileModel.noteName = newValue
                    self.userProfileModel.saveModel()
                    self.updateName()
                }
            }
        }
    }
    
    static func instanceFromStoryBoard() -> UserProfileViewController
    {
        return instanceFromStoryBoard("UserAccount", identifier: "userProfileViewController") as! UserProfileViewController
    }
}
