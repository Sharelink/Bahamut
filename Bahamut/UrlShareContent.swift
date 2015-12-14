//
//  UrlShareContent.swift
//  Bahamut
//
//  Created by AlexChow on 15/11/30.
//  Copyright © 2015年 GStudio. All rights reserved.
//

import Foundation
import EVReflection

class UrlContentView:UIView
{
    var model:UrlContentModel!
    var titleLable:UILabel!
    var linkImg:UIImageView!
    var bgImg:UIImageView!
    
    private func initViews()
    {
        if bgImg == nil
        {
            bgImg = UIImageView(image: UIImage(named: "webPageBg"))
            self.addSubview(bgImg)
            self.addGestureRecognizer(UITapGestureRecognizer(target: self, action: "onTapTitleLable:"))
            self.layer.borderColor = UIColor.lightGrayColor().CGColor
            self.layer.borderWidth = 1
        }
        
        if titleLable == nil
        {
            titleLable = UILabel()
            titleLable.textAlignment = .Left
            titleLable.numberOfLines = 2
            titleLable.font = UIFont(name: "System", size: 23)
            titleLable.backgroundColor = UIColor.whiteColor()
            titleLable.textColor = UIColor.darkGrayColor()
            self.addSubview(titleLable)
        }
        
        if linkImg == nil
        {
            linkImg = UIImageView(image: UIImage(named: "link"))
            linkImg.userInteractionEnabled = true
            self.addSubview(linkImg)
        }
    }
    
    func refresh()
    {
        initViews()
        bgImg.frame = self.bounds
        linkImg.frame = CGRectMake(0, 0, 48, 48)
        linkImg.center = self.center
        
        if String.isNullOrWhiteSpace(model.title)
        {
            titleLable.text = NSLocalizedString("EMPTY_TITLE", comment: "")
        }else
        {
            titleLable.text = "\(model.title)"
        }
        titleLable.sizeToFit()
        titleLable.frame = CGRectMake(0, 128, self.bounds.width, titleLable.frame.height)
    }
    
    func onTapTitleLable(ges:UITapGestureRecognizer)
    {
        SimpleBrowser.openUrl(MainViewTabBarController.currentNavicationController, url: model.url)
    }
}

class UrlContentModel: EVObject
{
    var title:String!
    var url:String!
}

class UrlContent:UIShareContentDelegate
{
    func refresh(sender: UIShareContent, share: ShareThing?) {
        if let contentView = sender.contentView as? UrlContentView
        {
            let model = UrlContentModel(json: share?.shareContent)
            contentView.model = model
            contentView.refresh()
        }
    }
    
    func getContentView(sender: UIShareContent, share: ShareThing?) -> UIView {
        let view = UrlContentView(frame: sender.bounds)
        return view
    }
}
