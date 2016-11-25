//
//  ImageUtil+Base64.swift
//  Vessage
//
//  Created by Alex Chow on 2016/11/25.
//  Copyright © 2016年 Bahamut. All rights reserved.
//

import Foundation
extension ImageUtil{
    
    class func getVideoThumbImageBase64String(videoURL:String,compressionQuality: CGFloat) -> String?
    {
        if let thumbData = getVideoThumbImageData(videoURL, compressionQuality: compressionQuality)
        {
            return thumbData.base64UrlEncodedString()
        }
        return nil
    }
    
    class func getVideoThumbImageBase64String(base64:String) -> UIImage?
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
    
}
