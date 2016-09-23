//
//  ImageUtil.swift
//  Bahamut
//
//  Created by AlexChow on 15/8/15.
//  Copyright © 2015年 GStudio. All rights reserved.
//

import Foundation
import UIKit
import AVFoundation
class ImageUtil
{
    class func getVideoThumbImage(videoURL:String) -> UIImage?
    {
        return generateThumb(videoURL)
    }
    
    class func generateThumb(videoURL:String) -> UIImage?
    {
        var thumb:UIImage!
        let asset:AVURLAsset = AVURLAsset(URL: NSURL(fileURLWithPath:videoURL))
        
        let gen:AVAssetImageGenerator = AVAssetImageGenerator(asset:asset)
        
        gen.appliesPreferredTrackTransform = true
        
        let time:CMTime = CMTimeMakeWithSeconds(1, asset.duration.timescale)
        
        do{
            let image:CGImageRef = try gen.copyCGImageAtTime(time,actualTime:nil)
            thumb = UIImage(CGImage: image)
            return thumb
        }catch
        {
            return nil
        }
    }
    
    class func getVideoThumbImageData(videoURL:String,compressionQuality: CGFloat) -> NSData?
    {
        if let thumb:UIImage = generateThumb(videoURL)
        {
            return UIImageJPEGRepresentation(thumb, compressionQuality)
        }
        return nil
    }
    
    class func getVideoThumbImageBase64String(videoURL:String,compressionQuality: CGFloat) -> String?
    {
        if let thumbData = getVideoThumbImageData(videoURL, compressionQuality: compressionQuality)
        {
            return thumbData.base64UrlEncodedString()
        }
        return nil
    }
    
    class func getImageFromBase64String(base64:String) -> UIImage?
    {
        if let thumbData = NSData(base64UrlEncodedString: base64)
        {
            if let thumb = UIImage(data: thumbData, scale: 1.0)
            {
                return thumb
            }
        }
        return nil
    }
    
    class func getImageThumbImage(imageURL:String) -> UIImage?
    {
        return UIImage(contentsOfFile: imageURL)
    }

}

extension UIImage
{
    static func namedImageInBundle(named:String, inBundle:NSBundle) -> UIImage?
    {
        return UIImage(named: named, inBundle: inBundle, compatibleWithTraitCollection: nil)
    }
}

extension UIImage
{
    
    func scaleToWidthOf(width:CGFloat,quality:CGFloat = 1) -> UIImage
    {
        let originWidth = self.size.width
        let a = width / originWidth
        let size = CGSizeMake(width, self.size.height * a)
        return scaleToSize(size,quality: quality)
    }
    
    func scaleToHeightOf(height:CGFloat,quality:CGFloat = 1) -> UIImage
    {
        let originHeight = self.size.height
        let a = height / originHeight
        let size = CGSizeMake(self.size.width * a, height)
        return scaleToSize(size,quality: quality)
    }
    
    func scaleToSize(asize:CGSize,quality:CGFloat = 1) -> UIImage
    {
        let imgCopy = UIImage(data: self.generateImageDataOfQuality(quality)!)!
        UIGraphicsBeginImageContext(asize)
        imgCopy.drawInRect(CGRectMake(0, 0, asize.width, asize.height))
        let newimage = UIGraphicsGetImageFromCurrentImageContext()!
        UIGraphicsEndImageContext()
        return newimage
    }
    
    func generateImageDataOfQuality(quality:CGFloat) -> NSData?
    {
        return UIImageJPEGRepresentation(self, quality)
    }
    
}

extension UIView{
    func viewToImage()->UIImage{
        UIGraphicsBeginImageContext(self.bounds.size)
        self.drawViewHierarchyInRect(self.bounds, afterScreenUpdates: true)
        let screenshot = UIGraphicsGetImageFromCurrentImageContext()!
        UIGraphicsEndImageContext()
        return screenshot
    }
}

extension UIImageView{
    
    func convertPointFromImage(imagePoint:CGPoint) -> CGPoint? {
        if self.image == nil{
            return nil
        }
        var viewPoint = imagePoint
        
        let imageSize = self.image!.size
        let viewSize  = self.bounds.size
        
        let ratioX = viewSize.width / imageSize.width
        let ratioY = viewSize.height / imageSize.height
        
        let contentMode = self.contentMode
        
        var scale:CGFloat = 0
        
        if (contentMode == .ScaleAspectFit) {
            scale = min(ratioX, ratioY)
        }
        else /*if (contentMode == UIViewContentModeScaleAspectFill)*/ {
            scale = max(ratioX, ratioY)
        }
        
        viewPoint.x *= scale
        viewPoint.y *= scale
        
        viewPoint.x += (viewSize.width  - imageSize.width  * scale) / 2.0
        viewPoint.y += (viewSize.height - imageSize.height * scale) / 2.0
        
        return viewPoint
    }
    
    func convertRectFromImage(imageRect:CGRect) -> CGRect?{
        if self.image == nil{
            return nil
        }
        var viewRect = imageRect
        
        let imageSize = self.image!.size
        let viewSize  = self.bounds.size
        
        let ratioX = viewSize.width / imageSize.width
        let ratioY = viewSize.height / imageSize.height
        
        let contentMode = self.contentMode
        
        var scale:CGFloat = 0
        
        if (contentMode == .ScaleAspectFit) {
            scale = min(ratioX, ratioY)
        }
        else /*if (contentMode == UIViewContentModeScaleAspectFill)*/ {
            scale = max(ratioX, ratioY)
        }
        
        viewRect.origin.x *= scale
        viewRect.origin.y *= scale
        viewRect.size.width *= scale
        viewRect.size.height *= scale
        
        viewRect.origin.x += (viewSize.width  - imageSize.width  * scale) / 2.0
        viewRect.origin.y += (viewSize.height - imageSize.height * scale) / 2.0
        
        return viewRect
    }
}
