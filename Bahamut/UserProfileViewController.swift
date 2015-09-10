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

class UserProfileViewController: UIViewController,UICollectionViewDataSource,UICollectionViewDelegate,UICollectionViewDelegateFlowLayout,UIEditTextPropertyViewControllerDelegate
{
    @IBOutlet weak var tagCollectionView: UICollectionView!{
        didSet{
            tagCollectionView.dataSource = self
            tagCollectionView.delegate = self
            tagCollectionView.autoresizesSubviews = true
            tagCollectionView.reloadData()
        }
    }
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
    
    func bindTapActions()
    {
        if isMyProfile
        {
            tagCollectionView.addGestureRecognizer(UITapGestureRecognizer(target: self, action: "selectUserTag:"))
            userNickNameLabelView.addGestureRecognizer(UITapGestureRecognizer(target: self, action: "editNickName:"))
            userSignTextView.addGestureRecognizer(UITapGestureRecognizer(target: self, action: "editSignText:"))
        }
        headIconImageView.addGestureRecognizer(UITapGestureRecognizer(target: self, action: "headIconTapped:"))
    }
    
    @IBAction func editProfileVideo()
    {
        
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
        tagCollectionView.reloadData()
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
            if tagCollectionView != nil
            {
                tagCollectionView.reloadData()
            }
        }
    }
    func collectionView(collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        return tags?.count ?? 0
    }
    
    func collectionView(collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, minimumInteritemSpacingForSectionAtIndex section: Int) -> CGFloat {
        return CGFloat(4)
    }
    
    func collectionView(collectionView: UICollectionView, cellForItemAtIndexPath indexPath: NSIndexPath) -> UICollectionViewCell {
        let identifier: String = "UserTagCell"
        let cell = collectionView.dequeueReusableCellWithReuseIdentifier(identifier, forIndexPath: indexPath) as! UserTagCell
        cell.model = tags[indexPath.row]
        return cell
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
