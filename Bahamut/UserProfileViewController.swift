//
//  UserProfileViewController.swift
//  Bahamut
//
//  Created by AlexChow on 15/8/15.
//  Copyright © 2015年 GStudio. All rights reserved.
//

import UIKit
import ChatFramework
import SharelinkSDK

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
    
    func showUserProfileViewController(currentNavigationController:UINavigationController,userProfile:Sharelinker)
    {
        let controller = UserProfileViewController.instanceFromStoryBoard()
        controller.userProfileModel = userProfile
        currentNavigationController.pushViewController(controller , animated: true)
    }

}

extension SharelinkTagService
{
    func showConfirmAddTagAlert(curentViewController:UIViewController,tag:SharelinkTag)
    {
        let alert = UIAlertController(title: NSLocalizedString("FOCUS", comment: "") , message: String(format: NSLocalizedString("CONFIRM_FOCUS_TAG", comment: ""), tag.getShowName()), preferredStyle: UIAlertControllerStyle.Alert)
        alert.addAction(UIAlertAction(title: NSLocalizedString("YES", comment: ""), style: .Default){ _ in
            self.addThisTapToMyFocus(curentViewController,tag: tag)
            })
        alert.addAction(UIAlertAction(title: NSLocalizedString("UMMM", comment: ""), style: .Cancel){ _ in
            self.cancelAddTag(tag)
            })
        curentViewController.presentViewController(alert, animated: true, completion: nil)
    }
    
    func cancelAddTag(tag:SharelinkTag)
    {
        
    }
    
    func addThisTapToMyFocus(curentViewController:UIViewController,tag:SharelinkTag)
    {
        if self.isTagExists(tag.data)
        {
            let alert = UIAlertController(title: nil, message: NSLocalizedString("SAME_TAG_EXISTS", comment: ""), preferredStyle: .Alert)
            alert.addAction(UIAlertAction(title: "I_SEE", style: .Cancel, handler: nil))
            curentViewController.presentViewController(alert, animated: true, completion: nil)
            return
        }
        
        let newTag = SharelinkTag()
        newTag.tagName = tag.tagName
        newTag.tagColor = tag.tagColor
        newTag.isFocus = "true"
        newTag.type = tag.type
        newTag.showToLinkers = "true"
        newTag.data = tag.data
        self.addSharelinkTag(newTag) { (suc) -> Void in
            let alerttitle = suc ? NSLocalizedString("FOCUS_TAG_SUCCESS", comment: "") : NSLocalizedString("FOCUS_TAG_FAILED", comment: "")
            let alert = UIAlertController(title:alerttitle , message: nil, preferredStyle: UIAlertControllerStyle.Alert)
            alert.addAction(UIAlertAction(title: NSLocalizedString("I_SEE", comment: ""), style: .Cancel){ _ in
                })
            curentViewController.presentViewController(alert, animated: true, completion: nil)
        }
        
    }
}

//MARK:UserProfileViewController
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
    var userProfileModel:Sharelinker!
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
    
    func bindTapActions()
    {
        avatarImageView.addGestureRecognizer(UITapGestureRecognizer(target: self, action: "avatarTapped:"))
    }
    
    func avatarTapped(_:UITapGestureRecognizer)
    {
        UUImageAvatarBrowser.showImage(avatarImageView)
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
            let frame = profileVideoViewContainer.bounds
            profileVideoView = ShareLinkFilmView(frame: frame)
            profileVideoView.backgroundColor = UIColor.whiteColor()
            profileVideoView.playerController.fillMode = AVLayerVideoGravityResizeAspectFill
        }
    }
    
    //MARK: focus tags
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
            ServiceContainer.getService(SharelinkTagService).showConfirmAddTagAlert(self,tag: sender.tags[indexPath.row])
        }
    }
    
    @IBOutlet weak var focusTagViewContainer: UIView!{
        didSet{
            focusTagViewContainer.layer.cornerRadius = 7
            focusTagController = UITagCollectionViewController.instanceFromStoryBoard()
            focusTagViewContainer.addSubview(focusTagController.view)
            
        }
    }

    
    //MARK: personal video
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
        let alert = UIAlertController(title:NSLocalizedString("CHANGE_PROFILE_VIDEO", comment: "Change Profile Video"), message: nil, preferredStyle: .ActionSheet)
        alert.addAction(UIAlertAction(title:NSLocalizedString("REC_NEW_VIDEO", comment: "Record A New Video"), style: .Destructive) { _ in
            self.recordVideo()
            })
        alert.addAction(UIAlertAction(title:NSLocalizedString("SELECT_VIDEO", comment: "Select A Video From Album"), style: .Destructive) { _ in
            self.seleteVideo()
            })
        alert.addAction(UIAlertAction(title:NSLocalizedString("CANCEL",comment:""), style: .Cancel){ _ in})
        presentViewController(alert, animated: true, completion: nil)
    }
    
    private func recordVideo()
    {
        UICameraViewController.showCamera(self.navigationController!, delegate: self)
    }
    
    func cameraCancelRecord(sender: UICameraViewController!)
    {
        view.makeToast(message: NSLocalizedString("CANCELED", comment: ""))
    }
    
    func cameraSaveRecordVideo(sender: UICameraViewController!, destination: String!)
    {
        let fileService = ServiceContainer.getService(FileService)
        let newFilePath = fileService.createLocalStoreFileName(FileType.Video)
        if fileService.moveFileTo(destination, destinationPath: newFilePath)
        {
            profileVideoView.fileFetcher = fileService.getFileFetcherOfFilePath(FileType.Video)
            profileVideoView.filePath = newFilePath
            self.view.makeToast(message:NSLocalizedString("VIDEO_SAVED", comment: ""))
            saveProfileVideo()
        }else
        {
            self.view.makeToast(message: NSLocalizedString("SAVE_VIDEO_FAILED",comment:""))
        }
    }
    
    private func seleteVideo()
    {
        let files = ServiceContainer.getService(FileService).getFileModelsOfFileLocalStore(FileType.Video)
        ServiceContainer.getService(FileService).showFileCollectionControllerView(self.navigationController!, files: files,selectionMode:.Single, delegate: self)
    }
    
    //MARK: delegate for video resource item
    
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
    
    //MARK: update
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
        updateNoteButton()
    }
    
    private func updateNoteButton()
    {
        if userProfileModel.userId == ServiceContainer.getService(UserService).myUserId
        {
            self.navigationItem.rightBarButtonItems?.removeAll()
        }
    }
    
    func updateName()
    {
        self.navigationItem.title = userProfileModel.getNoteName()
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
        propertySet.propertyLabel = NSLocalizedString("NOTE_NAME", comment: "Note Name")
        UIEditTextPropertyViewController.showEditPropertyViewController(self.navigationController!,propertySet:propertySet, controllerTitle: NSLocalizedString("NOTE_NAME", comment: ""), delegate: self)
    }
    
    func editPropertySave(propertyId: String!, newValue: String!)
    {
        let userService = ServiceContainer.getService(UserService)
        if propertyId == "note"
        {
            self.view.makeToastActivityWithMessage(message:NSLocalizedString("UPDATING", comment: ""))
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
