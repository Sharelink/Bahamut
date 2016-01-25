//
//  AssetsConstants.swift
//  Bahamut
//
//  Created by AlexChow on 15/9/10.
//  Copyright © 2015年 GStudio. All rights reserved.
//

import Foundation
import UIKit

struct FilmAssetsConstants
{
    static let SharelinkFilm = "SharelinkFilm.mp4"
}

struct  ImageAssetsConstants
{
    static let defaultCustomSRCIcon = UIImage.namedImageInSharelink("new_share_header_icon_csrc")
    static let defaultAvatar = "defaultAvatar"
    static let defaultViewImage = "defaultView"
    static let defaultAvatarPath = Sharelink.mainBundle.pathForResource("defaultAvatar", ofType: "png")!
}

class UserGuideAssetsConstants
{
    class func getViewGuideImages(lang:String,viewName:String) -> [UIImage]
    {
        var imgs:[UIImage] = [UIImage]()
        var i = 0
        repeat
        {
            let imgName = "\(lang)_\(viewName)ViewGuide_\(i).jpg"
            if let img = UIImage.namedImageInSharelink(imgName){
                imgs.append(img)
            }else{
                return imgs
            }
            i++
        }while(true)
    }
}