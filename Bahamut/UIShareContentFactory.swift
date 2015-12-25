//
//  UIShareContentFactory.swift
//  Bahamut
//
//  Created by AlexChow on 15/11/30.
//  Copyright © 2015年 GStudio. All rights reserved.
//

import Foundation


class UIShareContentTypeDelegateGenerator
{
    static func getDelegate(shareType:ShareThingType) -> UIShareContentDelegate!
    {
        return getDelegate(shareType.rawValue)
    }
    
    static func getDelegate(shareType:String) -> UIShareContentDelegate!
    {
        switch(shareType)
        {
            case ShareThingType.shareFilm.rawValue : return FilmContent()
            case ShareThingType.shareUrl.rawValue : return UrlContent()
            case ShareThingType.shareText.rawValue : return TextContent()
            case ShareThingType.shareImage.rawValue : return ImageContent()
            default:return nil
        }
    }
}