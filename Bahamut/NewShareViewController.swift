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

class NewShareViewController: UIViewController,UICameraViewControllerDelegate,UITextViewDelegate,UIResourceExplorerDelegate,UITextFieldDelegate,UITagCollectionViewControllerDelegate,ProgressTaskDelegate
{
    static let tagsLimit = 7
    override func viewDidLoad() {
        super.viewDidLoad()
        changeNavigationBarColor()
        if shareThingModel == nil
        {
            shareThingModel = ShareThing()
            shareThingModel.shareType = ShareType.filmType.rawValue
        }
        myTagController = UITagCollectionViewController.instanceFromStoryBoard()
    }
    
    override func viewWillAppear(animated: Bool) {
        super.viewWillAppear(animated)
        registerForKeyboardNotifications()
        initMytags()
    }
    
    override func viewWillDisappear(animated: Bool) {
        super.viewWillDisappear(animated)
        removeObserverForKeyboardNotifications()
    }
    
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
    @IBOutlet weak var shareDescriptionTextArea: UITextView!{
        didSet{
            shareDescriptionTextArea.layer.cornerRadius = 7
            shareDescriptionTextArea.layer.borderColor = UIColor.lightGrayColor().CGColor
            shareDescriptionTextArea.layer.borderWidth = 1
            shareDescriptionTextArea.delegate = self
        }
    }
    
    @IBOutlet weak var shareContentContainer: UIShareContent!{
        didSet{
            shareContentContainer.delegate = UIShareContentTypeDelegateGenerator.getDelegate(ShareType.filmType)
            let player = shareContentContainer.contentView as! ShareLinkFilmView
            player.fileFetcher = FilePathFileFetcher.shareInstance
            shareContentContainer.shareThing = shareThingModel
        }
    }
    
    func initMytags()
    {
        myTagController.tags = ServiceContainer.getService(SharelinkTagService).getMyAllTags()
    }
    
    var myTagController:UITagCollectionViewController!
        {
        didSet{
            myTagContainer = UIView()
            myTagController.delegate = self
            self.addChildViewController(myTagController)
        }
    }
    
    var selectedTagController:UITagCollectionViewController!{
        didSet{
            selectedTagController.delegate = self
            self.addChildViewController(selectedTagController)
        }
    }
    @IBOutlet weak var selectedTagViewContainer: UIView!{
        didSet{
            selectedTagViewContainer.userInteractionEnabled = true
            selectedTagViewContainer.layer.cornerRadius = 7
            selectedTagViewContainer.layer.borderColor = UIColor.lightGrayColor().CGColor
            selectedTagViewContainer.layer.borderWidth = 1
            selectedTagController  = UITagCollectionViewController.instanceFromStoryBoard()
            selectedTagViewContainer.addSubview(selectedTagController.view)
        }
    }
    
    @IBOutlet weak var recordNewFilmButton: UIButton!{
        didSet{
            recordNewFilmButton.tintColor = UIColor.themeColor
        }
    }
    @IBOutlet weak var selectFilmButton: UIButton!{
        didSet{
            selectFilmButton.tintColor = UIColor.themeColor
        }
    }
    @IBOutlet weak var newTagNameTextfield: UITextField!{
        didSet{
            newTagNameTextfield.delegate = self
        }
    }
    
    @IBAction func selectTag(sender: AnyObject)
    {
        let btn = sender as! UIButton
        
        if myTagContainer.superview != nil
        {
            hideMyTagsCollection()
            btn.setTitleColor(UIColor.lightGrayColor(), forState: .Normal)
        }else{
            showMyTagsCollection()
            btn.setTitleColor(UIColor.themeColor, forState: .Normal)
        }
    }
    
    private var myTagContainer:UIView!{
        didSet{
            myTagContainer.layer.cornerRadius = 7
            myTagContainer.layer.borderWidth = 1
            myTagContainer.layer.borderColor = UIColor.lightGrayColor().CGColor
            myTagContainer.backgroundColor = UIColor.whiteColor()
        }
    }
    private func showMyTagsCollection()
    {
        self.view.addSubview(myTagContainer)
        myTagContainer.frame = selectedTagViewContainer.frame
        self.myTagContainer.addSubview(myTagController.view)
        let height = CGFloat(126)
        UIView.beginAnimations(nil, context: nil)
        UIView.setAnimationDuration(0.3)
        myTagContainer.frame = CGRectMake(self.selectedTagViewContainer.frame.origin.x, selectedTagViewContainer.frame.origin.y - height - 7,self.selectedTagViewContainer.bounds.width, height)
        self.view.layoutIfNeeded()
        UIView.commitAnimations()
    }
    
    private func hideMyTagsCollection()
    {
        UIView.beginAnimations(nil, context: nil)
        UIView.setAnimationDuration(0.3)
        myTagContainer.frame = selectedTagViewContainer.frame
        self.view.layoutIfNeeded()
        UIView.commitAnimations()
        myTagContainer.removeFromSuperview()
    }
    
