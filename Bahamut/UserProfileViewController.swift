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
        let controller = UIStoryboard(name: "Main", bundle: NSBundle.mainBundle()).instantiateViewControllerWithIdentifier("userProfileViewController") as! UserProfileViewController
        let userProfile = self.getUser(userId)
        controller.userProfileModel = userProfile
        controller.userTags = self.getLinkedUserAllTags(userId)
        currentNavigationController.pushViewController(controller , animated: true)
    }
}

class UserProfileViewController: UIViewController,UICollectionViewDataSource,UICollectionViewDelegate,UICollectionViewDelegateFlowLayout,UIResourceExplorerDelegate
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
    
    func collectionView(collectionView: UICollectionView, cellForItemAtIndexPath indexPath: NSIndexPath) -> UICollectionViewCell {
        let identifier: String = "UserTagCell"
        let cell = collectionView.dequeueReusableCellWithReuseIdentifier(identifier, forIndexPath: indexPath) as! UserTagCell
        cell.model = userTags[indexPath.row]
        return cell
    }
    
    func collectionView(collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, sizeForItemAtIndexPath indexPath: NSIndexPath) -> CGSize {
        let identifier: String = "UserTagCell"
        let cell = collectionView.dequeueReusableCellWithReuseIdentifier(identifier, forIndexPath: indexPath) as! UserTagCell
        return CGSizeMake(cell.tagNameLabel.bounds.width, cell.tagNameLabel.bounds.height)
    }
    
    func selectUserTag(_:UITapGestureRecognizer)
    {
        let userService = ServiceContainer.getService(UserService)
        userService.showTagCollectionControllerView(self.navigationController!, tags: userService.getUserTagsResourceItemModels(self.userTags), selectionMode: .Multiple, delegate: self)
    }
    
}
