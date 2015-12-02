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
    var titleLable:UITextView!
    var linkImg:UIImageView!
    func refresh()
    {
        if linkImg == nil
        {
            linkImg = UIImageView()
            linkImg.image = UIImage(named: "link")
            self.addSubview(linkImg)
        }
        if titleLable == nil
        {
            titleLable = UITextView()
            titleLable.editable = false
            titleLable.userInteractionEnabled = true
            self.addGestureRecognizer(UITapGestureRecognizer(target: self, action: "onTapTitleLable:"))
            self.addSubview(titleLable)
        }
        linkImg.frame = CGRectMake(0, 0, 128, 128)
        linkImg.center = self.center
        titleLable.text = "🔗\(model.title)"
        titleLable.sizeToFit()
        titleLable.frame = CGRectMake(0, 0, self.bounds.width, titleLable.frame.height)
        self.setNeedsLayout()
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
