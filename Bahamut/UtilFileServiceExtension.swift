//
//  UtilFileServiceExtension.swift
//  Bahamut
//
//  Created by AlexChow on 15/9/10.
//  Copyright © 2015年 GStudio. All rights reserved.
//

import Foundation
import UIKit
import SharelinkSDK

extension FileService
{
    func setAvatar(imageView:UIImageView,iconFileId:String!)
    {
        dispatch_async(dispatch_get_main_queue()) { () -> Void in
            imageView.image = PersistentManager.sharedInstance.getImage(ImageAssetsConstants.defaultAvatar)
            if let fileId = iconFileId
            {
                if let uiimage =  PersistentManager.sharedInstance.getImage( fileId )
                {
                    imageView.image = uiimage
                }else
                {
                    self.fetch(fileId, fileType: FileType.Image, callback: { (filePath) -> Void in
                        if filePath != nil
                        {
                            imageView.image = PersistentManager.sharedInstance.getImage(fileId)
                        }
                    })
                }
            }
        }
    }
}