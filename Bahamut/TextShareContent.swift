//
//  TextShareContent.swift
//  Bahamut
//
//  Created by AlexChow on 15/12/21.
//  Copyright © 2015年 GStudio. All rights reserved.
//

import Foundation
import UIKit

class TextContent: UIShareContentDelegate
{
    func initContent(shareCell: UIShareThing, share: ShareThing) {
        return
    }
    
    func refresh(sender: UIShareContent, share: ShareThing?)
    {
        
    }
    
    func getContentFrame(sender: UIShareThing, share: ShareThing?) -> CGRect {
        return CGRectZero
    }
    
    func getContentView(sender: UIShareContent, share: ShareThing?)-> UIView
    {
        return UIView()
    }
}