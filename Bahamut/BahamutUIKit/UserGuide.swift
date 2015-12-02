//
//  UserGuide.swift
//  Bahamut
//
//  Created by AlexChow on 15/12/2.
//  Copyright © 2015年 GStudio. All rights reserved.
//

import Foundation
import UIKit

//MARK: UserGuide
public class UserGuide:NSObject
{
    private var viewController:UIViewController!
    private var guideImages:[UIImage]!
    private var userId:String!
    private var showingIndex:Int = 0
    private var imgController:NoStatusBarViewController!
    private var imageView:UIImageView!
    private var isInited:Bool = false
    public func initGuide<T:UIViewController>(controller:T,userId:String,guideImgs:[UIImage])
    {
        viewController = controller
        guideImages = guideImgs
        self.userId = userId
        initImageViewController()
        isInited = true
        
        let className = T.description()
        firstTimeStoreKey = "showGuideMark:\(self.userId)\(className)"
    }
    
    private var firstTimeStoreKey:String!
    
    private func initImageViewController()
    {
        imgController = NoStatusBarViewController()
        imgController.view.frame = (UIApplication.sharedApplication().keyWindow?.bounds)!
        imageView = UIImageView(frame: imgController.view.bounds)
        imgController.view.addSubview(imageView)
        self.imgController.view.addGestureRecognizer(UITapGestureRecognizer(target: self, action: "onTapImage:"))
    }
    
    public func deInitUserGuide()
    {
        isInited = false
        self.viewController = nil
        self.imageView = nil
        self.imgController = nil
        self.guideImages = nil
        self.firstTimeStoreKey = nil
    }
    
    public func onTapImage(_:UITapGestureRecognizer)
    {
        showNextImage()
    }
    
    private func showNextImage()
    {
        self.showingIndex++
        if showingIndex >= self.guideImages.count
        {
            self.viewController.dismissViewControllerAnimated(false, completion: {
                self.deInitUserGuide()
            })
        }else
        {
            self.imageView.image = self.guideImages[self.showingIndex]
        }
    }
    
    public func showGuide()
    {
        if isInited && self.guideImages != nil && self.guideImages.count > 0
        {
            self.showingIndex = -1
            self.viewController.presentViewController(imgController, animated: true, completion: {
                self.showNextImage()
            })
        }
    }
    
    public func showGuideControllerPresentFirstTime()
    {
        if isInited && self.guideImages != nil && self.guideImages.count > 0
        {
            let key = firstTimeStoreKey
            let showed = NSUserDefaults.standardUserDefaults().boolForKey(key)
            if !showed
            {
                NSUserDefaults.standardUserDefaults().setBool(true, forKey: key)
                showGuide()
            }else
            {
                deInitUserGuide()
            }
        }
    }
}