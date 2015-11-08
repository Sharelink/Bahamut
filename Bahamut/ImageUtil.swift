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
    class func getVideoThumbImage(videoURL:String) -> UIImage
    {
        if let thumb = generateThumb(videoURL)
        {
            return thumb
        }else
        {
            return UIImage(named:"file")!
        }
    }
    
    class func generateThumb(videoURL:String) -> UIImage?
    {
        var thumb:UIImage!
        let asset:AVURLAsset = AVURLAsset(URL: NSURL(fileURLWithPath:videoURL))
        
        let gen:AVAssetImageGenerator = AVAssetImageGenerator(asset:asset)
        
        gen.appliesPreferredTrackTransform = true
        
        let time:CMTime = CMTimeMakeWithSeconds(1, asset.duration.timescale);
        
        do{
            let image:CGImageRef = try gen.copyCGImageAtTime(time,actualTime:nil)
            thumb = UIImage(CGImage: image)
            return thumb
        }catch
        {
            return nil
        }
    }
    
    class func getVideoThumbImageData(videoURL:String) -> NSData?
    {
        if let thumb:UIImage = generateThumb(videoURL)
        {
            return UIImageJPEGRepresentation(thumb, 0.7)
        }
        return nil
    }
    
    class func getVideoThumbImageBase64String(videoURL:String) -> String?
    {
        if let thumbData = getVideoThumbImageData(videoURL)
        {
            return thumbData.base64UrlEncodedString()
        }
        return nil
    }
    
    class func getThumbImageFromBase64String(base64:String) -> UIImage?
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
    
    class func getImageThumbImage(imageURL:String) -> UIImage
    {
        let image:UIImage = UIImage(contentsOfFile: imageURL)!
        return image
    }
    
    class func getSountIconImage() -> UIImage
    {
        let thumb = UIImage(named:"music")
        return thumb!
    }
    
    class func getTextFileIconImage() -> UIImage
    {
        let thumb = UIImage(named:"text_file")
        return thumb!
    }
}