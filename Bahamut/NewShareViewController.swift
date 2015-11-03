//
//  NewShareViewController.swift
//  Bahamut
//
//  Created by AlexChow on 15/8/12.
//  Copyright (c) 2015年 GStudio. All rights reserved.
//

import UIKit
import SharelinkSDK
import EVReflection

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

//MARK: NewShareViewController
class NewShareViewController: UIViewController,UICameraViewControllerDelegate,UITextViewDelegate,UIResourceExplorerDelegate,UITextFieldDelegate,UITagCollectionViewControllerDelegate,ProgressTaskDelegate
{
    static let tagsLimit = 7
    override func viewDidLoad() {
        super.viewDidLoad()
        changeNavigationBarColor()
        if shareThingModel == nil
        {
            shareThingModel = ShareThing()
            shareThingModel.shareType = ShareThingType.shareFilm.rawValue
        }
        myTagController = UITagCollectionViewController.instanceFromStoryBoard()
    }
    
    var shareThingModel:ShareThing!{
        didSet{
            if shareContentContainer != nil
            {
                shareContentContainer.shareThing = shareThingModel
            }
        }
    }
    
    override func viewWillAppear(animated: Bool) {
        super.viewWillAppear(animated)
        initMytags()
        registerForKeyboardNotifications()
        
    }
    
    override func viewWillDisappear(animated: Bool) {
        super.viewWillDisappear(animated)
        ServiceContainer.getService(SharelinkTagService).removeObserver(self)

        removeObserverForKeyboardNotifications()
    }
    
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
    //MARK: outlets
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
            shareContentContainer.delegate = UIShareContentTypeDelegateGenerator.getDelegate(.shareFilm)
            let player = shareContentContainer.contentView as! ShareLinkFilmView
            player.fileFetcher = FilePathFileFetcher.shareInstance
            player.autoLoad = true
            shareContentContainer.shareThing = shareThingModel
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
    
    //MARK: my tags
    
    var myCustomTagSortableList:SortableObjectList<SharelinkTagSortableObject>!
    
    func initMytags()
    {
        let tagService = ServiceContainer.getService(SharelinkTagService)
        tagService.addObserver(self, selector: "myTagUpdated", name: SharelinkTagService.TagsUpdated, object: nil)
        myTagUpdated(nil)
    }
    
    func myTagUpdated(_:NSNotification!)
    {
        dispatch_async(dispatch_get_main_queue()) { () -> Void in
            let tagService = ServiceContainer.getService(SharelinkTagService)
            let mySystemTags = tagService.getAllSystemTags().filter{ $0.isKeywordTag() || $0.isFeedbackTag() || $0.isPrivateTag() || $0.isResharelessTag()}
            
            let myCustomTags = tagService.getAllCustomTags().filter{$0.isSharelinkerTag() == false}
            //let myCustomTagSortables = myCustomTags.map{ $0.getSortableObject() }
            //self.myCustomTagSortableList = SortableObjectList<SharelinkTagSortableObject>(initList: myCustomTagSortables)
            
            //let sortedCustomTags = self.myCustomTagSortableList.list.map{$0.getTag()}
            
            var shareableTags = [SharelinkTag]()
            shareableTags.appendContentsOf(mySystemTags)
            shareableTags.appendContentsOf(myCustomTags)
            self.myTagController.tags = shareableTags
        }
        
    }
    
