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
    
    override func viewDidAppear(animated: Bool) {
        super.viewDidAppear(animated)
        registerForKeyboardNotifications()
        initMytags()
    }
    
    override func viewDidDisappear(animated: Bool) {
        super.viewDidDisappear(animated)
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
        UIView.commitAnimations()
    }
    
    private func hideMyTagsCollection()
    {
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
    
    var activeTextField:UIView!
    var originCenter:CGPoint!
    
    func removeObserverForKeyboardNotifications()
    {
        NSNotificationCenter.defaultCenter().removeObserver(self, name: UIKeyboardWillShowNotification, object: nil)
        NSNotificationCenter.defaultCenter().removeObserver(self, name: UIKeyboardWillHideNotification, object: nil)
    }
    
    func registerForKeyboardNotifications()
    {
        NSNotificationCenter.defaultCenter().addObserver(self, selector: "keyboardWasShown:", name: UIKeyboardDidShowNotification, object: nil)
        NSNotificationCenter.defaultCenter().addObserver(self, selector: "keyboardWillBeHidden:", name: UIKeyboardWillHideNotification, object: nil)
    }
    
    func keyboardWasShown(aNotification:NSNotification)
    {
        let info = aNotification.userInfo!
        
        if let kbRect = info[UIKeyboardFrameEndUserInfoKey]!.CGRectValue
        {
            let tfFrame = activeTextField.frame
            let kbHeight = kbRect.height + 7
            let bottom = view.frame.height - tfFrame.origin.y - kbHeight - tfFrame.height
            if bottom < 0
            {
                var animationDuration:NSTimeInterval
                var animationCurve:UIViewAnimationCurve
                let curve = info[UIKeyboardAnimationCurveUserInfoKey] as! Int
                animationCurve = UIViewAnimationCurve(rawValue: curve)!
                animationDuration = info[UIKeyboardAnimationDurationUserInfoKey] as! NSTimeInterval
                
                UIView.beginAnimations(nil, context:nil)
                UIView.setAnimationDuration(animationDuration)
                UIView.setAnimationCurve(animationCurve)
                
                originCenter = view.center
                view.center.y += bottom
                view.layoutIfNeeded()
                
                UIView.commitAnimations()
            }
        }
    }
    
    func keyboardWillBeHidden(aNotification:NSNotification)
    {
        if let ocenter = originCenter
        {
            view.center = ocenter
            originCenter = nil
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
    
    func textFieldDidBeginEditing(textField: UITextField)
    {
        activeTextField = textField
        
    }
    
    
    func textFieldDidEndEditing(textField: UITextField) {
        activeTextField = nil
    }

    
    var shareThingModel:ShareThing!{
        didSet{
            if shareContentContainer != nil
            {
                shareContentContainer.shareThing = shareThingModel
            }
        }
    }
    
    func textViewDidBeginEditing(textView: UITextView) {
        activeTextField = textView
    }
    
    func textViewDidEndEditing(textView: UITextView) {
        
        activeTextField = nil
    }
    
    func textViewDidChange(textView: UITextView) {
        shareThingModel.title = textView.text
    }
    
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
                    let newShare = ShareThing()
                    newShare.title = self.shareDescriptionTextArea.text
                    newShare.shareContent = fileId
                    newShare.shareType = ShareType.filmType.rawValue
                    
                    ProgressTaskWatcher.sharedInstance.addTaskObserver(fileId, delegate: self)
                    fService.startSendFile(fileId)
                    self.view.makeToastActivityWithMessage(message: "Posting")
                    sService.postNewShare(newShare, tags: self.selectedTagController.tags ,callback: { (isSuc) -> Void in
                        self.view.hideToastActivity()
                        if isSuc
                        {
                            self.view.makeToast(message: "Post New Share Success")
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
    
    func taskProgress(taskIdentifier: String, persent: Float) {
        print(persent)
    }
    
    func taskCompleted(taskIdentifier: String, result: AnyObject!) {
        print("completed")
        ProgressTaskWatcher.sharedInstance.removeTaskObserver(taskIdentifier, delegate: self)
    }
    
    func taskFailed(taskIdentifier: String, result: AnyObject!) {
        print("failed")
        ProgressTaskWatcher.sharedInstance.removeTaskObserver(taskIdentifier, delegate: self)
    }
    
    func testupload()
    {
        let fService = ServiceContainer.getService(FileService)
        fService.getFileByFileId(FilmAssetsConstants.defaultPersonalFilm,fileType: FileType.Video) { (filePath) -> Void in
            if let localFilmPath = filePath
            {
                self.view.makeToastActivityWithMessage(message: "Sending Film")
                fService.requestFileId(localFilmPath, type: FileType.Video, callback: { (fileId) -> Void in
                    self.view.hideToastActivity()
                    if fileId != nil
                    {
                        ProgressTaskWatcher.sharedInstance.addTaskObserver(fileId, delegate: self)
                        fService.startSendFile(fileId)
                    }
                })
                
            }else
            {
                self.view.makeToast(message: "must select or capture a film!")
            }
        }
        
    }

    static func instanceFromStoryBoard() -> NewShareViewController
    {
        return instanceFromStoryBoard("Main", identifier: "newShareViewController") as! NewShareViewController
    }
}
