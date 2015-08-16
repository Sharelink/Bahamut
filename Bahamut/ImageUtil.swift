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
        var thumb:UIImage!
        let asset:AVURLAsset = AVURLAsset(URL: NSURL(fileURLWithPath:videoURL))
        
        let gen:AVAssetImageGenerator = AVAssetImageGenerator(asset:asset)
        
        gen.appliesPreferredTrackTransform = true
        
        let time:CMTime = CMTimeMakeWithSeconds(1, asset.duration.timescale);
        
        do{
            let image:CGImageRef = try gen.copyCGImageAtTime(time,actualTime:nil)
            thumb = UIImage(CGImage: image)
        }catch let error as NSError
        {
            print(error.description)
            thumb = UIImage(named:"file")
        }
        return thumb;
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