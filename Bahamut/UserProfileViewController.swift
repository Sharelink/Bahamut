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
    
    func showUserProfileViewController(currentNavigationController:UINavigationController,userProfile:Sharelinker)
    {
        let controller = UserProfileViewController.instanceFromStoryBoard()
        controller.userProfileModel = userProfile
        currentNavigationController.pushViewController(controller , animated: true)
    }

}
//MARK: extension SharelinkThemeService
extension SharelinkThemeService
{
    func showConfirmAddThemeAlert(currentViewController:UIViewController,theme:SharelinkTheme)
    {
        let alert = UIAlertController(title: "FOCUS".localizedString() , message: String(format: "CONFIRM_FOCUS_THEME".localizedString(), theme.getShowName()), preferredStyle: UIAlertControllerStyle.Alert)
        alert.addAction(UIAlertAction(title: "YES".localizedString(), style: .Default){ _ in
            self.addThisThemeToMyFocus(currentViewController,theme: theme)
            })
        alert.addAction(UIAlertAction(title: "UMMM".localizedString(), style: .Cancel){ _ in
            })
        currentViewController.presentViewController(alert, animated: true, completion: nil)
    }
    
    func addThisThemeToMyFocus(currentViewController:UIViewController,theme:SharelinkTheme,callback:((Bool)->Void)! = nil)
    {
        if self.isThemeExists(theme.data)
        {
            let alert = UIAlertController(title: nil, message: "SAME_THEME_EXISTS".localizedString(), preferredStyle: .Alert)
            alert.addAction(UIAlertAction(title: "I_SEE".localizedString(), style: .Cancel, handler: nil))
            currentViewController.presentViewController(alert, animated: true, completion: nil)
            return
        }
        
        let newTag = SharelinkTheme()
        newTag.tagName = theme.tagName
        newTag.tagColor = theme.tagColor
        newTag.isFocus = "true"
        newTag.type = theme.type
        newTag.showToLinkers = "true"
        newTag.data = theme.data
        self.addSharelinkTheme(newTag) { (suc) -> Void in
            let alerttitle = suc ? "FOCUS_THEME_SUCCESS".localizedString() : "FOCUS_THEME_ERROR".localizedString()
            let alert = UIAlertController(title:alerttitle , message: nil, preferredStyle: UIAlertControllerStyle.Alert)
            alert.addAction(UIAlertAction(title: "I_SEE".localizedString(), style: .Cancel){ _ in
                })
            currentViewController.presentViewController(alert, animated: true, completion: nil)
            if let handler = callback
            {
                handler(suc)
            }
        }
        
    }
}