    func addTag()
    {
        if selectedTagController.tags != nil && selectedTagController.tags.count >= NewShareViewController.tagsLimit
        {
            selectedTagViewContainer.makeToast(message: "can't not add more tags!", duration: HRToastDefaultDuration, position: HRToastPositionTop)
            return
        }
        if let newTagName = newTagNameTextfield.text?.stringByTrimmingCharactersInSet(NSCharacterSet.whitespaceCharacterSet())
        {
            if !newTagName.isEmpty
            {
                let newTag = SharelinkTag()
                newTag.tagColor = UIColor.getRandomTextColor().toHexString()
                newTag.tagName = newTagName
                newTagNameTextfield.text = nil
                if !selectedTagController.addTag(newTag)
                {
                    selectedTagViewContainer.makeToast(message: "tag has been added!", duration: HRToastDefaultDuration, position: HRToastPositionTop)
                }
                return
            }
        }
        selectedTagViewContainer.makeToast(message: "there is nothing!", duration: HRToastDefaultDuration, position: HRToastPositionTop)
    }
    
    func tagDidTap(sender: UITagCollectionViewController, indexPath: NSIndexPath)
    {
        if sender == myTagController
        {
            let tag = myTagController.tags[indexPath.row]
            if !selectedTagController.addTag(tag)
            {
                self.view.makeToast(message: "tags has been ready")
            }
        }else if sender == selectedTagController
        {
            sender.removeTag(indexPath)
        }
    }
    
    func removeObserverForKeyboardNotifications()
    {
        NSNotificationCenter.defaultCenter().removeObserver(self)
    }
    
    func registerForKeyboardNotifications()
    {
        NSNotificationCenter.defaultCenter().addObserver(self, selector: "keyboardChanged:", name: UIKeyboardDidShowNotification, object: nil)
        NSNotificationCenter.defaultCenter().addObserver(self, selector: "keyboardChanged:", name: UIKeyboardWillHideNotification, object: nil)
    }
    
    var offset:CGFloat = 0
    func keyboardChanged(aNotification:NSNotification)
    {
        let info = aNotification.userInfo!
        if !newTagNameTextfield.isFirstResponder()
        {
            return
        }
        if let kbFrame = info[UIKeyboardFrameEndUserInfoKey]!.CGRectValue
        {
            let tfFrame = newTagNameTextfield.frame
            
            if aNotification.name == UIKeyboardDidShowNotification
            {
                offset = tfFrame.origin.y + tfFrame.size.height + 7 - kbFrame.origin.y
                if offset <= 0
                {
                    return
                }
                var animationDuration:NSTimeInterval
                var animationCurve:UIViewAnimationCurve
                let curve = info[UIKeyboardAnimationCurveUserInfoKey] as! Int
                animationCurve = UIViewAnimationCurve(rawValue: curve)!
                animationDuration = info[UIKeyboardAnimationDurationUserInfoKey] as! NSTimeInterval
                UIView.beginAnimations(nil, context:nil)
                UIView.setAnimationDuration(animationDuration)
                UIView.setAnimationCurve(animationCurve)
                
                view.frame.origin.y = -offset
                
                view.layoutIfNeeded()
                UIView.commitAnimations()
            }else
            {
                if offset <= 0
                {
                    return
                }
                view.frame.origin.y = 0
                view.layoutIfNeeded()
            }
        }
    }
    
    func textField(textField: UITextField, shouldChangeCharactersInRange range: NSRange, replacementString string: String) -> Bool {
        if string == "\n"
        {
            addTag()
            return false
        }
        return true
    }
    
    var shareThingModel:ShareThing!{
        didSet{
            if shareContentContainer != nil
            {
                shareContentContainer.shareThing = shareThingModel
            }
        }
    }
    
    func textViewDidChange(textView: UITextView) {
        shareThingModel.title = textView.text
    }
    
    //MARK: select film delegate
    
