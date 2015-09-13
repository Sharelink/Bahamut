//
//  NewShareViewController.swift
//  Bahamut
//
//  Created by AlexChow on 15/8/12.
//  Copyright (c) 2015年 GStudio. All rights reserved.
//

import UIKit

//MARK: ShareService extension
extension ShareService
{
    func showReshareViewController(currentNavigationController:UINavigationController,reShareModel:ShareThing)
    {
        let controller = NewShareViewController.instanceFromStoryBoard()
        controller.shareThingModel = ShareThing()
        controller.shareThingModel.pShareId = reShareModel.shareId
        controller.shareThingModel.shareContent = reShareModel.shareContent
        controller.shareThingModel.shareType = reShareModel.shareType
        controller.hidesBottomBarWhenPushed = true
        currentNavigationController.pushViewController(controller, animated: true)
    }
}

class NewShareViewController: UIViewController,UICameraViewControllerDelegate,UITextViewDelegate,UIResourceExplorerDelegate {

    override func viewDidLoad() {
        super.viewDidLoad()
        if shareThingModel == nil
        {
            shareThingModel = ShareThing()
        }
        lockScreen()
    }
    
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
    @IBOutlet weak var shareDescriptionTextArea: UITextView!{
        didSet{
            shareDescriptionTextArea.layer.cornerRadius = 7
            shareDescriptionTextArea.delegate = self
        }
    }
    
    @IBOutlet weak var shareContentContainer: UIShareContent!{
        didSet{
            shareContentContainer.mediaPlayer.fileFetcher = FilePathFileFetcher()
            shareContentContainer.mediaPlayer.autoLoad = true
            if let content = shareThingModel?.shareContent
            {
                shareContentContainer.model = content
            }
            
        }
    }
    
    var selectTagCollectionViewController:UITagCollectionViewController!
    @IBOutlet weak var tagCollectionViewContainer: UIView!{
        didSet{
            tagCollectionViewContainer.layer.cornerRadius = 7
            selectTagCollectionViewController  = UITagCollectionViewController.instanceFromStoryBoard()
            tagCollectionViewContainer.addSubview(selectTagCollectionViewController.view)
            self.addChildViewController(selectTagCollectionViewController)
        }
    }
    
    override func viewWillLayoutSubviews() {
        super.viewWillLayoutSubviews()
        selectTagCollectionViewController.view.frame = tagCollectionViewContainer.bounds
    }
    
    var shareThingModel:ShareThing!{
        didSet{
            if shareContentContainer != nil
            {
                shareContentContainer.model = shareThingModel.shareContent
            }
        }
    }
    
    
    func textViewDidChange(textView: UITextView) {
        shareThingModel.title = textView.text
    }
    
    func resourceExplorerItemSelected(itemModel: UIResrouceItemModel, index: Int, sender: UIResourceExplorerController!) {
        let fileModel = itemModel as! UIFileCollectionCellModel
        shareThingModel.shareContent = fileModel.filePath
        self.shareContentContainer.model = shareThingModel.shareContent
    }
    
    func resourceExplorerOpenItem(itemModel: UIResrouceItemModel, sender: UIResourceExplorerController!) {
        let fileModel = itemModel as! UIFileCollectionCellModel
        ShareLinkFilmView.showPlayer(sender, uri: fileModel.filePath, fileFetcer: FilePathFileFetcher.shareInstance)
    }
    
    func resourceExplorerAddItem(completedHandler: (itemModel: UIResrouceItemModel) -> Void, sender: UIResourceExplorerController!)
    {
        
        class SaveVideo:NSObject,UICameraViewControllerDelegate
        {
            init(handler:(itemModel: UIResrouceItemModel) -> Void)
            {
                completedHandler = handler
            }
            var completedHandler:(itemModel: UIResrouceItemModel) -> Void
            @objc private func cameraCancelRecord(sender: UICameraViewController!)
            {
                sender.view.makeToast(message: "Record Cancel")
            }
            
            @objc private func cameraSaveRecordVideo(sender: UICameraViewController!, destination: String!) {
                let fileService = ServiceContainer.getService(FileService)
                let newFilePath = fileService.createLocalStoreFileName(FileType.Video) + ".mp4"
                if fileService.moveFileTo(destination, destinationPath: newFilePath)
                {
                    let videoFileModel = UIFileCollectionCellModel()
                    videoFileModel.filePath = newFilePath
                    videoFileModel.fileType = .Video
                    completedHandler(itemModel: videoFileModel)
                    sender.view.makeToast(message: "Video Saved")
                }else
                {
                    sender.view.makeToast(message: "Save Video Failed")
                }
                
            }
        }
        
        UICameraViewController.showCamera(sender.navigationController!, delegate: SaveVideo(handler:completedHandler))
    }
    
    func resourceExplorerDeleteItem(itemModels: [UIResrouceItemModel], sender: UIResourceExplorerController!) {
        let fileModels = itemModels as! [UIFileCollectionCellModel]
        var sum = 0
        for fileModel in fileModels
        {
            if fileModel.filePath == shareThingModel.shareContent
            {
                shareThingModel.shareContent = nil
            }
            do
            {
                try NSFileManager.defaultManager().removeItemAtPath(fileModel.filePath)
                sum++
            }catch let error as NSError{
                print(error.description)
            }
        }
        sender.view.makeToast(message: "\(sum) files deleted", duration: HRToastDefaultDuration, position: HRToastPositionCenter)
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
            self.shareThingModel.shareContent = newFilePath
            self.shareContentContainer.model = self.shareThingModel.shareContent
            self.view.makeToast(message: "Video Saved")
        }else
        {
            self.view.makeToast(message: "Save Video Failed")
        }
    }
    
    @IBAction func recordVideo()
    {
        UICameraViewController.showCamera(self.navigationController!, delegate: self)
    }
    
    @IBAction func selectVideo()
    {
        let files = ServiceContainer.getService(FileService).getFileModelsOfFileLocalStore(FileType.Video)
        ServiceContainer.getService(FileService).showFileCollectionControllerView(self.navigationController!, files: files,selectionMode:.Single, delegate: self)
    }
    
    @IBAction func share()
    {
        if let localFilmPath = shareThingModel.shareContent
        {
            let sService = ServiceContainer.getService(ShareService)
            let fService = ServiceContainer.getService(FileService)
            self.view.makeToastActivityWithMessage(message: "Sending Film")
            fService.requestFileId(localFilmPath, type: FileType.Video, callback: { (fileId) -> Void in
                self.view.hideToastActivity()
                if fileId != nil
                {
                    self.shareThingModel.shareContent = fileId
                    fService.startSendFile(fileId)
                    self.view.makeToastActivityWithMessage(message: "Posting")
                    sService.postNewShare(self.shareThingModel, callback: { (isSuc) -> Void in
                        self.view.hideToastActivity()
                        if isSuc
                        {
                            
                        }else
                        {
                            self.view.makeToast(message: "Post New Share Failed")
                        }
                    })
                }
            })
            
        }else
        {
            self.view.makeToast(message: "must select or capture a film!")
        }
    }

    static func instanceFromStoryBoard() -> NewShareViewController
    {
        return instanceFromStoryBoard("Main", identifier: "newShareViewController") as! NewShareViewController
    }
}