//MARK:UserProfileViewController
class UserProfileViewController: UIViewController,UIEditTextPropertyViewControllerDelegate,QupaiSDKDelegate,UIResourceExplorerDelegate,ThemeCollectionViewControllerDelegate,ProgressTaskDelegate
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
    
    let fileService = {
        return ServiceContainer.getService(FileService)
    }()
    var userProfileModel:Sharelinker!
    var isMyProfile:Bool{
        return userProfileModel.userId == ServiceContainer.getService(UserService).myUserId
    }
    
    //MARK: init
    override func viewDidLoad() {
        super.viewDidLoad()
        initProfileVideoView()
        initThemes()
    }
    
    private func initThemes()
    {
        
        self.themes = ServiceContainer.getService(SharelinkThemeService).getUserTheme(userProfileModel.userId){ result in
            self.themes = result
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
    var focusThemeController:ThemeCollectionViewController!{
        didSet{
            self.addChildViewController(focusThemeController)
            focusThemeController.delegate = self
        }
    }
    
    func themeCellDidClick(sender: ThemeCollectionViewController, cell: ThemeCollectionCell, indexPath: NSIndexPath) {
        if isMyProfile
        {
            return
        }
        if sender == focusThemeController
        {
            ServiceContainer.getService(SharelinkThemeService).showConfirmAddThemeAlert(self,theme: sender.themes[indexPath.row])
        }
    }
    
    //TODO: add RefreshThemes functions
    private var refreshThemesButton:UIButton!
    private var refreshingIndicator:UIActivityIndicatorView!
    
    private func initRefreshThemes()
    {
        refreshingIndicator = UIActivityIndicatorView()
        refreshingIndicator.center = focusThemeViewContainer.center
        refreshThemesButton = UIButton(type: .InfoDark)
        refreshThemesButton.center = focusThemeViewContainer.center
    }
    
    @IBOutlet weak var focusThemeViewContainer: UIView!{
        didSet{
            
            focusThemeViewContainer.layer.cornerRadius = 7
            focusThemeController = ThemeCollectionViewController.instanceFromStoryBoard()
            focusThemeViewContainer.addSubview(focusThemeController.view)
            
        }
    }

    
    //MARK: personal video
    
    private var taskFileMap = [String:FileAccessInfo]()
    
    func saveProfileVideo()
    {
        let fService = ServiceContainer.getService(FileService)
        fService.sendFileToAliOSS(profileVideoView.filePath, type: FileType.Video) { (taskId, fileKey) -> Void in
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
                    self.playToast("SET_PROFILE_VIDEO_SUC".localizedString())
                }
            })
        }
        
    }
    
    func taskFailed(taskIdentifier: String, result: AnyObject!) {
        self.playToast("SET_PROFILE_VIDEO_FAILED".localizedString())
        taskFileMap.removeValueForKey(taskIdentifier)
    }
    
    @IBAction func editProfileVideo()
    {
        showEditProfileVideoActionSheet()
    }
    
    private func showEditProfileVideoActionSheet()
    {
        let alert = UIAlertController(title:"CHANGE_PROFILE_VIDEO".localizedString() , message: nil, preferredStyle: .ActionSheet)
        alert.addAction(UIAlertAction(title:"REC_NEW_VIDEO".localizedString() , style: .Destructive) { _ in
            self.recordVideo()
            })
        alert.addAction(UIAlertAction(title:"SELECT_VIDEO".localizedString(), style: .Destructive) { _ in
            self.seleteVideo()
            })
        alert.addAction(UIAlertAction(title:"USE_DEFAULT_VIDEO".localizedString(), style: .Destructive) { _ in
            self.useDefaultVideo()
            })
        alert.addAction(UIAlertAction(title:"CANCEL".localizedString(), style: .Cancel){ _ in})
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
    
    #if APP_VERSION
    func qupaiSDK(sdk: ALBBQuPaiPluginPluginServiceProtocol!, compeleteVideoPath videoPath: String!, thumbnailPath: String!) {
        self.dismissViewControllerAnimated(false, completion: nil)
        if videoPath == nil
        {
            return
        }
        let fileService = ServiceContainer.getService(FileService)
        let newFilePath = fileService.createLocalStoreFileName(FileType.Video)
        if PersistentFileHelper.moveFile(videoPath, destinationPath: newFilePath)
        {
            profileVideoView.fileFetcher = fileService.getFileFetcherOfFilePath(FileType.Video)
            profileVideoView.filePath = newFilePath
            self.playToast( "VIDEO_SAVED".localizedString())
            saveProfileVideo()
        }else
        {
            self.playToast( "SAVE_VIDEO_FAILED".localizedString())
        }
    }
    #endif
    
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
        if isMyProfile && UserSetting.isAppstoreReviewing == false
        {
            editProfileVideoButton.hidden = false
        }else
        {
            editProfileVideoButton.hidden = true
        }
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
        profileVideoView.fileFetcher = fileService.getFileFetcherOfFileId(FileType.Video)
        if String.isNullOrWhiteSpace(userProfileModel.personalVideoId)
        {
            profileVideoView.fileFetcher = fileService.getFileFetcherOfFilePath(.Video)
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
    
    //MARK: user theme
    var themes:[SharelinkTheme]!{
        didSet{
            self.focusThemeController.themes = self.themes
        }
    }
    
    @IBAction func editNoteName()
    {
        let propertySet = UIEditTextPropertySet()
        propertySet.propertyIdentifier = "note"
        propertySet.propertyValue = userProfileModel.noteName
        propertySet.propertyLabel = "NOTE_NAME".localizedString()
        UIEditTextPropertyViewController.showEditPropertyViewController(self.navigationController!,propertySet:propertySet, controllerTitle: "NOTE_NAME".localizedString(), delegate: self)
    }
    
    func editPropertySave(propertyId: String!, newValue: String!)
    {
        let userService = ServiceContainer.getService(UserService)
        if propertyId == "note"
        {
            let hud = self.showActivityHudWithMessage("",message:"UPDATING".localizedString())
            if SharelinkerCenterNoteName == newValue
            {
                let alert = UIAlertController(title: "INVALID_VALUE".localizedString(), message: "USE_ANOTHER_VALUE".localizedString(), preferredStyle: UIAlertControllerStyle.Alert)
                alert.addAction(UIAlertAction(title: "I_SEE".localizedString(), style: UIAlertActionStyle.Cancel ,handler:nil))
                self.presentViewController(alert, animated: true, completion: nil)
                return
            }
            userService.setLinkerNoteName(userProfileModel.userId, newNoteName: newValue){ isSuc,msg in
                hud.hideAsync(true)
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
        return instanceFromStoryBoard("UserAccount", identifier: "userProfileViewController",bundle: Sharelink.mainBundle()) as! UserProfileViewController
    }
}
