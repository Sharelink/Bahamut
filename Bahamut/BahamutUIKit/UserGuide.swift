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
class UserGuide:NSObject
{
    fileprivate var viewController:UIViewController!
    fileprivate var guideImages:[UIImage]!
    fileprivate var userId:String!
    fileprivate var showingIndex:Int = 0
    fileprivate var imgController:NoStatusBarViewController!
    fileprivate var imageView:UIImageView!
    fileprivate var isInited:Bool = false
    func initGuide<T:UIViewController>(_ controller:T,userId:String,guideImgs:[UIImage])
    {
        viewController = controller
        guideImages = guideImgs
        self.userId = userId
        initImageViewController()
        isInited = true
        
        let className = T.description()
        firstTimeStoreKey = "showGuideMark:\(self.userId!)\(className)"
    }
    
    fileprivate var firstTimeStoreKey:String!
    
    fileprivate func initImageViewController()
    {
        imgController = NoStatusBarViewController()
        imgController.view.frame = (UIApplication.shared.keyWindow?.bounds)!
        imageView = UIImageView(frame: imgController.view.bounds)
        imgController.view.addSubview(imageView)
        self.imgController.view.addGestureRecognizer(UITapGestureRecognizer(target: self, action: #selector(UserGuide.onTapImage(_:))))
    }
    
    func deInitUserGuide()
    {
        isInited = false
        self.viewController = nil
        self.imageView = nil
        self.imgController = nil
        self.guideImages = nil
        self.firstTimeStoreKey = nil
    }
    
    func onTapImage(_:UITapGestureRecognizer)
    {
        showNextImage()
    }
    
    fileprivate func showNextImage()
    {
        self.showingIndex += 1
        if showingIndex >= self.guideImages.count
        {
            self.viewController.dismiss(animated: false, completion: {
                self.deInitUserGuide()
            })
        }else
        {
            self.imageView.image = self.guideImages[self.showingIndex]
        }
    }
    
    func showGuide() -> Bool
    {
        if isInited && self.guideImages != nil && self.guideImages.count > 0
        {
            self.showingIndex = -1
            self.viewController.present(imgController, animated: true, completion: {
                self.showNextImage()
            })
            return true
        }
        return false
    }
    
    func showGuideControllerPresentFirstTime()  -> Bool
    {
        if isInited && self.guideImages != nil && self.guideImages.count > 0
        {
            let key = firstTimeStoreKey
            let showed = UserDefaults.standard.bool(forKey: key!)
            if !showed
            {
                UserDefaults.standard.set(true, forKey: key!)
                return showGuide()
            }else
            {
                deInitUserGuide()
            }
        }
        return false
    }
}
