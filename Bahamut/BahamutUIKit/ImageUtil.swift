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
    class func getVideoThumbImage(_ videoURL:String) -> UIImage?
    {
        return generateThumb(videoURL)
    }
    
    class func generateThumb(_ videoURL:String) -> UIImage?
    {
        var thumb:UIImage!
        let asset:AVURLAsset = AVURLAsset(url: URL(fileURLWithPath:videoURL))
        
        let gen:AVAssetImageGenerator = AVAssetImageGenerator(asset:asset)
        
        gen.appliesPreferredTrackTransform = true
        
        let time:CMTime = CMTimeMakeWithSeconds(1, asset.duration.timescale)
        
        do{
            let image:CGImage = try gen.copyCGImage(at: time,actualTime:nil)
            thumb = UIImage(cgImage: image)
            return thumb
        }catch
        {
            return nil
        }
    }
    
    class func getVideoThumbImageData(_ videoURL:String,compressionQuality: CGFloat) -> Data?
    {
        if let thumb:UIImage = generateThumb(videoURL)
        {
            return UIImageJPEGRepresentation(thumb, compressionQuality)
        }
        return nil
    }
    
    class func getImageThumbImage(_ imageURL:String) -> UIImage?
    {
        return UIImage(contentsOfFile: imageURL)
    }

}

extension UIImage
{
    static func namedImageInBundle(_ named:String, inBundle:Bundle) -> UIImage?
    {
        return UIImage(named: named, in: inBundle, compatibleWith: nil)
    }
}

extension UIImage
{
    
    func scaleToWidthOf(_ width:CGFloat,quality:CGFloat = 1,isPNG:Bool = false) -> UIImage
    {
        let originWidth = self.size.width
        let a = width / originWidth
        let size = CGSize(width: width, height: self.size.height * a)
        return scaleToSize(size,quality: quality,isPNG: isPNG)
    }
    
    func scaleToHeightOf(_ height:CGFloat,quality:CGFloat = 1,isPNG:Bool = false) -> UIImage
    {
        let originHeight = self.size.height
        let a = height / originHeight
        let size = CGSize(width: self.size.width * a, height: height)
        return scaleToSize(size,quality: quality,isPNG: isPNG)
    }
    
    func scaleToSize(_ asize:CGSize,quality:CGFloat = 1,isPNG:Bool = false) -> UIImage
    {
        let imgCopy = UIImage(data: self.generateImageDataOfQuality(quality,isPNG: isPNG)!)!
        UIGraphicsBeginImageContext(asize)
        imgCopy.draw(in: CGRect(x: 0, y: 0, width: asize.width, height: asize.height))
        let newimage = UIGraphicsGetImageFromCurrentImageContext()!
        UIGraphicsEndImageContext()
        return newimage
    }
    
    func generateImageDataOfQuality(_ quality:CGFloat,isPNG:Bool = false) -> Data?
    {
        return UIImageJPEGRepresentation(self, quality)
    }
    
}

extension UIView{
    func viewToImage()->UIImage?{
        
        UIGraphicsBeginImageContextWithOptions(self.frame.size, false, UIScreen.main.scale)
        self.drawHierarchy(in: self.bounds, afterScreenUpdates: true)
        let image = UIGraphicsGetImageFromCurrentImageContext()
        UIGraphicsEndImageContext()
        return image
    }
}

extension UIImageView{
    
    func convertPointFromImage(_ imagePoint:CGPoint) -> CGPoint? {
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
        
        if (contentMode == .scaleAspectFit) {
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
    
    func convertRectFromImage(_ imageRect:CGRect) -> CGRect?{
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
        
        if (contentMode == .scaleAspectFit) {
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
