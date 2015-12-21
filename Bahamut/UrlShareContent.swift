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
    
    private func initViews()
    {
        
        if titleLable == nil
        {
            self.backgroundColor = UIColor.headerColor
            self.addGestureRecognizer(UITapGestureRecognizer(target: self, action: "onTapTitleLable:"))
            titleLable = UILabel()
            titleLable.textAlignment = .Left
            titleLable.numberOfLines = 2
            titleLable.font = UIFont(name: "System", size: 13)
            titleLable.backgroundColor = UIColor.clearColor()
            titleLable.textColor = UIColor.lightGrayColor()
            self.addSubview(titleLable)
        }
        
        if linkImg == nil
        {
            linkImg = UIImageView(image: UIImage(named: "linkIcon"))
            linkImg.userInteractionEnabled = true
            self.addSubview(linkImg)
        }
    }
    
    func refresh()
    {
        initViews()
        linkImg.frame = CGRectMake(3, 3, 42, 42)
        
        if String.isNullOrWhiteSpace(model.title)
        {
            titleLable.text = NSLocalizedString("EMPTY_TITLE", comment: "")
        }else
        {
            titleLable.text = "\(model.title)"
        }
        titleLable.frame = CGRectMake(49, 0, self.bounds.width - 49, 48)
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
    
    func getContentFrame(sender: UIShareThing, share: ShareThing?) -> CGRect {
        return CGRectMake(0,0,sender.rootController.view.bounds.width - 23,49)
    }
    
    func getContentView(sender: UIShareContent, share: ShareThing?) -> UIView {
        let view = UrlContentView(frame: CGRectMake(0,0,sender.shareCell.rootController.view.bounds.width - 23,49))
        return view
    }
}
