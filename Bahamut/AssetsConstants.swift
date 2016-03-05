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
    static var SharelinkFilmFilePath:String = {
        return Sharelink.mainBundle().pathForResource("SharelinkFilm", ofType:"mp4")!
    }()
}

struct  ImageAssetsConstants
{
    static let defaultCustomSRCIcon = UIImage.namedImageInSharelink("new_share_header_icon_csrc")
    static let defaultAvatar = "defaultAvatar"
    static let defaultViewImage = "defaultView"
    static let defaultAvatarPath = Sharelink.mainBundle().pathForResource("defaultAvatar", ofType: "png")!
}


//MARK: Set avatar Util
extension FileService
{
    func setAvatar(imageView:UIImageView,iconFileId fileId:String!)
    {
        dispatch_async(dispatch_get_main_queue()) { () -> Void in
            imageView.image = PersistentManager.sharedInstance.getImage(ImageAssetsConstants.defaultAvatar,bundle: Sharelink.mainBundle())
            if String.isNullOrWhiteSpace(fileId) == false
            {
                if let uiimage =  PersistentManager.sharedInstance.getImage( fileId ,bundle: Sharelink.mainBundle())
                {
                    imageView.image = uiimage
                }else
                {
                    self.fetchFile(fileId, fileType: FileType.Image, callback: { (filePath) -> Void in
                        if filePath != nil
                        {
                            dispatch_async(dispatch_get_main_queue(), { () -> Void in
                                imageView.image = PersistentManager.sharedInstance.getImage(fileId,bundle: Sharelink.mainBundle())
                            })
                        }
                    })
                }
            }
        }
    }
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