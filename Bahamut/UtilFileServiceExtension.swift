//
//  UtilFileServiceExtension.swift
//  Bahamut
//
//  Created by AlexChow on 15/9/10.
//  Copyright © 2015年 GStudio. All rights reserved.
//

import Foundation
import UIKit

extension FileService
{
    func setHeadIcon(imageView:UIImageView,iconFileId:String!)
    {
        if let fileId = iconFileId
        {
            if let uiimage =  PersistentManager.sharedInstance.getImage( fileId )
            {
                imageView.image = uiimage
            }else
            {
                getFileByFileId(fileId,fileType: FileType.Image, returnCallback: { (filePath) -> Void in
                    if filePath != nil
                    {
                        imageView.image = PersistentManager.sharedInstance.getImage(fileId)
                    }else
                    {
                        imageView.image = PersistentManager.sharedInstance.getImage(ImageAssetsConstants.defaultHeadIcon)
                    }
                })
            }
        }else
        {
            imageView.image = PersistentManager.sharedInstance.getImage(ImageAssetsConstants.defaultHeadIcon)
        }
    }
}