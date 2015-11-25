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
    
    func showUserProfileViewController(currentNavigationController:UINavigationController,userProfile:Sharelinker)
    {
        let controller = UserProfileViewController.instanceFromStoryBoard()
        controller.userProfileModel = userProfile
        currentNavigationController.pushViewController(controller , animated: true)
    }

}
//MARK: extension SharelinkTagService
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
            alert.addAction(UIAlertAction(title: NSLocalizedString("I_SEE",comment:""), style: .Cancel, handler: nil))
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
class UserProfileViewController: UIViewController,UIEditTextPropertyViewControllerDelegate,QupaiSDKDelegate,UIResourceExplorerDelegate,UITagCollectionViewControllerDelegate,ProgressTaskDelegate
{

    //MARK: properties
    private var profileVideoView:ShareLinkFilmView!{
        didSet{
            profileVideoViewContainer.addSubview(profileVideoView)
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
    
    //MARK: init
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
        MobClick.beginLogPageView("SharelinkerProfile")
    }
    
    override func viewWillDisappear(animated: Bool) {
        super.viewWillAppear(animated)
        MobClick.endLogPageView("SharelinkerProfile")
    }
    
    override func viewDidAppear(animated: Bool) {
        super.viewDidAppear(animated)
        
    }
    
    private func initProfileVideoView()
    {
        if profileVideoView == nil
        {
            let frame = profileVideoViewContainer.bounds
            profileVideoView = ShareLinkFilmView(frame: frame)
            profileVideoView.backgroundColor = UIColor.whiteColor()
            profileVideoView.playerController.fillMode = AVLayerVideoGravityResizeAspectFill
            profileVideoView.autoPlay = true
            profileVideoView.autoLoad = true
            profileVideoView.canSwitchToFullScreen = true
            profileVideoView.isMute = false
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
    
    private var taskFileMap = [String:FileAccessInfo]()
    
    func saveProfileVideo()
    {
        let fService = ServiceContainer.getService(FileService)
        fService.sendBahamutFire(profileVideoView.filePath, type: FileType.Video) { (taskId, fileKey) -> Void in
            ProgressTaskWatcher.sharedInstance.addTaskObserver(taskId, delegate: self)
            if let fk = fileKey
            {
                self.taskFileMap[taskId] = fk
            }
        }
        
    }
    
    func taskCompleted(taskIdentifier: String, result: AnyObject!) {
        let uService = ServiceContainer.getService(UserService)
        if let fileKey = taskFileMap.removeValueForKey(taskIdentifier)
        {
            uService.setMyProfileVideo(fileKey.fileId, setProfileCallback: { (isSuc, msg) -> Void in
                if isSuc
                {
                    self.userProfileModel.personalVideoId = fileKey.accessKey
                    self.userProfileModel.saveModel()
                    self.updatePersonalFilm()
                    self.showToast(NSLocalizedString("SET_PROFILE_VIDEO_SUC", comment: ""))
                }
            })
        }
        
    }
    
    func taskFailed(taskIdentifier: String, result: AnyObject!) {
        self.showToast(NSLocalizedString("SET_PROFILE_VIDEO_FAILED", comment: ""))
        taskFileMap.removeValueForKey(taskIdentifier)
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
        alert.addAction(UIAlertAction(title:NSLocalizedString("USE_DEFAULT_VIDEO", comment: "Use Default Video"), style: .Destructive) { _ in
            self.useDefaultVideo()
            })
        alert.addAction(UIAlertAction(title:NSLocalizedString("CANCEL",comment:""), style: .Cancel){ _ in})
        presentViewController(alert, animated: true, completion: nil)
    }
    
    private func useDefaultVideo()
    {
        ServiceContainer.getService(UserService).setMyProfileVideo("")
        self.profileVideoView.filePath = FilmAssetsConstants.SharelinkFilm
    }
    
    private func recordVideo()
    {
        if let qpController = QuPaiRecordCamera().getQuPaiController(self)
        {
            self.presentViewController(qpController, animated: true, completion: nil)
        }
    }
    
    func qupaiSDK(sdk: ALBBQuPaiPluginPluginServiceProtocol!, compeleteVideoPath videoPath: String!, thumbnailPath: String!) {
        self.dismissViewControllerAnimated(false, completion: nil)
        if videoPath == nil
        {
            return
        }
        let fileService = ServiceContainer.getService(FileService)
        let newFilePath = fileService.createLocalStoreFileName(FileType.Video)
        if fileService.moveFileTo(videoPath, destinationPath: newFilePath)
        {
            profileVideoView.fileFetcher = fileService.getFileFetcherOfFilePath(FileType.Video)
            profileVideoView.filePath = newFilePath
            self.showToast( NSLocalizedString("VIDEO_SAVED", comment: ""))
            saveProfileVideo()
        }else
        {
            self.showToast( NSLocalizedString("SAVE_VIDEO_FAILED",comment:""))
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
        if String.isNullOrWhiteSpace(userProfileModel.personalVideoId)
        {
            profileVideoView.filePath = FilmAssetsConstants.SharelinkFilm
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
            self.makeToastActivityWithMessage("",message:NSLocalizedString("UPDATING", comment: ""))
            if SharelinkerCenterNoteName == newValue
            {
                let alert = UIAlertController(title: NSLocalizedString("INVALID_VALUE", comment: "Invalid Value"), message: NSLocalizedString("USE_ANOTHER_VALUE", comment: "Use another value please!"), preferredStyle: UIAlertControllerStyle.Alert)
                alert.addAction(UIAlertAction(title: NSLocalizedString("I_SEE",comment:""), style: UIAlertActionStyle.Cancel ,handler:nil))
                self.presentViewController(alert, animated: true, completion: nil)
                return
            }
            userService.setLinkerNoteName(userProfileModel.userId, newNoteName: newValue){ isSuc,msg in
                self.hideToastActivity()
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
