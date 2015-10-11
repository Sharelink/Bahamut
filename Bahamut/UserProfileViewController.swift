//
//  UserProfileViewController.swift
//  Bahamut
//
//  Created by AlexChow on 15/8/15.
//  Copyright © 2015年 GStudio. All rights reserved.
//

import UIKit


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
    
    @IBOutlet weak var headIconImageView: UIImageView!{
        didSet{
            headIconImageView.layer.cornerRadius = 3
            headIconImageView.userInteractionEnabled = true
        }
    }
    @IBOutlet weak var userSignTextView: UILabel!{
        didSet{
            userSignTextView.userInteractionEnabled = true
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
        tagService.addSharelinkTag(newTag) { () -> Void in
            
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
        headIconImageView.addGestureRecognizer(UITapGestureRecognizer(target: self, action: "headIconTapped:"))
    }
    
    func saveProfileVideo()
    {
        let fService = ServiceContainer.getService(FileService)
        fService.requestFileId(profileVideoView.filePath, type: FileType.Video, callback: { (fileId) -> Void in
            self.view.hideToastActivity()
            if fileId != nil
            {
                fService.startSendFile(fileId)
                let uService = ServiceContainer.getService(UserService)
                uService.setUserProfileVideo(fileId, setProfileCallback: { (isSuc, msg) -> Void in
                    if isSuc
                    {
                        self.userProfileModel.personalVideoId = fileId
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
        userSignTextView.text = userProfileModel.signText
        updateHeadIcon()
        updatePersonalFilm()
    }
    
    func updateName()
    {
        self.navigationItem.title = userProfileModel.nickName
        userNickNameLabelView.text = userProfileModel.noteName ?? userProfileModel.nickName
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
    
    func updateHeadIcon()
    {
        fileService.setHeadIcon(headIconImageView, iconFileId: userProfileModel.headIconId)
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
    
    func headIconTapped(_:UITapGestureRecognizer)
    {
        let imageFileFetcher = ServiceContainer.getService(FileService).getFileFetcherOfFileId(FileType.Image)
        UIImagePlayerController.showImagePlayer(self, imageUrls: ["defaultView"],imageFileFetcher: imageFileFetcher)
    }
    
    func editPropertySave(propertyId: String!, newValue: String!)
    {
        let userService = ServiceContainer.getService(UserService)
        if propertyId == "note"
        {
            self.view.makeToastActivityWithMessage(message: "Updating")
            userService.setUserNoteName(userProfileModel.userId, newNoteName: newValue){ isSuc,msg in
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