    var myTagController:UITagCollectionViewController!
        {
        didSet{
            myTagContainer = UIView()
            myTagController.delegate = self
            self.addChildViewController(myTagController)
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
        let height = CGFloat(selectedTagViewContainer.frame.origin.y - self.shareContentContainer.frame.origin.y + 23)
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
    
    //MARK: seletectd tags
    var selectedTagController:UITagCollectionViewController!{
        didSet{
            selectedTagController.delegate = self
            self.addChildViewController(selectedTagController)
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

    
    func addTag()
    {
        if selectedTagController.tags != nil && selectedTagController.tags.count >= NewShareViewController.tagsLimit
        {
            selectedTagViewContainer.makeToast(message:NSLocalizedString("TAG_LIMIT_MESSAGE", comment: "can't not add more tags!"), duration: HRToastDefaultDuration, position: HRToastPositionTop)
            return
        }
        if let newTagName = newTagNameTextfield.text?.stringByTrimmingCharactersInSet(NSCharacterSet.whitespaceCharacterSet())
        {
            if !newTagName.isEmpty
            {
                let newTag = SharelinkTag()
                newTag.tagColor = UIColor.getRandomTextColor().toHexString()
                newTag.tagName = newTagName
                newTag.type = SharelinkTagConstant.TAG_TYPE_KEYWORD
                newTag.data = newTagName
                newTagNameTextfield.text = nil
                if !selectedTagController.addTag(newTag)
                {
                    selectedTagViewContainer.makeToast(message:NSLocalizedString("TAG_ALREADY_SELECTED", comment: "tag has been added!"), duration: HRToastDefaultDuration, position: HRToastPositionTop)
                }
                return
            }
        }
        selectedTagViewContainer.makeToast(message:NSLocalizedString("TAG_IS_EMPTY", comment: "there is nothing!"), duration: HRToastDefaultDuration, position: HRToastPositionTop)
    }
    
    func tagDidTap(sender: UITagCollectionViewController, indexPath: NSIndexPath)
    {
        if sender == myTagController
        {
            let tag = myTagController.tags[indexPath.row]
            if selectedTagController.addTag(tag)
            {
                let tagSortableObj = tag.getSortableObject()
                tagSortableObj.compareValue = NSNumber(double: NSDate().timeIntervalSince1970)
                tagSortableObj.saveModel()
            }
        }else if sender == selectedTagController
        {
            sender.removeTag(indexPath)
        }
    }
    
    //MARK: keyboard
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
    
    
    func textViewDidChange(textView: UITextView) {
        shareThingModel.message = textView.text
    }

    
    
    //MARK: select film delegate
    
    func resourceExplorerItemsSelected(itemModels: [UIResrouceItemModel],sender: UIResourceExplorerController!) {
        if itemModels.count > 0
        {
            let fileModel = itemModels.first as! UIFileCollectionCellModel
            let filmModel = FilmModel()
            filmModel.film = fileModel.filePath
            shareThingModel.shareContent = filmModel.toJsonString()
            self.shareContentContainer.shareThing = shareThingModel
        }
    }
    
    func resourceExplorerOpenItem(itemModel: UIResrouceItemModel, sender: UIResourceExplorerController!) {
        let fileModel = itemModel as! UIFileCollectionCellModel
        ShareLinkFilmView.showPlayer(sender, uri: fileModel.filePath, fileFetcer: FilePathFileFetcher.shareInstance)
    }
    
    func resourceExplorerAddItem(completedHandler: (itemModel: UIResrouceItemModel,indexPath:NSIndexPath) -> Void, sender: UIResourceExplorerController!)
    {
        
        class SaveVideo:NSObject,UICameraViewControllerDelegate
        {
            init(handler:(itemModel: UIResrouceItemModel,indexPath:NSIndexPath) -> Void)
            {
                completedHandler = handler
            }
            var completedHandler:(itemModel: UIResrouceItemModel,indexPath:NSIndexPath) -> Void
            @objc private func cameraCancelRecord(sender: UICameraViewController!)
            {
                sender.view.makeToast(message:NSLocalizedString("RECORD_CANCELED", comment:  "Record Cancel"))
            }
            
            @objc private func cameraSaveRecordVideo(sender: UICameraViewController!, destination: String!) {
                let fileService = ServiceContainer.getService(FileService)
                let newFilePath = fileService.createLocalStoreFileName(FileType.Video)
                if fileService.moveFileTo(destination, destinationPath: newFilePath)
                {
                    let videoFileModel = UIFileCollectionCellModel()
                    videoFileModel.filePath = newFilePath
                    videoFileModel.fileType = .Video
                    completedHandler(itemModel: videoFileModel,indexPath: NSIndexPath(forRow: 0, inSection: 0))
                    sender.view.makeToast(message: NSLocalizedString("VIDEO_SAVED", comment: "Video Saved"))
                }else
                {
                    sender.view.makeToast(message: NSLocalizedString("SAVE_VIDEO_FAILED", comment: "Save Video Failed"))
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
            if fileModel.filePath == FilmModel(json: shareThingModel.shareContent).film
            {
                shareThingModel.shareContent = nil
            }
            do
            {
                try NSFileManager.defaultManager().removeItemAtPath(fileModel.filePath)
                sum++
            }catch let error as NSError{
                NSLog(error.description)
            }
        }
        sender.view.makeToast(message: String(format:(NSLocalizedString("FILES_WAS_DELETED", comment: "%@ files deleted")), sum), duration: HRToastDefaultDuration, position: HRToastPositionCenter)
    }
    
    //MARK: record film
    
    func cameraCancelRecord(sender: UICameraViewController!)
    {
        view.makeToast(message: NSLocalizedString("CANCEL", comment: "Cancel"))
    }
    
    func cameraSaveRecordVideo(sender: UICameraViewController!, destination: String!)
    {
        let fileService = ServiceContainer.getService(FileService)
        let newFilePath = fileService.createLocalStoreFileName(FileType.Video)
        if fileService.moveFileTo(destination, destinationPath: newFilePath)
        {
            let filmModel = FilmModel()
            filmModel.film = newFilePath
            self.shareThingModel.shareContent = filmModel.toJsonString()
            self.shareContentContainer.shareThing = self.shareThingModel
            self.view.makeToast(message: NSLocalizedString("VIDEO_SAVED", comment: "Video Saved"))
        }else
        {
            self.view.makeToast(message: NSLocalizedString("SAVE_VIDEO_FAILED", comment: "Save Video Failed"))
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
        if self.selectedTagController.tags == nil || self.selectedTagController.tags.count == 0
        {
            let alert = UIAlertController(title: NSLocalizedString("SHARE", comment:  ""), message: NSLocalizedString("NO_SELECT_TAG_TIPS", comment:  ""),preferredStyle: UIAlertControllerStyle.Alert)
            alert.addAction(UIAlertAction(title: NSLocalizedString("CONTINUE", comment:  ""), style: UIAlertActionStyle.Default, handler: { (ac) -> Void in
                self.prepareShare()
            }))
            alert.addAction(UIAlertAction(title: NSLocalizedString("CANCEL", comment:  ""), style: UIAlertActionStyle.Cancel, handler: nil))
            self.presentViewController(alert, animated: true, completion: nil )
        }else
        {
            prepareShare()
        }
    }
    
    private func prepareShare()
    {
        if let shareContent = shareThingModel.shareContent
        {
            let newShare = ShareThing()
            newShare.message = self.shareDescriptionTextArea.text
            newShare.shareType = ShareThingType.shareFilm.rawValue
            newShare.shareContent = shareContent
            let me = ServiceContainer.getService(UserService).myUserModel
            newShare.userId = me.userId
            newShare.userNick = me.nickName
            newShare.avatarId = me.avatarId
            newShare.shareTime = NSDate().toDateTimeString()
            newShare.reshareable = "true"
            clear()
            let taskKey = NSNumber(double: NSDate().timeIntervalSince1970).integerValue.description
            let newShareTask = NewShareTask()
            newShareTask.id = taskKey
            newShareTask.saveModel()
            ProgressTaskWatcher.sharedInstance.addTaskObserver(taskKey, delegate: self)
            self.view.makeToastActivityWithMessage(message: NSLocalizedString("SENDING_FILM", comment: "Sending Film"))
            dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0)){
                let tags = self.selectedTagController.tags ?? [SharelinkTag]()
                self.postShare(newShare,tags:tags,taskKey: taskKey)
            }
            
        }else
        {
            self.view.makeToast(message:NSLocalizedString("NO_FILM_SELECTED", comment: "must select or capture a film!"))
        }
    }
    
    private func postShare(newShare:ShareThing,tags:[SharelinkTag],taskKey:String)
    {
        let sService = ServiceContainer.getService(ShareService)
        let fService = ServiceContainer.getService(FileService)
        let filePath = FilmModel(json: newShare.shareContent).film
        if filePath == nil
        {
            self.view.makeToast(message:NSLocalizedString("NO_FILM_SELECTED", comment: "must select or capture a film!"))
            return
        }
        fService.requestFileId(filePath!, type: FileType.Video, callback: { (fileKey) -> Void in
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
                
                let filmModel = FilmModel()
                filmModel.film = fileKey.fileId
                newShare.shareContent = filmModel.toJsonString()
                sService.postNewShare(newShare, tags: tags ,callback: { (shareId) -> Void in
                    self.view.hideToastActivity()
                    if shareId != nil
                    {
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
            let msg = result as! String
            if msg == "file"
            {
                task.uploadedFile = 1
                self.view.makeToast(message:NSLocalizedString("SEND_FILM_SUC", comment:  "Send Film Success"))
            }else if msg.hasBegin("share:")
            {
                task.shareId = msg.substringFromIndex(6)
                task.sharePosted = 1
                self.view.makeToast(message:NSLocalizedString("POST_SHARE_SUC", comment: "Post Share Success"))
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
            let msg = result as! String
            if msg == "file"
            {
                task.uploadedFile = -1
                self.view.makeToast(message:NSLocalizedString("SEND_FILM_FAILED", comment: "Send File Failed"))
            }else if msg == "share"
            {
                task.sharePosted = -1
                self.view.makeToast(message:NSLocalizedString("POST_SHARE_FAILED", comment: "Post Share Error"))
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
