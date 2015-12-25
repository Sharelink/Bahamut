//
//  ImageShareContent.swift
//  Bahamut
//
//  Created by AlexChow on 15/12/26.
//  Copyright © 2015年 GStudio. All rights reserved.
//

import Foundation
class ImageContent: UIShareContentDelegate
{
    func getContentFrame(sender: UIShareThing, share: ShareThing?) -> CGRect {
        return CGRectMake(0,0,sender.rootController.view.bounds.width - 23,128)
    }
    
    func getContentView(sender: UIShareContent, share: ShareThing?) -> UIView {
        return UIView()
    }
    
    func refresh(sender: UIShareContent, share: ShareThing?) {
        
    }
}