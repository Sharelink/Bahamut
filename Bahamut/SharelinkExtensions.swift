//
//  SharelinkExtensions.swift
//  Sharelink
//
//  Created by AlexChow on 16/1/25.
//  Copyright © 2016年 GStudio. All rights reserved.
//

import Foundation
import UIKit

extension UIImage
{
    static func namedImageInSharelink(named:String) -> UIImage?
    {
        return UIImage.namedImageInBundle(named, inBundle: Sharelink.mainBundle())
    }
}

extension String
{
    func localizedString() -> String{
        return NSLocalizedString(self, tableName: "Localizable", bundle: Sharelink.mainBundle(), value: "", comment: "")
    }
}

extension UIViewController
{
    func showAppVersionOnlyTips()
    {
        self.playToast("App Version Only")
    }
}