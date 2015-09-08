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
        controller.shareThingModel.shareContent = reShareModel.shareContent
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
            shareContentContainer.mediaPlayer.fileFetcher = FilePathFileFetcher()
            shareContentContainer.mediaPlayer.autoLoad = true
            if let content = shareThingModel?.shareContent
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
    
    var selectedTags:[SharelinkTag] = [SharelinkTag]()
    
    func collectionView(collectionView: UICollectionView, cellForItemAtIndexPath indexPath: NSIndexPath) -> UICollectionViewCell
    {
        let identifier: String = "UserTagCell"
        let tag = selectedTags[indexPath.row]
        let tagColor = UIColor(hexString: tag.tagColor)
        let cell = collectionView.dequeueReusableCellWithReuseIdentifier(identifier, forIndexPath: indexPath)
        let label = UILabel()
        label.text = tag.tagName
        label.textColor = tagColor
        cell.autoresizingMask = [UIViewAutoresizing.FlexibleWidth, UIViewAutoresizing.FlexibleHeight]
        label.addSubview(label)
        return cell
    }
    
    func collectionView(collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        return shareThingModel.forTags?.count ?? 0
    }
    
    var shareThingModel:ShareThing!{
        didSet{
            if shareContentContainer != nil
            {
                shareContentContainer.model = shareThingModel.shareContent
            }
        }
    }
    
    func selectUserTag(_:UITapGestureRecognizer)
    {
        let userService = ServiceContainer.getService(UserService)
        let userTagService = ServiceContainer.getService(UserTagService)
        let allTags = userTagService.getMyAllTags()
        let setAllTags = Set<SharelinkTag>(allTags)
        if shareThingModel.forTags == nil
        {
            selectedTags = [SharelinkTag]()
        }
        let notSeletedTags = setAllTags.subtract(selectedTags).map{return $0}
        let seletedTagModels = userService.getUserTagsResourceItemModels(selectedTags,selected: true)
        let notSeletedTagModels = userService.getUserTagsResourceItemModels(notSeletedTags)
        
        userService.showTagCollectionControllerView(self.navigationController!, tags: seletedTagModels + notSeletedTagModels, selectionMode: ResourceExplorerSelectMode.Multiple){ tagsSelected -> Void in
            let result = tagsSelected.map{return $0.tagModel!}
            self.selectedTags = result
            self.userTagCollectionView.reloadData()
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
        let fileModel = itemModel as! UIFileCollectionCellModel
        ShareLinkFilmView.showPlayer(sender, uri: fileModel.filePath, fileFetcer: FilePathFileFetcher.shareInstance)
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
                self.shareThingModel.shareContent = newFilePath
                self.shareContentContainer.model = self.shareThingModel.shareContent
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

    static func instanceFromStoryBoard() -> NewShareViewController
    {
        return instanceFromStoryBoard("Main", identifier: "newShareViewController") as! NewShareViewController
    }
}
