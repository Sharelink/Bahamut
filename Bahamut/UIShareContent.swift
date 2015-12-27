//
//  UIShareContent.swift
//  Bahamut
//
//  Created by AlexChow on 15/7/28.
//  Copyright (c) 2015年 GStudio. All rights reserved.
//

import UIKit
import AVFoundation
import EVReflection

protocol UIShareContentDelegate
{
    func initContent(shareCell:UIShareThing,share:ShareThing)
    func refresh(sender:UIShareContent,share:ShareThing?)
    func getContentView(sender: UIShareContent, share: ShareThing?) -> UIView
    func getContentFrame(sender: UIShareThing, share: ShareThing?) -> CGRect
}

class UIShareContent: UIView
{
    var shareCell:UIShareThing!
    var delegate:UIShareContentDelegate!
    var share:ShareThing!{
        didSet{
            if contentView != nil
            {
                contentView.removeFromSuperview()
            }
            contentView = delegate.getContentView(self, share: share)
            self.addSubview(contentView)
        }
    }
    
    func update()
    {
        if delegate != nil && contentView != nil
        {
            self.delegate.refresh(self, share: self.share)
        }
    }
    
    deinit{
        if contentView != nil
        {
            contentView.removeFromSuperview()
            contentView = nil
        }
    }
    
    private(set) var contentView:UIView!
}
