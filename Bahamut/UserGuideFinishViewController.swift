//
//  UserGuideFinishViewController.swift
//  Sharelink
//
//  Created by AlexChow on 16/1/30.
//  Copyright © 2016年 GStudio. All rights reserved.
//

import Foundation
class UserGuideFinishViewController: UIViewController
{
    
    @IBOutlet weak var shareImgView: UIImageView!
    @IBOutlet weak var userProfileImgView: UIImageView!
    @IBOutlet weak var userSettingImgView: UIImageView!
    
    private var shareService:ShareService!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        shareImgView.addGestureRecognizer(UITapGestureRecognizer(target: self, action: "tapShare:"))
        shareImgView.userInteractionEnabled = true
        
        userProfileImgView.addGestureRecognizer(UITapGestureRecognizer(target: self, action: "tapProfile:"))
        userProfileImgView.userInteractionEnabled = true
        
        userSettingImgView.addGestureRecognizer(UITapGestureRecognizer(target: self, action: "tapSetting:"))
        userSettingImgView.userInteractionEnabled = true
        
        shareService = ServiceContainer.getService(ShareService)
    }
    
    override func viewWillAppear(animated: Bool) {
        self.shareService.addObserver(self, selector: "sharePosted:", name: ShareService.newSharePosted, object: nil)
        self.shareService.addObserver(self, selector: "sharePostFailed:", name: ShareService.newSharePostFailed, object: nil)
        super.viewWillAppear(animated)
    }
    
    override func viewWillDisappear(animated: Bool) {
        super.viewWillAppear(animated)
        self.shareService.removeObserver(self)
    }
    
    //MARK: new share posted notification
    func sharePosted(a:NSNotification)
    {
        self.playCheckMark("POST_SHARE_SUC".localizedString())
    }
    
    func sharePostFailed(a:NSNotification)
    {
        self.playCrossMark("POST_SHARE_FAILED".localizedString())
    }
    
    func tapShare(a:UITapGestureRecognizer)
    {
        if let view = a.view
        {
            view.animationMaxToMin(0.1, maxScale: 1.2, completion: { () -> Void in
                let shareModel = ShareThing()
                shareModel.message = "FIRST_SHARE_MESSAGE".localizedString()
                
                ServiceContainer.getService(ShareService).showNewShareController(self.navigationController!, shareModel: shareModel,isReshare:false)
            })
        }
    }
    
    func tapProfile(a:UITapGestureRecognizer)
    {
        if let view = a.view
        {
            view.animationMaxToMin(0.1, maxScale: 1.2, completion: { () -> Void in
                let userService = ServiceContainer.getService(UserService)
                userService.showUserProfileViewController(self.navigationController!, userProfile:userService.myUserModel)
            })
        }
        
    }
    
    func tapSetting(a:UITapGestureRecognizer)
    {
        if let view = a.view
        {
            view.animationMaxToMin(0.1, maxScale: 1.2, completion: { () -> Void in
                ServiceContainer.getService(UserService).showMyDetailView(self)
            })
        }
    }
    
    @IBAction func done(sender: AnyObject) {
        UserSetting.setSetting(NewUserStartGuided, enable: true)
        self.dismissViewControllerAnimated(true, completion: nil)
    }
    
}