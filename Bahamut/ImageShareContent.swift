//
//  ImageShareContent.swift
//  Bahamut
//
//  Created by AlexChow on 15/12/26.
//  Copyright © 2015年 GStudio. All rights reserved.
//

import Foundation
import UIKit

class ImageContent:NSObject,UIShareContentDelegate
{
    private var rows:Int = 0
    private var itemsPerRow:Int = 3
    private var thumbImageSize = CGSizeMake(98, 98)
    private var maxThumbSize = CGSizeMake(168,168)
    private let imageSpace = CGFloat(7)
    private var thumbImages:[UIImage]!
    private var shareCell:UIShareThing!
    private var imageContentModel:ShareImageContentModel!
    private var view = UIView(){
        didSet{
            view.backgroundColor = UIColor.whiteColor()
            view.userInteractionEnabled = true
        }
    }
    private var imageViews = [UIImageView]()
    private var pWidth:CGFloat{
        return thumbImageSize.width + imageSpace
    }
    
    private var pHeight:CGFloat{
        return thumbImageSize.height + imageSpace
    }
    
    private func calRows(width:CGFloat,imageCount:Int)
    {
        var oneRowItem = itemsPerRow
        if imageCount < itemsPerRow
        {
            oneRowItem = imageCount
        }
        let perRow = CGFloat(oneRowItem)
        let hw = (width - (perRow + 1) * imageSpace) / perRow
        thumbImageSize = CGSizeMake(min(hw,maxThumbSize.width), min(hw,maxThumbSize.height))
        rows = Int((imageCount + itemsPerRow - 1) / itemsPerRow)
    }
    
    class ImageHubImageProvider: NSObject,ImageProvider,ProgressTaskDelegate
    {
        private var hubFileId:String!
        private var images:[UIImage]!
        private var observer:LoadImageObserver!
        private var thumbnails = [UIImage]()
        private var imageCount:Int = 0
        
        init(hubFileId:String,thumbnails:[UIImage])
        {
            self.hubFileId = hubFileId
            self.thumbnails = thumbnails
            self.imageCount = thumbnails.count
        }
        
        func getImageCount() -> Int {
            return imageCount
        }
        
        func getThumbnail(index: Int) -> UIImage? {
            if index < thumbnails.count{
                return thumbnails[index]
            }
            return nil
        }
        
        func registImagePlayerObserver(observer: LoadImageObserver) {
            self.observer = observer
        }
        
        func startLoad(index: Int) {
            if images != nil && index < images.count
            {
                if observer != nil
                {
                    observer.imageLoaded(index, image: images[index])
                }
            }else
            {
                let fileService = ServiceContainer.getService(FileService)
                
                if let path = fileService.getFilePath(hubFileId, type: .NoType){
                    taskCompleted(hubFileId, result: path)
                }else
                {
                    ProgressTaskWatcher.sharedInstance.addTaskObserver(hubFileId, delegate: self)
                    ServiceContainer.getService(FileService).fetchFile(self.hubFileId, fileType: .NoType, callback: { (filePath) -> Void in
                    })
                }
                
            }
        }
        
        func taskCompleted(taskIdentifier: String, result: AnyObject!) {
            
            if let filePath = result as? String
            {
                if let json = PersistentFileHelper.readTextFile(filePath)
                {
                    let imageHubModel = ShareImageHub(json: json)
                    images = [UIImage]()
                    for imgString in imageHubModel.imagesBase64
                    {
                        let image = ImageUtil.getImageFromBase64String(imgString)
                        images.append(image!)
                    }
                }
            }
            
            if let handler = observer?.imageLoaded
            {
                for i in 0..<imageCount
                {
                    handler(i,image: images[i])
                }
            }
        }
        
        func taskFailed(taskIdentifier: String, result: AnyObject!) {
            if let handler = observer?.imageLoadError
            {
                for i in 0..<imageCount
                {
                    handler(i)
                }
            }
        }
        
        func taskProgress(taskIdentifier: String, persent: Float) {
            if let handler = observer?.imageLoadingProgress
            {
                let progress = persent / 100
                for i in 0..<imageCount
                {
                    handler(i,progress: progress)
                }
            }
        }
    }
    
    func onTapImageView(a:UITapGestureRecognizer)
    {
        if let imgView = a.view as? UIImageView
        {
            let imageIndex = imgView.tag
            UIImagePlayerController.showImagePlayer(shareCell.rootController, imageProvider: ImageHubImageProvider(hubFileId: imageContentModel.imagesFileId,thumbnails: self.thumbImages),imageIndex: imageIndex)
        }
    }
    
    func initContent(shareCell: UIShareThing, share: ShareThing) {
        self.shareCell = shareCell
        if let shareContent = share.shareContent
        {
            self.imageContentModel = ShareImageContentModel(json:shareContent)
            let images = imageContentModel.thumbImgs.map{ImageUtil.getImageFromBase64String($0)}.filter{$0 != nil}.map{$0!}
            self.thumbImages = images
            let width = shareCell.rootController.view.bounds.width - 23
            calRows(width, imageCount: images.count)
        }else
        {
            self.thumbImages.removeAll()
            self.thumbImageSize = CGSizeZero
            self.rows = 0
        }
        
    }
    
    func getContentFrame(sender: UIShareThing, share: ShareThing?) -> CGRect {
        let width = sender.rootController.view.bounds.width - 23
        let height = pHeight * CGFloat(rows)
        self.view.frame = CGRectMake(0,0,width,height)
        return view.frame
    }
    
    func getContentView(sender: UIShareContent, share: ShareThing?) -> UIView {
        for i in 0..<rows
        {
            for j in 0..<itemsPerRow
            {
                let index = i * itemsPerRow + j
                if imageViews.count == index
                {
                    let img = UIImageView()
                    img.userInteractionEnabled = true
                    img.clipsToBounds = true
                    img.contentMode = .ScaleAspectFill
                    let tapGes = UITapGestureRecognizer(target: self, action: #selector(ImageContent.onTapImageView(_:)))
                    img.addGestureRecognizer(tapGes)
                    imageViews.append(img)
                    
                }
                let imgView = imageViews[index]
                imgView.frame = CGRectMake( CGFloat(j) * pWidth, CGFloat(i) * pHeight, thumbImageSize.width, thumbImageSize.height)
                view.addSubview(imgView)
            }
            
        }
        return view
    }
    
    func refresh(sender: UIShareContent, share: ShareThing?){
        for i in 0..<thumbImages.count{
            let img = imageViews[i]
            img.tag = i
            img.image = thumbImages[i]
        }
    }
    
}