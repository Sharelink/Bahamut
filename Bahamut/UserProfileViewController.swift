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
        let userProfile = self.getUser(userId)
        let tags = self.getAUsersTags(userId)
        showUserProfileViewController(currentNavigationController, userProfile: userProfile!, tags: tags)
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
            tagCollectionView.addGestureRecognizer(UITapGestureRecognizer(target: self, action: "selectUserTag:"))
            tagCollectionView.reloadData()
        }
    }
    @IBOutlet weak var userProfileVideo: ShareLinkFilmView!
    @IBOutlet weak var headIconImageView: UIImageView!
    @IBOutlet weak var userSignTextView: UILabel!
    @IBOutlet weak var userNickNameLabelView: UILabel!
    var userProfileModel:ShareLinkUser!
    override func viewDidLoad() {
        super.viewDidLoad()
        tagCollectionView.autoresizesSubviews = true
    }
    
    override func viewWillAppear(animated: Bool) {
        super.viewWillAppear(animated)
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
        let allTags = userService.getMyAllTags()
        let setAllTags = Set<SharelinkTag>(allTags)
        let notSeletedTags = setAllTags.subtract(tags).map{return $0}
        let seletedTagModels = userService.getUserTagsResourceItemModels(tags,selected: true) as! [UISharelinkTagItemModel]
        let notSeletedTagModels = userService.getUserTagsResourceItemModels(notSeletedTags) as! [UISharelinkTagItemModel]
        userService.showTagCollectionControllerView(self.navigationController!, tags: seletedTagModels + notSeletedTagModels, selectionMode: ResourceExplorerSelectMode.Multiple){ tagsSelected in
            let newSelected = Set<UISharelinkTagItemModel>(tagsSelected)
            let oldSelected = Set<UISharelinkTagItemModel>(seletedTagModels)
            let willAddTags = newSelected.subtract(seletedTagModels).map({ (model) -> UserTag in
                let ut = UserTag()
                ut.userId = self.userProfileModel.userId
                ut.tagId = model.tagModel.tagId
                return ut
            })
            let willRemovetags = oldSelected.subtract(newSelected).map({ (model) -> UserTag in
                let ut = UserTag()
                ut.userId = self.userProfileModel.userId
                ut.tagId = model.tagModel.tagId
                return ut
            })
            userService.updateUserTags(self.userProfileModel.userId, willAddTags: willAddTags, willRemoveTags: willRemovetags){
                self.tags = tagsSelected.map{return $0.tagModel}
            }
        }
    }
    
}
