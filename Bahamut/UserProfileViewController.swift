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
        let userProfile = self.getUser(userId)
        showUserProfileViewController(currentNavigationController, userProfile: userProfile!, tags: userTags)
    }
    
    func showUserProfileViewController(currentNavigationController:UINavigationController,userProfile:ShareLinkUser,tags:[SharelinkTag])
    {
        let controller = UIStoryboard(name: "Main", bundle: NSBundle.mainBundle()).instantiateViewControllerWithIdentifier("userProfileViewController") as! UserProfileViewController
        controller.userProfileModel = userProfile
        controller.tags = tags
        currentNavigationController.pushViewController(controller , animated: true)
    }
}

class UserProfileViewController: UIViewController,UICollectionViewDataSource,UICollectionViewDelegate,UICollectionViewDelegateFlowLayout
{
    @IBOutlet weak var tagCollectionView: UICollectionView!{
        didSet{
            tagCollectionView.dataSource = self
            tagCollectionView.delegate = self
            tagCollectionView.reloadData()
        }
    }
    @IBOutlet weak var userProfileVideo: ShareLinkFilmView!
    @IBOutlet weak var headIconImageView: UIImageView!
    @IBOutlet weak var userSignTextView: UILabel!
    @IBOutlet weak var userNickNameLabelView: UILabel!
    var userProfileModel:ShareLinkUser!
    var isMyProfile:Bool{
        return userProfileModel.userId == ServiceContainer.getService(UserService).myUserId
    }
    override func viewDidLoad() {
        super.viewDidLoad()
        tagCollectionView.autoresizesSubviews = true
    }
    
    override func viewWillAppear(animated: Bool) {
        super.viewWillAppear(animated)
        if isMyProfile
        {
            tagCollectionView.addGestureRecognizer(UITapGestureRecognizer(target: self, action: "selectUserTag:"))
        }
        update()
    }
    
    @IBAction func editProfileVideo()
    {
        
    }
    
    func update()
    {
        userNickNameLabelView.text = userProfileModel.noteName ?? userProfileModel.nickName
        userSignTextView.text = userProfileModel.signText
        ServiceContainer.getService(FileService).getFile(userProfileModel.headIconId, returnCallback: { (filePath) -> Void in
            self.headIconImageView.image = PersistentManager.sharedInstance.getImage(self.userProfileModel.headIconId, filePath: filePath)
        })
        tagCollectionView.reloadData()
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
    
}
