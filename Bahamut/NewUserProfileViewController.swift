//
//  ProfileViewController.swift
//  Bahamut
//
//  Created by AlexChow on 15/7/28.
//  Copyright (c) 2015年 GStudio. All rights reserved.
//

import UIKit

extension UserService
{
    
    func showRegistNewUserController(navigationController:UINavigationController,registModel:RegistModel)
    {
        let profileViewController = NewUserProfileViewController.instanceFromStoryBoard()
        profileViewController.registModel = registModel
        profileViewController.model = ShareLinkUser()
        navigationController.pushViewController(profileViewController, animated: true)
    }
}

class RegistModel {
    var registUserServer:String!
    var accountId:String!
    var accessToken:String!
}

class NewUserProfileViewController: UIViewController,UIImagePickerControllerDelegate,UINavigationControllerDelegate
{
    var registModel:RegistModel!
    var model:ShareLinkUser!
    @IBOutlet weak var nickNameTextfield: UITextField!
    @IBOutlet weak var signText: UITextField!

    @IBOutlet weak var headIconImage: UIImageView!{
        didSet{
            headIconImage.addGestureRecognizer(UITapGestureRecognizer(target: self, action: "takeHeadIconPhoto:"))
        }
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        changeNavigationBarColor()
    }
    
    override func viewWillAppear(animated: Bool) {
        super.viewWillAppear(animated)
        update()
    }
    
    func update()
    {
        let fService = ServiceContainer.getService(FileService)
        fService.setHeadIcon(headIconImage, iconFileId: model.headIconId)
    }
    
    @IBAction func saveProfile()
    {
        model.nickName = nickNameTextfield.text
        model.signText = signText.text
        ServiceContainer.getService(UserService).registNewUser(self.registModel, newUser: model){ isSuc,msg,validateResult in
            if isSuc
            {
                ServiceContainer.getService(AccountService).setLogined(validateResult.UserId, token: validateResult.AppToken, shareLinkApiServer: validateResult.APIServer, fileApiServer: validateResult.FileAPIServer)
                MainNavigationController.start("Regist Success")
            }else
            {
                self.view.makeToast(message: msg)
            }
        }
    }
    
    private var imagePickerController:UIImagePickerController! = UIImagePickerController()
        {
        didSet{
            imagePickerController.delegate = self
        }
    }
    func takeHeadIconPhoto(_:UIGestureRecognizer)
    {
        let alert = UIAlertController(title: "Change HeadIcon", message: nil, preferredStyle: .ActionSheet)
        alert.addAction(UIAlertAction(title: "Take A Photo", style: .Destructive) { _ in
            self.takePhoto()
            })
        alert.addAction(UIAlertAction(title: "Select A Photo From Album", style: .Destructive) { _ in
            self.selectPhoto()
            })
        alert.addAction(UIAlertAction(title: "Cancel", style: .Cancel){ _ in})
        presentViewController(alert, animated: true, completion: nil)
    }
    
    func takePhoto()
    {
        imagePickerController.sourceType = .Camera
        imagePickerController.allowsEditing = true
        self.presentViewController(imagePickerController, animated: true, completion: nil)
    }
    
    func imagePickerController(picker: UIImagePickerController, didFinishPickingImage image: UIImage, editingInfo: [String : AnyObject]?)
    {
        imagePickerController.dismissViewControllerAnimated(true)
            {
                if self.headIconImage != nil
                {
                    self.headIconImage.image = image
                    let fService = ServiceContainer.getService(FileService)
                    let imageData = UIImageJPEGRepresentation(image, 1)
                    let localPath = fService.createLocalStoreFileName(FileType.Image)
                    PersistentManager.sharedInstance.storeFile(imageData!, filePath: localPath)
                    fService.requestFileId(localPath, type: FileType.Image, callback: { (fileId) -> Void in
                        fService.startSendFile(fileId)
                        let uService = ServiceContainer.getService(UserService)
                        uService.setUserHeadIcon(fileId, setProfileCallback: { (isSuc, msg) -> Void in
                            if isSuc
                            {
                                let myInfo = uService.myUserModel
                                myInfo.headIconId = fileId
                                myInfo.saveModel()
                                self.headIconImage.image = PersistentManager.sharedInstance.getImage(fileId)
                            }else
                            {
                                self.view.makeToast(message: "Set Head Icon failed")
                            }
                        })
                    })
                }
        }
    }
    
    func selectPhoto()
    {
        imagePickerController.sourceType = .PhotoLibrary
        imagePickerController.allowsEditing = true
        imagePickerController.delegate = self
        self.presentViewController(imagePickerController, animated: true, completion: nil)
    }
    
    static func instanceFromStoryBoard()->NewUserProfileViewController{
        return instanceFromStoryBoard("UserAccount", identifier: "NewUserProfileViewController") as! NewUserProfileViewController
    }
}
