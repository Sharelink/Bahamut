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
        let controller = UIStoryboard(name: "Main", bundle: NSBundle.mainBundle()).instantiateViewControllerWithIdentifier("newShareViewController") as! NewShareViewController
        
        controller.shareThingModel = ShareThing()
        controller.shareThingModel.content = ShareContent()
        controller.shareThingModel.content.content = reShareModel.content.content
        controller.shareThingModel.shareType = reShareModel.shareType
        controller.hidesBottomBarWhenPushed = true
        currentNavigationController.pushViewController(controller, animated: true)
    }
}

class NewShareViewController: UIViewController,UICameraViewControllerDelegate,UITextViewDelegate,UIResourceExplorerDelegate ,UICollectionViewDataSource,UICollectionViewDelegate{

    override func viewDidLoad() {
        super.viewDidLoad()
        if shareThingModel == nil
        {
            shareThingModel = ShareThing()
            shareThingModel.content = ShareContent()
        }
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
    @IBOutlet weak var shareDescriptionTextArea: UITextView!{
        didSet{
            shareDescriptionTextArea.delegate = self
        }
    }
    
    @IBOutlet weak var shareContentContainer: UIShareContent!{
        didSet{
            if let content = shareThingModel?.content
            {
                shareContentContainer.model = content
            }
            
        }
    }
    
    @IBOutlet weak var userTagCollectionView: UICollectionView!{
        didSet{
            userTagCollectionView.delegate = self
            userTagCollectionView.dataSource = self
            userTagCollectionView.addGestureRecognizer(UITapGestureRecognizer(target: self, action: "selectUserTag:"))
        }
    }
    
    func collectionView(collectionView: UICollectionView, cellForItemAtIndexPath indexPath: NSIndexPath) -> UICollectionViewCell {
        let identifier: String = "UserTagCell"
        let cell = collectionView.dequeueReusableCellWithReuseIdentifier(identifier, forIndexPath: indexPath)
        cell.backgroundColor = UIColor(CIColor: CIColor(string: shareThingModel.userTags[indexPath.row].tagColor))
        return cell
    }
    
    func collectionView(collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        return shareThingModel.userTags?.count ?? 0
    }
    
    var shareThingModel:ShareThing!{
        didSet{
            if shareContentContainer != nil
            {
                shareContentContainer.model = shareThingModel.content
            }
        }
    }
    
    func selectUserTag(_:UITapGestureRecognizer)
    {
        let userService = ServiceContainer.getService(UserService)
        let tags = userService.getMyAllUserTags()
        let tagsModels = userService.getUserTagsResourceItemModels(tags) as! [UserTagModel]
        for model in tagsModels
        {
            for eModel in shareThingModel.userTags
            {
                model.selected = eModel.tagId == model.tagModel.tagId
            }
        }
        userService.showTagCollectionControllerView(self.navigationController!, tags: tagsModels, selectionMode: ResourceExplorerSelectMode.Multiple){ tagsSelected -> Void in
            
            let result = tagsSelected.map{ tag -> UserTag in
                return tag.tagModel
            }
            self.shareThingModel.userTags = result
            self.userTagCollectionView.reloadData()
        }
        
    }
    
    func textViewDidChange(textView: UITextView) {
        shareThingModel.title = textView.text
    }
    
    func resourceExplorerItemSelected(itemModel: UIResrouceItemModel, index: Int, sender: UIResourceExplorerController!) {
        let fileModel = itemModel as! UIFileCollectionCellModel
        shareThingModel.content.content = fileModel.filePath
        self.shareContentContainer.model = shareThingModel.content
    }
    
    func resourceExplorerAddItem(completedHandler: (itemModel: UIResrouceItemModel) -> Void, sender: UIResourceExplorerController!) {
        ServiceContainer.getService(CameraService).showCamera(sender.navigationController!, delegate: nil) { (destination) -> Void in
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
    
    func resourceExplorerDeleteItem(itemModels: [UIResrouceItemModel], sender: UIResourceExplorerController!) {
        let fileModels = itemModels as! [UIFileCollectionCellModel]
        var sum = 0
        for fileModel in fileModels
        {
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
    
    func resourceExplorerOpenItem(itemModel: UIResrouceItemModel, sender: UIResourceExplorerController!) {
        
        sender.view.makeToast(message: "open file")
    }
    
    func videoCancelRecord(sender: UICameraViewController!)
    {
        view.makeToast(message: "Cancel")
    }
    
    @IBAction func recordVideo() {
        ServiceContainer.getService(CameraService).showCamera(self.navigationController!, delegate: self){ destination in
            let fileService = ServiceContainer.getService(FileService)
            let newFilePath = fileService.createLocalStoreFileName(FileType.Video) + ".mp4"
            if fileService.moveFileTo(destination, destinationPath: newFilePath)
            {
                self.shareThingModel.content.content = newFilePath
                self.shareContentContainer.model = self.shareThingModel.content
                self.view.makeToast(message: "Video Saved")
            }else
            {
                self.view.makeToast(message: "Save Video Failed")
            }
        }
    }
    
    @IBAction func selectVideo()
    {
        let files = ServiceContainer.getService(FileService).getFileModelsOfFileLocalStore(FileType.Video)
        ServiceContainer.getService(FileService).showFileCollectionControllerView(self.navigationController!, files: files,selectionMode:.Single, delegate: self)
    }
    
    @IBAction func share()
    {
        
    }
    /*
    // MARK: - Navigation

    // In a storyboard-based application, you will often want to do a little preparation before navigation
    override func prepareForSegue(segue: UIStoryboardSegue, sender: AnyObject?) {
        // Get the new view controller using segue.destinationViewController.
        // Pass the selected object to the new view controller.
    }
    */

}
