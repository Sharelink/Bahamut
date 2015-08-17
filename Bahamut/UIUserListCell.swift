//
//  UIUser.swift
//  Bahamut
//
//  Created by AlexChow on 15/8/8.
//  Copyright (c) 2015年 GStudio. All rights reserved.
//

import UIKit

class UIUserListCell: UITableViewCell,UICollectionViewDelegateFlowLayout,UICollectionViewDelegate,UICollectionViewDataSource
{
    var userModel:ShareLinkUser!{
        didSet{
            update()
        }
    }
    
    var userTags:[UserTag]!{
        didSet{
            if userTagCollectionView != nil
            {
                userTagCollectionView.reloadData()
            }
        }
    }
    
    var rootController:UIViewController!
    @IBOutlet weak var headIconImageView: UIImageView!{
        didSet{
            headIconImageView.userInteractionEnabled = true
            headIconImageView.addGestureRecognizer(UITapGestureRecognizer(target: self, action: "showHeadIcon:"))
        }
    }
    @IBOutlet weak var userNickTextField: UILabel!{
        didSet{
            userNickTextField.userInteractionEnabled = true
            userNickTextField.addGestureRecognizer(UITapGestureRecognizer(target: self, action: "showProfile:"))
        }
    }
    @IBOutlet weak var userTagCollectionView: UICollectionView!
    
    func showProfile(_:UIGestureRecognizer)
    {
        ServiceContainer.getService(UserService).showUserProfileViewController(rootController.navigationController!, userId: userModel.userId)
    }
    
    func showHeadIcon(_:UIGestureRecognizer)
    {
        print("show head icon")
    }
    
    func update()
    {
        userNickTextField.text = userModel.noteName ?? userModel.nickName
        ServiceContainer.getService(FileService).getFile(userModel.headIconId, returnCallback: { (filePath) -> Void in
            self.headIconImageView.image = PersistentManager.sharedInstance.getImage(self.userModel.headIconId, filePath: filePath)
        })
        userTagCollectionView.reloadData()
    }
    
    //MARK user tag
    func collectionView(collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, sizeForItemAtIndexPath indexPath: NSIndexPath) -> CGSize {
        
        return CGSizeMake(20, 20)
    }
    
    func collectionView(collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        return userTags?.count ?? 0
    }
    
    func collectionView(collectionView: UICollectionView, cellForItemAtIndexPath indexPath: NSIndexPath) -> UICollectionViewCell {
        let identifier: String = "UserTagCell"
        let cell = collectionView.dequeueReusableCellWithReuseIdentifier(identifier, forIndexPath: indexPath)
        cell.backgroundColor = UIColor(CIColor: CIColor(string: userTags[indexPath.row].tagColor))
        return cell
    }

}