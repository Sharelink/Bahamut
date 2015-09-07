//
//  TapViewBgHideKeyBoardExtension.swift
//  Bahamut
//
//  Created by AlexChow on 15/9/6.
//  Copyright © 2015年 GStudio. All rights reserved.
//

import UIKit

extension UIViewController
{
    
    override public func touchesBegan(touches: Set<UITouch>, withEvent event: UIEvent?) {
        super.touchesBegan(touches, withEvent: event)
        for sv in view.subviews
        {
            sv.resignFirstResponder()
        }
    }
}