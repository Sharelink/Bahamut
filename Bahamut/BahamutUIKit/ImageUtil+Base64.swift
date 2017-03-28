//
//  ImageUtil+Base64.swift
//  Vessage
//
//  Created by Alex Chow on 2016/11/25.
//  Copyright © 2016年 Bahamut. All rights reserved.
//

import Foundation
extension ImageUtil{
    
    static func getVideoThumbImageBase64String(_ videoURL:String,compressionQuality: CGFloat) -> String?
    {
        if let thumbData = getVideoThumbImageData(videoURL, compressionQuality: compressionQuality)
        {
            return (thumbData as NSData).base64UrlEncodedString()
        }
        return nil
    }
    
    static func getVideoThumbImageBase64String(_ base64:String) -> UIImage?
    {
        if let thumbData = NSData(base64UrlEncodedString: base64)
        {
            if let thumb = UIImage(data: thumbData as Data, scale: 1.0)
            {
                return thumb
            }
        }
        return nil
    }
    
}
