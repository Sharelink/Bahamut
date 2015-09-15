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

class NewShareViewController: UIViewController,UICameraViewControllerDelegate,UITextViewDelegate,UIResourceExplorerDelegate,UITextFieldDelegate,UITagCollectionViewControllerDelegate
{
    static let tagsLimit = 7
    override func viewDidLoad() {
        super.viewDidLoad()
        if shareThingModel == nil
        {
            shareThingModel = ShareThing()
        }
    }
    
    override func viewDidAppear(animated: Bool) {
        super.viewDidAppear(animated)
        registerForKeyboardNotifications()
    }
    
    override func viewDidDisappear(animated: Bool) {
        super.viewDidDisappear(animated)
        NSNotificationCenter.defaultCenter().removeObserver(self)
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
    
    @IBOutlet weak var scrollView: UIScrollView!{
        didSet{
            scrollView.userInteractionEnabled = true
            scrollView.addGestureRecognizer(UITapGestureRecognizer(target: self, action: "hideKBoard:"))
        }
    }
    
    func hideKBoard(_:UITapGestureRecognizer)
    {
        if activeTextField != nil
        {
            activeTextField.resignFirstResponder()
        }
        hideKeyBoard()
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
    
    var myTagController:UITagCollectionViewController!{
        didSet{
            myTagController.delegate = self
            self.addChildViewController(myTagController)
        }
    }
    @IBOutlet weak var myTagCollectionViewContainer: UIView!{
        didSet{
            myTagCollectionViewContainer.layer.cornerRadius = 7
            myTagController = UITagCollectionViewController.instanceFromStoryBoard()
            myTagCollectionViewContainer.addSubview(myTagController.view)
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
            selectedTagViewContainer.layer.cornerRadius = 7
            selectedTagController  = UITagCollectionViewController.instanceFromStoryBoard()
            selectedTagViewContainer.addSubview(selectedTagController.view)
        }
    }
    
    override func viewWillLayoutSubviews() {
        super.viewWillLayoutSubviews()
        selectedTagController.view.frame = selectedTagViewContainer.bounds
        myTagController.view.frame = myTagCollectionViewContainer.bounds
    }
    
    @IBOutlet weak var newTagNameTextfield: UITextField!{
        didSet{
            newTagNameTextfield.delegate = self
        }
    }
    @IBAction func addTag()
    {
        if selectedTagController.tags != nil && selectedTagController.tags.count >= NewShareViewController.tagsLimit
        {
            view.makeToast(message: "can't not add more tags")
            return
        }
        if let newTagName = newTagNameTextfield.text?.stringByTrimmingCharactersInSet(NSCharacterSet.whitespaceCharacterSet())
        {
            if !newTagName.isEmpty
            {
                let newTag = UITagCellModel()
                newTag.tagColor = UIColor(hex: arc4random()).toHexString()
                newTag.tagName = newTagName
                newTagNameTextfield.text = nil
                if !selectedTagController.addTag(newTag)
                {
                    self.view.makeToast(message: "tags has been ready")
                }
                newTagNameTextfield.becomeFirstResponder()
                return
            }
        }
        view.makeToast(message: "tag can't be white space")
        newTagNameTextfield.becomeFirstResponder()
        
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
    
    func registerForKeyboardNotifications()
    {
        NSNotificationCenter.defaultCenter().addObserver(self, selector: "keyboardWasShown:", name: UIKeyboardDidShowNotification, object: nil)
        NSNotificationCenter.defaultCenter().addObserver(self, selector: "keyboardWillBeHidden:", name: UIKeyboardWillHideNotification, object: nil)
    }
    
    func keyboardWasShown(aNotification:NSNotification)
    {
        let info = aNotification.userInfo
        if let kbSize = info![UIKeyboardFrameBeginUserInfoKey]!.CGRectValue
        {
            let contentInsets = UIEdgeInsetsMake(0.0, 0.0, kbSize.size.height, 0.0)
            scrollView.contentInset = contentInsets
            scrollView.scrollIndicatorInsets = contentInsets
            
            var aRect = view.frame
            aRect.size.height -= kbSize.size.height
            if !CGRectContainsPoint(aRect, self.activeTextField.frame.origin)
            {
                let scrollPoint = CGPointMake(0.0, activeTextField.frame.origin.y - kbSize.size.height + activeTextField.bounds.height)
                scrollView.setContentOffset(scrollPoint, animated: true)
            }
        }
    }
    
    func keyboardWillBeHidden(aNotification:NSNotification)
    {
        let contentInsets = UIEdgeInsetsZero
        scrollView.contentInset = contentInsets
        scrollView.scrollIndicatorInsets = contentInsets
    }
    
    func textFieldDidBeginEditing(textField: UITextField) {
        activeTextField = textField
        
    }
    
    
    func textFieldDidEndEditing(textField: UITextField) {
        
        activeTextField = nil
    }

    
    var shareThingModel:ShareThing!{
        didSet{
            if shareContentContainer != nil
            {
                shareContentContainer.model = shareThingModel.shareContent
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
                            self.view.makeToast(message: "Post New Share Failed")
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
