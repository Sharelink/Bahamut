//
//  NewShareViewController.swift
//  Bahamut
//
//  Created by AlexChow on 15/8/12.
//  Copyright (c) 2015年 GStudio. All rights reserved.
//

import UIKit

class NewShareViewController: UIViewController,UICameraViewControllerDelegate,UITextViewDelegate,UIFileCollectionControllerDelegate {

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
    
    var shareThingModel:ShareThing!{
        didSet{
            if shareContentContainer != nil
            {
                shareContentContainer.model = shareThingModel.content
            }
        }
    }
    
    func textViewDidChange(textView: UITextView) {
        shareThingModel.title = textView.text
    }
    
    func fileSelected(fileModel: UIFileCollectionCellModel, index: Int, sender: UIFileCollectionController!)
    {
        shareThingModel.content.content = fileModel.filePath
    }
    
    func fileDeSelected(fileModel: UIFileCollectionCellModel, index: Int, sender: UIFileCollectionController!)
    {
        shareThingModel.content.content = nil
    }
    
    func addFile(completedHandler: (fileModel: UIFileCollectionCellModel) -> Void, sender: UIFileCollectionController!) {

        ServiceContainer.getService(CameraService).showCamera(sender.navigationController!, delegate: nil) { (destination) -> Void in
            let fileService = ServiceContainer.getService(FileService)
            let newFilePath = fileService.createLocalStoreFileName(FileType.Video) + ".mp4"
            if fileService.moveFileTo(destination, destinationPath: newFilePath)
            {
                let videoFileModel = UIFileCollectionCellModel()
                videoFileModel.filePath = newFilePath
                videoFileModel.fileType = .Video
                completedHandler(fileModel: videoFileModel)
                sender.view.makeToast(message: "Video Saved")
            }else
            {
                sender.view.makeToast(message: "Save Video Failed")
            }
        }
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
        ServiceContainer.getService(FileService).showFileCollectionControllerView(self.navigationController!, files: files, delegate: self)
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
