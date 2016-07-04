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
            self.addGestureRecognizer(UITapGestureRecognizer(target: self, action: #selector(UrlContentView.onTapTitleLable(_:))))
            titleLable = UILabel()
            titleLable.textAlignment = .Left
            titleLable.numberOfLines = 2
            titleLable.font = UIFont(name: "System", size: 13)
            titleLable.backgroundColor = UIColor.clearColor()
            titleLable.textColor = UIColor.lightGrayColor()
            self.layer.cornerRadius = 7
            self.addSubview(titleLable)
        }
        
        if linkImg == nil
        {
            linkImg = UIImageView(image: UIImage.namedImageInSharelink( "linkIcon"))
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
            titleLable.text = "EMPTY_TITLE".localizedString()
        }else
        {
            titleLable.text = "\(model.title)"
        }
        titleLable.frame = CGRectMake(49, 0, self.bounds.width - 49, 48)
    }
    
    func onTapTitleLable(ges:UITapGestureRecognizer)
    {
        if let a = ges.view
        {
            a.animationMaxToMin(0.1, maxScale: 1.1, completion: { () -> Void in
                if let navc = UIApplication.currentNavigationController
                {
                    SimpleBrowser.openUrlWithShare(navc, url: self.model.url)
                }
            })
        }
    }
}

extension SimpleBrowser
{
    static func openUrlWithShare(currentViewController: UINavigationController,url:String)
    {
        let broswer = self.openUrl(currentViewController, url: url)
        let btn = UIBarButtonItem(image: UIImage.namedImageInSharelink("share_icon"), style: .Plain, target: broswer, action: #selector(SimpleBrowser.shareUrl(_:)))
        broswer.navigationItem.rightBarButtonItem = btn
    }
    
    func shareUrl(sender:AnyObject?)
    {
        let share = ShareThing()
        share.shareType = ShareThingType.shareUrl.rawValue
        let urlModel = UrlContentModel()
        urlModel.url = self.url
        share.shareContent = urlModel.toJsonString()
        ServiceContainer.getService(ShareService).showNewShareController(self.navigationController!, shareModel: share, isReshare: false)
    }
}

class UrlContentModel: EVObject
{
    var title:String!
    var url:String!
}

class UrlContent:UIShareContentDelegate
{
    func initContent(shareCell: UIShareThing, share: ShareThing) {
        
    }
    
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