    func resourceExplorerItemsSelected(itemModels: [UIResrouceItemModel],sender: UIResourceExplorerController!) {
        if itemModels.count > 0
        {
            let fileModel = itemModels.first as! UIFileCollectionCellModel
            shareThingModel.shareContent = fileModel.filePath
            self.shareContentContainer.shareThing = shareThingModel
        }
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
                let newFilePath = fileService.createLocalStoreFileName(FileType.Video)
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
    
    //MARK: record film
    
    func cameraCancelRecord(sender: UICameraViewController!)
    {
        view.makeToast(message: "Cancel")
    }
    
    func cameraSaveRecordVideo(sender: UICameraViewController!, destination: String!)
    {
        let fileService = ServiceContainer.getService(FileService)
        let newFilePath = fileService.createLocalStoreFileName(FileType.Video)
        if fileService.moveFileTo(destination, destinationPath: newFilePath)
        {
            self.shareThingModel.shareContent = newFilePath
            self.shareContentContainer.shareThing = self.shareThingModel
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
    
    //MARK: post new share
    
    func clear()
    {
        self.shareDescriptionTextArea.text = ""
        shareThingModel.shareContent = nil
        self.shareContentContainer.shareThing = self.shareThingModel
    }
    
    @IBAction func share()
    {
        if let shareContent = shareThingModel.shareContent
        {
            let newShare = ShareThing()
            newShare.title = self.shareDescriptionTextArea.text
            newShare.shareType = ShareType.filmType.rawValue
            newShare.shareContent = shareContent
            let tags = self.selectedTagController.tags
            clear()
            let taskKey = NSNumber(double: NSDate().timeIntervalSince1970).integerValue.description
            let newShareTask = NewShareTask()
            newShareTask.id = taskKey
            newShareTask.saveModel()
            ProgressTaskWatcher.sharedInstance.addTaskObserver(taskKey, delegate: self)
            self.view.makeToastActivityWithMessage(message: "Sending Film")
            dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0)){
                self.postShare(newShare,tags:tags,taskKey: taskKey)
            }
            
        }else
        {
            self.view.makeToast(message: "must select or capture a film!")
        }
    }
    
    private func postShare(newShare:ShareThing,tags:[SharelinkTag],taskKey:String)
    {
        let sService = ServiceContainer.getService(ShareService)
        let fService = ServiceContainer.getService(FileService)
        fService.requestFileId(newShare.shareContent, type: FileType.Video, callback: { (fileKey) -> Void in
            if fileKey != nil
            {
                
                fService.startSendFile(fileKey.accessKey,taskKey: taskKey){ suc in
                    if suc
                    {
                        ProgressTaskWatcher.sharedInstance.missionCompleted(taskKey, result: "file")
                    }else
                    {
                        ProgressTaskWatcher.sharedInstance.missionFailed(taskKey, result: "file")
                    }
                }
                
                newShare.shareContent = fileKey.fileId
                sService.postNewShare(newShare, tags: self.selectedTagController.tags ,callback: { (shareId) -> Void in
                    self.view.hideToastActivity()
                    if shareId != nil
                    {
                        newShare.shareContent = fileKey.accessKey
                        newShare.saveModel()
                        ProgressTaskWatcher.sharedInstance.missionCompleted(taskKey, result: "share:\(shareId)")
                    }else
                    {
                        ProgressTaskWatcher.sharedInstance.missionFailed(taskKey, result: "share")
                    }
                })
            }else
            {
                ProgressTaskWatcher.sharedInstance.missionFailed(taskKey, result: "file")
            }
        })
    }
    
    func taskCompleted(taskIdentifier: String, result: AnyObject!) {
        if let task = PersistentManager.sharedInstance.getModel(NewShareTask.self, idValue: taskIdentifier)
        {
            var msg = result as! String
            if msg == "file"
            {
                task.uploadedFile = 1
                msg = "Send File Success"
            }else if msg.hasBegin("share:")
            {
                task.shareId = msg.substringFromIndex(6)
                task.sharePosted = 1
                msg = "Post Share Success"
            }
            dispatch_async(dispatch_get_main_queue()) { () -> Void in
                self.view.makeToastActivityWithMessage(message: msg)
            }
            if task.uploadedFile.integerValue != 0 && task.sharePosted.integerValue != 0
            {
                ProgressTaskWatcher.sharedInstance.removeTaskObserver(taskIdentifier, delegate: self)
            }
            if task.isTaskCompleted()
            {
                ServiceContainer.getService(ShareService).postNewShareFinish(task.shareId, isCompleted: true)
            }else if task.isTaskFailed() && task.shareId != nil
            {
                ServiceContainer.getService(ShareService).postNewShareFinish(task.shareId, isCompleted: false)
            }
            task.saveModel()
        }
        
    }
    
    func taskFailed(taskIdentifier: String, result: AnyObject!) {
        if let task = PersistentManager.sharedInstance.getModel(NewShareTask.self, idValue: taskIdentifier)
        {
            var msg = result as! String
            if msg == "file"
            {
                task.uploadedFile = -1
                msg = "Send File Error"
            }else if msg == "share"
            {
                task.sharePosted = -1
                msg = "Post Share Error"
            }
            dispatch_async(dispatch_get_main_queue()) { () -> Void in
                self.view.makeToastActivityWithMessage(message: msg)
            }
            if task.uploadedFile.integerValue != 0 && task.sharePosted.integerValue != 0
            {
                ProgressTaskWatcher.sharedInstance.removeTaskObserver(taskIdentifier, delegate: self)
            }
            task.saveModel()
        }
    }
    
    static func instanceFromStoryBoard() -> NewShareViewController
    {
        return instanceFromStoryBoard("Main", identifier: "newShareViewController") as! NewShareViewController
    }
}

//MARK: new share task entity

class NewShareTask : ShareLinkObject
{
    var id:String!
    var uploadedFile:NSNumber = 0
    var sharePosted:NSNumber = 0
    var shareId:String!
    
    func isTaskCompleted() -> Bool
    {
        return (uploadedFile.integerValue > 0 && sharePosted.integerValue > 0)
    }
    
    func isTaskFailed() -> Bool
    {
        return uploadedFile.integerValue < 0 || sharePosted.integerValue < 0
    }
}
