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
    func showUserProfileViewController(currentNavigationController:UINavigationController,userId:String,userTags:[SharelinkTag])
    {
        if let userProfile = self.getUser(userId)
        {
            showUserProfileViewController(currentNavigationController, userProfile: userProfile, tags: userTags)
        }
    }
    
    func showUserProfileViewController(currentNavigationController:UINavigationController,userProfile:ShareLinkUser,tags:[SharelinkTag])
    {
        let controller = UserProfileViewController.instanceFromStoryBoard()
        controller.userProfileModel = userProfile
        controller.tags = tags
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
            profileVideoView.fileFetcher = ServiceContainer.getService(FileService).getFileFetcher(FileType.Video)
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
        
    }
    
    private func initProfileVideoView()
    {
        if profileVideoView == nil
        {
            profileVideoView = ShareLinkFilmView(frame: profileVideoViewContainer.bounds)
            updatePersonalFilm()
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
        if sender == focusTagController
        {
            showConfirmAddTagAlert(sender.tags[indexPath.row])
        }
    }
    
    func showConfirmAddTagAlert(tag:UITagCellModel)
    {
        let alert = UIAlertController(title: "I'm interest in \(tag.tagName)", message: "Are your sure to focus this tag?", preferredStyle: UIAlertControllerStyle.Alert)
        alert.addAction(UIAlertAction(title: "Yes!", style: .Default){ _ in
            self.addThisTapToMyFocus(tag)
        })
        alert.addAction(UIAlertAction(title: "Ummm!", style: .Cancel){ _ in
            self.cancelAddTap(tag)
        })
    }
    
    func cancelAddTap(tag:UITagCellModel)
    {
        
    }
    
    func addThisTapToMyFocus(tag:UITagCellModel)
    {
        
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
        if isMyProfile
        {
            userNickNameLabelView.addGestureRecognizer(UITapGestureRecognizer(target: self, action: "editNickName:"))
            userSignTextView.addGestureRecognizer(UITapGestureRecognizer(target: self, action: "editSignText:"))
        }
        headIconImageView.addGestureRecognizer(UITapGestureRecognizer(target: self, action: "headIconTapped:"))
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
        let newFilePath = fileService.createLocalStoreFileName(FileType.Video) + ".mp4"
        if fileService.moveFileTo(destination, destinationPath: newFilePath)
        {
            profileVideoView.filePath = newFilePath
            self.view.makeToast(message: "Video Saved")
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
    
    func resourceExplorerItemSelected(itemModel: UIResrouceItemModel, index: Int, sender: UIResourceExplorerController!) {
        let fileModel = itemModel as! UIFileCollectionCellModel
        profileVideoView.filePath = fileModel.filePath
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
        userNickNameLabelView.text = userProfileModel.noteName ?? userProfileModel.nickName
        userSignTextView.text = userProfileModel.signText
        updateHeadIcon()
        updatePersonalFilm()
    }
    
    func updatePersonalFilm()
    {
        if profileVideoView == nil
        {
            return
        }
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
        }
    }
    
    func editNickName(_:UITapGestureRecognizer)
    {
        UIEditTextPropertyViewController.showEditPropertyViewController(self.navigationController!, propertyIdentifier: "nick", propertyValue: self.userProfileModel.nickName, propertyLabel: "NickName", title: "Nick", delegate: self)
    }
    
    func editSignText(_:UITapGestureRecognizer)
    {
        UIEditTextPropertyViewController.showEditPropertyViewController(self.navigationController!, propertyIdentifier: "signtext", propertyValue: self.userProfileModel.signText, propertyLabel: "Sign Text", title: "Sign Text", delegate: self)
    }
    
    func headIconTapped(_:UITapGestureRecognizer)
    {
        let imageFileFetcher = ServiceContainer.getService(FileService).getFileFetcher(FileType.Image)
        UIImagePlayerController.showImagePlayer(self, imageUrls: ["defaultView"],imageFileFetcher: imageFileFetcher)
    }
    
    func editPropertySave(propertyId: String!, newValue: String!)
    {
        let userService = ServiceContainer.getService(UserService)
        if propertyId == "signtext"
        {
            self.view.makeToastActivityWithMessage(message: "Updating")
            userService.setProfileNick(newValue, setProfileCallback: { (isSuc, msg) -> Void in
                self.view.hideToastActivity()
            })
        }else if propertyId == "nick"
        {
            self.view.makeToastActivityWithMessage(message: "Updating")
            userService.setProfileNick(newValue, setProfileCallback: { (isSuc, msg) -> Void in
                self.view.hideToastActivity()
            })
        }
    }
    
    func selectUserTag(_:UITapGestureRecognizer)
    {
        let userService = ServiceContainer.getService(UserService)
        let userTagService = ServiceContainer.getService(UserTagService)
        let allTags = userTagService.getMyAllTags()
        let setAllTags = Set<SharelinkTag>(allTags)
        let notSeletedTags = setAllTags.subtract(tags).map{return $0}
        let seletedTagModels = userService.getUserTagsResourceItemModels(tags,selected: true) as! [UISharelinkTagItemModel]
        let notSeletedTagModels = userService.getUserTagsResourceItemModels(notSeletedTags) as! [UISharelinkTagItemModel]
        userService.showTagCollectionControllerView(self.navigationController!, tags: seletedTagModels + notSeletedTagModels, selectionMode: ResourceExplorerSelectMode.Negative)
    }
    
    static func instanceFromStoryBoard() -> UserProfileViewController
    {
        return instanceFromStoryBoard("UserAccount", identifier: "userProfileViewController") as! UserProfileViewController
    }
}
