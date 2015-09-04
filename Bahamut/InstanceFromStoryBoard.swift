//
//  UIViewControllerInstanceFromStoryBoard.swift
//  Bahamut
//
//  Created by AlexChow on 15/9/5.
//  Copyright © 2015年 GStudio. All rights reserved.
//

import Foundation
import UIKit

class UIViewControllerStoryBoardMap
{
    func initMap()
    {
        _ = NSBundle.mainBundle()
    }
    
}

extension UIViewController
{
    static func instanceFromStoryBoard(storyBoardName:String,identifier:String) -> UIViewController
    {
        let storyBoard = UIStoryboard(name: storyBoardName, bundle: NSBundle.mainBundle())
        return storyBoard.instantiateViewControllerWithIdentifier(identifier)
    }
}