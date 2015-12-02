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
    func refresh(sender:UIShareContent,share:ShareThing?)
    func getContentView(sender: UIShareContent, share: ShareThing?) -> UIView
}

protocol UIShareContentViewSetupDelegate
{
    func setupContentView(contentView:UIView, share:ShareThing)
}

class UIShareContent: UIView
{
    var delegate:UIShareContentDelegate!
    var setupContentViewDelegate:UIShareContentViewSetupDelegate!
    
    var share:ShareThing!{
        didSet{
            if contentView != nil
            {
                contentView.removeFromSuperview()
            }
            contentView = delegate.getContentView(self, share: share)
            if setupContentViewDelegate != nil
            {
                setupContentViewDelegate.setupContentView(contentView, share: share)
            }
            self.addSubview(contentView)
        }
    }
    
    func update()
    {
        self.backgroundColor = UIColor.clearColor()
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
