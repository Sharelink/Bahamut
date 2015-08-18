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
        let userTags = self.getLinkedUserAllTags(userId)
        showUserProfileViewController(currentNavigationController, userProfile: userProfile!, userTags: userTags)
    }
    
    func showUserProfileViewController(currentNavigationController:UINavigationController,userProfile:ShareLinkUser,userTags:[UserTag])
    {
        let controller = UIStoryboard(name: "Main", bundle: NSBundle.mainBundle()).instantiateViewControllerWithIdentifier("userProfileViewController") as! UserProfileViewController
        controller.userProfileModel = userProfile
        controller.userTags = userTags
        currentNavigationController.pushViewController(controller , animated: true)
    }
}

class UserProfileViewController: UIViewController,UICollectionViewDataSource,UICollectionViewDelegate,UICollectionViewDelegateFlowLayout
{
    @IBOutlet weak var userTagCollectionView: UICollectionView!{
        didSet{
            userTagCollectionView.dataSource = self
            userTagCollectionView.delegate = self
            userTagCollectionView.addGestureRecognizer(UITapGestureRecognizer(target: self, action: "selectUserTag:"))
            userTagCollectionView.reloadData()
        }
    }
    @IBOutlet weak var userProfileVideo: ShareLinkFilmView!
    @IBOutlet weak var headIconImageView: UIImageView!
    @IBOutlet weak var userSignTextView: UILabel!
    @IBOutlet weak var userNickNameLabelView: UILabel!
    var userProfileModel:ShareLinkUser!
    override func viewDidLoad() {
        super.viewDidLoad()
        userTagCollectionView.autoresizesSubviews = true
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
        userTagCollectionView.reloadData()
    }
    
    //MARK: user tag
    var userTags:[UserTag]!{
        didSet{
            if userTagCollectionView != nil
            {
                userTagCollectionView.reloadData()
            }
        }
    }
    func collectionView(collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        return userTags?.count ?? 0
    }
    
    func collectionView(collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, minimumInteritemSpacingForSectionAtIndex section: Int) -> CGFloat {
        return CGFloat(4)
    }
    
    func collectionView(collectionView: UICollectionView, cellForItemAtIndexPath indexPath: NSIndexPath) -> UICollectionViewCell {
        let identifier: String = "UserTagCell"
        let cell = collectionView.dequeueReusableCellWithReuseIdentifier(identifier, forIndexPath: indexPath) as! UserTagCell
        cell.model = userTags[indexPath.row]
        return cell
    }
    
    func selectUserTag(_:UITapGestureRecognizer)
    {
        let userService = ServiceContainer.getService(UserService)
        let tags = userService.getMyAllUserTags()
        let tagsModels = userService.getUserTagsResourceItemModels(tags) as! [UserTagModel]
        for model in tagsModels
        {
            model.selected = false
            for eModel in self.userTags
            {
                if eModel.tagId == model.tagModel.tagId
                {
                    model.selected = true
                    break
                }
            }
        }
        userService.showTagCollectionControllerView(self.navigationController!, tags: tagsModels, selectionMode: ResourceExplorerSelectMode.Multiple){ tagsSelected in
            let result = tagsSelected.map{ tag -> UserTag in
                return tag.tagModel
            }
            let oldTags = Set<UserTag>(self.userTags)
            let newTags = Set<UserTag>(result)
            let willRemoveTags = oldTags.subtract(newTags).map{ rTag -> UserTag in
                if rTag.tagUserIds != nil
                {
                    rTag.tagUserIds = rTag.tagUserIds.filter{$0 != self.userProfileModel.userId}
                }
                return rTag
            }
            let willAddTags = newTags.subtract(oldTags).map{ rTag -> UserTag in
                if rTag.tagUserIds == nil
                {
                    rTag.tagUserIds = [String]()
                }
                rTag.tagUserIds.append(self.userProfileModel.userId)
                return rTag
            }
            userService.updateUserTags(self.userProfileModel.userId, willAddTags: willAddTags, willRemoveTags: willRemoveTags){
                self.userTags = result
            }
        }
    }
    
}
