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
        controller.isReshare = true
        controller.shareThingModel = ShareThing()
        controller.shareThingModel.pShareId = reShareModel.shareId
        controller.shareThingModel.shareId = reShareModel.shareId
        controller.shareThingModel.shareContent = reShareModel.shareContent
        controller.shareThingModel.shareType = reShareModel.shareType
        controller.shareThingModel.forTags = reShareModel.forTags
        controller.shareThingModel.message = reShareModel.message
        controller.hidesBottomBarWhenPushed = true
        currentNavigationController.pushViewController(controller, animated: true)
    }
}

//MARK: NewShareViewController
class NewShareViewController: UIViewController,UICameraViewControllerDelegate,UITextViewDelegate,UIResourceExplorerDelegate,UITextFieldDelegate,UITagCollectionViewControllerDelegate,ProgressTaskDelegate,UIShareContentViewSetupDelegate
{
    static let tagsLimit = 7
    var fileService:FileService!
    var shareService:ShareService!
    var isReshare:Bool = false
    var shareThingModel:ShareThing!
    
    private var viewKeyboardAdjustProxy:ControllerViewAdjustByKeyboardProxy!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        self.shareService = ServiceContainer.getService(ShareService)
        self.fileService = ServiceContainer.getService(FileService)
        changeNavigationBarColor()
        viewKeyboardAdjustProxy = ControllerViewAdjustByKeyboardProxy(controller: self)
        myTagController = UITagCollectionViewController.instanceFromStoryBoard()
    }
    
    override func viewWillAppear(animated: Bool) {
        super.viewWillAppear(animated)
        if isReshare
        {
            initReshare()
        }
        viewKeyboardAdjustProxy.registerForKeyboardNotifications([newTagNameTextfield])
        
    }
    
    override func viewWillDisappear(animated: Bool) {
        super.viewWillDisappear(animated)
        viewKeyboardAdjustProxy.removeObserverForKeyboardNotifications()
    }
    
    private func initReshare()
    {
        //filter share's tag without poster's personal tag
        let tagDatas = shareThingModel.forTags.map{SendTagModel(json:$0)}.filter{ SharelinkTagConstant.TAG_TYPE_SHARELINKER != $0.type }
        for m in tagDatas
        {
            let tag = SharelinkTag()
            tag.type = m.type
            tag.tagName = m.name
            tag.data = m.data
            tag.tagColor = UIColor.getRandomTextColor().toHexString()
            self.selectedTagController.addTag(tag)
        }
        self.shareMessageTextView.text = shareThingModel.message
    }
    
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
    //MARK: outlets
    @IBOutlet weak var shareMessageTextView: UITextView!{
        didSet{
            shareMessageTextView.layer.cornerRadius = 7
            shareMessageTextView.layer.borderColor = UIColor.lightGrayColor().CGColor
            shareMessageTextView.layer.borderWidth = 1
            shareMessageTextView.delegate = self
        }
    }
    
    @IBOutlet weak var shareContentContainer: UIShareContent!{
        didSet{
            shareContentContainer.setupContentViewDelegate = self
            if shareThingModel == nil
            {
                let st = ShareThing()
                st.shareType = ShareThingType.shareFilm.rawValue
                shareThingModel = st
            }
            refreshShareContent()
        }
    }
    
    func setupContentView(contentView: UIView, share: ShareThing)
    {
        if let player = contentView as? ShareLinkFilmView
        {
            if isReshare == false
            {
                player.fileFetcher = FilePathFileFetcher.shareInstance
            }else
            {
                player.fileFetcher = ServiceContainer.getService(FileService).getFileFetcherOfFileId(FileType.Video)
            }
            player.autoLoad = true
        }
    }
    
    func refreshShareContent()
    {
        shareContentContainer.delegate = UIShareContentTypeDelegateGenerator.getDelegate(ShareThingType(rawValue: shareThingModel.shareType!)!)
        shareContentContainer.share = shareThingModel
        shareContentContainer.update()
    }
    
    @IBOutlet weak var recordNewFilmButton: UIButton!{
        didSet{
            recordNewFilmButton.tintColor = UIColor.themeColor
            recordNewFilmButton.hidden = isReshare
        }
    }
    @IBOutlet weak var selectFilmButton: UIButton!{
        didSet{
            selectFilmButton.tintColor = UIColor.themeColor
            selectFilmButton.hidden = isReshare
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
    
    func initMyTags()
    {
        let tagService = ServiceContainer.getService(SharelinkTagService)
        let mySystemTags = tagService.getAllSystemTags().filter{ $0.isKeywordTag() || $0.isFeedbackTag() || $0.isPrivateTag() || $0.isResharelessTag()}
        
        let myCustomTags = tagService.getAllCustomTags().filter{$0.isSharelinkerTag() == false}
        var shareableTags = [SharelinkTag]()
        shareableTags.appendContentsOf(mySystemTags)
        shareableTags.appendContentsOf(myCustomTags)
        self.myTagController.tags = shareableTags
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
        initMyTags()
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
            dispatch_async(dispatch_get_main_queue(), { () -> Void in
                self.hideMyTagsCollection()
                btn.setTitleColor(UIColor.lightGrayColor(), forState: .Normal)
            })
            
        }else{
            dispatch_async(dispatch_get_main_queue(), { () -> Void in
                self.showMyTagsCollection()
                btn.setTitleColor(UIColor.themeColor, forState: .Normal)
            })
            
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
            self.shareContentContainer.share.shareContent = filmModel.toJsonString()
            self.shareContentContainer.update()
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
                shareContentContainer.update()
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
            self.shareContentContainer.share.shareContent = filmModel.toJsonString()
            self.shareContentContainer.update()
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
        self.shareMessageTextView.text = ""
        shareThingModel.shareContent = nil
        self.shareContentContainer.update()
    }
    
    @IBAction func share()
    {
        if self.selectedTagController.tags == nil || self.selectedTagController.tags.count == 0
        {
            let alert = UIAlertController(title: NSLocalizedString("SHARE", comment:  ""), message: NSLocalizedString("NO_SELECT_TAG_TIPS", comment:  ""),preferredStyle: UIAlertControllerStyle.Alert)
            alert.addAction(UIAlertAction(title: NSLocalizedString("CONTINUE", comment:  ""), style: UIAlertActionStyle.Default, handler: { (ac) -> Void in
                self.isReshare ? self.reshare() : self.prepareShare()
            }))
            alert.addAction(UIAlertAction(title: NSLocalizedString("CANCEL", comment:  ""), style: UIAlertActionStyle.Cancel, handler: nil))
            self.presentViewController(alert, animated: true, completion: nil )
        }else
        {
            self.isReshare ? self.reshare() : self.prepareShare()
        }
    }
    
    private func reshare()
    {
        let tags = self.selectedTagController.tags ?? [SharelinkTag]()
        self.view.makeToastActivityWithMessage(message: NSLocalizedString("SHARING", comment: "Sharing"))
        self.shareService.reshare(self.shareThingModel.shareId, message: self.shareMessageTextView.text, tags: tags){ isSuc,msg in
            self.view.hideToastActivity()
            var alert:UIAlertController!
            if isSuc{
                alert = UIAlertController(title: NSLocalizedString("SHARE_SUCCESSED", comment: "Share Successed"), message: nil, preferredStyle: .Alert)
                alert.addAction(UIAlertAction(title: NSLocalizedString("I_SEE", comment: ""), style: .Cancel, handler: { (action) -> Void in
                    self.navigationController?.popViewControllerAnimated(true)
                }))
            }else
            {
                alert = UIAlertController(title: NSLocalizedString("SHARE_FAILED", comment: "Share Failed"), message: msg, preferredStyle: .Alert)
                alert.addAction(UIAlertAction(title: NSLocalizedString("I_SEE", comment: ""), style: .Cancel, handler: { (action) -> Void in
                    
                }))
            }
            self.presentViewController(alert, animated: true, completion: nil)
        }
    }
    
    private func prepareShare()
    {
        if let shareContent = shareThingModel.shareContent
        {
            let newShare = ShareThing()
            newShare.message = self.shareMessageTextView.text
            newShare.shareType = ShareThingType.shareFilm.rawValue
            newShare.shareContent = shareContent
            let me = ServiceContainer.getService(UserService).myUserModel
            newShare.userId = me.userId
            newShare.userNick = me.nickName
            newShare.avatarId = me.avatarId
            newShare.shareTime = NSDate().toDateTimeString()
            newShare.reshareable = "true"
            clear()
            
            self.view.makeToastActivityWithMessage(message: NSLocalizedString("SENDING_FILM", comment: "Sending Film"))
            dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0)){
                let tags = self.selectedTagController.tags ?? [SharelinkTag]()
                self.postShare(newShare,tags:tags)
            }
            
        }else
        {
            self.view.makeToast(message:NSLocalizedString("NO_FILM_SELECTED", comment: "must select or capture a film!"))
        }
    }
    
    private func postShare(newShare:ShareThing,tags:[SharelinkTag])
    {
        let filePath = FilmModel(json: newShare.shareContent).film
        self.fileService.sendFile(filePath!, type: FileType.Video) { (taskId, fileKey) -> Void in
            self.view.hideToastActivity()
            if let taskKey = taskId
            {
                let filmModel = FilmModel()
                filmModel.film = fileKey.fileId
                newShare.shareContent = filmModel.toJsonString()
                let newShareTask = NewShareTask()
                newShareTask.id = taskKey
                newShareTask.shareTags = tags
                newShareTask.share = newShare
                newShareTask.sendFileKey = fileKey
                newShareTask.saveModel()
                ProgressTaskWatcher.sharedInstance.addTaskObserver(taskKey, delegate: self)
            }else
            {
                self.view.makeToast(message:NSLocalizedString("SEND_FILM_FAILED", comment: "Send File Failed"))
            }
        }
    }
    
    func taskCompleted(taskIdentifier: String, result: AnyObject!) {
        if let task = PersistentManager.sharedInstance.getModel(NewShareTask.self, idValue: taskIdentifier)
        {
            self.shareService.postNewShare(task.share, tags: task.shareTags ,callback: { (shareId) -> Void in
                if shareId != nil
                {
                    self.shareService.postNewShareFinish(shareId, isCompleted: true){ (isSuc) -> Void in
                        if isSuc
                        {
                            self.view.makeToast(message:NSLocalizedString("POST_SHARE_SUC", comment: "Post Share Success"))
                            NewShareTask.deleteObjectArray([task])
                        }else
                        {
                            self.view.makeToast(message:NSLocalizedString("POST_SHARE_FAILED", comment: "Post Share Error"))
                        }
                    }
                }else
                {
                    self.view.makeToast(message:NSLocalizedString("POST_SHARE_FAILED", comment: "Post Share Error"))
                }
            })
        }
    }
    
    func taskFailed(taskIdentifier: String, result: AnyObject!) {
        if let task = PersistentManager.sharedInstance.getModel(NewShareTask.self, idValue: taskIdentifier)
        {
            self.view.makeToast(message:NSLocalizedString("SEND_FILM_FAILED", comment: "Send File Failed"))
            NewShareTask.deleteObjectArray([task])
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
    var share:ShareThing!
    var shareTags:[SharelinkTag]!
    var sendFileKey:SendFileKey!
}
