//
//  SRCMenu.swift
//  Bahamut
//
//  Created by AlexChow on 16/1/20.
//  Copyright © 2016年 GStudio. All rights reserved.
//

import Foundation
import UIKit

protocol SRCMenuManagerDelegate
{
    func srcMenuDidShown()
    func srcMenuDidHidden()
    func srcMenuItemDidClick(itemView:SRCMenuItemView)
}

class SRCMenuItemView: UIView {
    var index:Int = 0
    var srcPlugin:SRCPlugin!
    var nameLabel:UILabel!
    var iconImageView:UIImageView!
}

class SRCMenuManager:NSObject,UIScrollViewDelegate
{
    private var menuTopInset:CGFloat = 0
    private var menuBottomInset:CGFloat = 0
    private var srcService:SRCService!
    private var rootView:UIView!
    private var srcMenu:UIView!
    private var srcItemContainer:UIScrollView!
    private var srcMenuPageControl:UIPageControl!
    private var srcItemViews = [SRCMenuItemView]()
    private var loadingSRCTipsLabel:UILabel!
    var menuBackgroundImage:UIImage!{
        didSet{
            if menuBackgroundImage == nil{
                if menuBackgroundImageView != nil{
                    menuBackgroundImageView.removeFromSuperview()
                }
            }else
            {
                if menuBackgroundImageView == nil{
                    menuBackgroundImageView = UIImageView()
                }
                menuBackgroundImageView.frame = srcMenu.bounds
                menuBackgroundImageView.image = menuBackgroundImage
                srcMenu.addSubview(menuBackgroundImageView)
                srcMenu.sendSubviewToBack(menuBackgroundImageView)
            }
        }
    }
    private var menuBackgroundImageView:UIImageView!
    var isMenuShown:Bool{
        return srcMenu.hidden == false
    }
    var delegate:SRCMenuManagerDelegate!
    
    func initManager(rootView:UIView,menuTopInset:CGFloat,menuBottomInset:CGFloat)
    {
        self.menuBottomInset = menuBottomInset
        self.menuTopInset = menuTopInset
        
        self.rootView = rootView
        self.srcService = ServiceContainer.getService(SRCService)
        self.srcService.addObserver(self, selector: "onLoadingPlugins:", name: SRCService.allSRCPluginsLoading, object: nil)
        self.srcService.addObserver(self, selector: "onPluginsLoaded:", name: SRCService.allSRCPluginsReloaded, object: nil)
        self.initSRCMenu()
        self.initItemLayoutAttributes()
        self.reloadSRCMenuItems()
    }
    
    //MARK: notification
    func onLoadingPlugins(_:NSNotification)
    {
        self.srcItemViews.forEach{$0.removeFromSuperview()}
        self.srcMenu.bringSubviewToFront(self.loadingSRCTipsLabel)
        self.loadingSRCTipsLabel.hidden = false
    }
    
    func onPluginsLoaded(_:NSNotification)
    {
        self.loadingSRCTipsLabel.hidden = true
        self.reloadSRCMenuItems()
    }
    
    //MARK: SRC
    
    private func initSRCMenu()
    {
        let srcMenuFrame = CGRectMake(0, 0, self.rootView.frame.width, self.rootView.frame.height - self.menuBottomInset)
        self.srcMenu = UIView(frame: srcMenuFrame)
        self.srcMenu.backgroundColor = UIColor.clearColor()
        let blurEffect = UIBlurEffect(style: .Light)
        let bcg = UIVisualEffectView(effect: blurEffect)
        bcg.frame = self.srcMenu.bounds
        self.srcMenu.addSubview(bcg)
        self.srcItemContainer = UIScrollView(frame: CGRectMake(0,0,srcMenuFrame.size.width,srcMenuFrame.size.height - 100))
        self.srcItemContainer.pagingEnabled = true
        self.srcItemContainer.showsHorizontalScrollIndicator = false
        self.srcItemContainer.delegate = self
        self.srcItemContainer.showsVerticalScrollIndicator = false
        self.srcItemContainer.backgroundColor = UIColor.clearColor()
        self.srcMenuPageControl = UIPageControl(frame:CGRectMake(0,srcMenuFrame.height - 98,srcMenuFrame.width,7))
        self.srcMenu.addSubview(self.srcItemContainer)
        self.srcMenu.addGestureRecognizer(UITapGestureRecognizer(target: self, action: "hideSRCMenu:"))
        self.srcItemContainer.addSubview(self.srcMenuPageControl)
        self.srcMenu.addSubview(self.srcMenuPageControl)
        self.srcMenu.hidden = true
        self.loadingSRCTipsLabel = UILabel()
        self.loadingSRCTipsLabel.font = self.loadingSRCTipsLabel.font.fontWithSize(23)
        self.loadingSRCTipsLabel.text = "LOADING_SRCPLUGINS".localizedString()
        self.loadingSRCTipsLabel.sizeToFit()
        self.loadingSRCTipsLabel.frame = CGRectMake(0,srcMenuFrame.size.height / 2 - 23 * 2,srcMenuFrame.size.width,self.loadingSRCTipsLabel.frame.height)
        self.loadingSRCTipsLabel.textAlignment = .Center
        self.loadingSRCTipsLabel.hidden = srcService.allSRCPlugins.count > 0
        self.srcMenu.addSubview(self.loadingSRCTipsLabel)
        self.rootView.addSubview(srcMenu)
    }

    
    func scrollViewDidEndDecelerating(scrollView: UIScrollView) {
        
        let page = Int(scrollView.contentOffset.x / scrollView.frame.width)
        self.srcMenuPageControl.currentPage = page
    }
    
    let itemTopEdge:CGFloat = 23
    let itemSpace:CGFloat = 7
    let rowSpace:CGFloat = 23
    let itemWidth:CGFloat = 84
    let nameFontSize:CGFloat = 13
    let iconWidthHeight:CGFloat = 67
    var iconEdge:CGFloat = 0
    var containerWidth:CGFloat = 0
    var containerHeight:CGFloat = 0
    var itemHeight:CGFloat = 0
    var rowItemCount = 0
    var rows = 0
    var edgeSpace:CGFloat = 0
    var onePageCount = 0
    
    private func initItemLayoutAttributes()
    {
        self.iconEdge = (itemWidth - iconWidthHeight) / 2
        self.containerWidth = self.srcItemContainer.frame.width
        self.containerHeight = self.srcItemContainer.frame.height - itemTopEdge
        self.itemHeight = itemWidth + nameFontSize
        self.rowItemCount = Int(containerWidth / (itemWidth + itemSpace))
        self.rows = Int(containerHeight / (itemHeight + rowSpace))
        self.edgeSpace = (containerWidth - CGFloat(rowItemCount) * (itemWidth + itemSpace) + itemSpace) / 2
        self.onePageCount = rows * rowItemCount
    }
    
    private func reloadSRCMenuItems()
    {
        if self.srcService.allSRCPlugins.count == 0
        {
            return
        }
        let allSRCPlugins = self.srcService.allSRCPlugins
        
        let totalPage = (allSRCPlugins.count + onePageCount - 1) / onePageCount
        self.srcMenuPageControl.numberOfPages = totalPage
        self.srcMenuPageControl.currentPage = 0
        self.srcMenuPageControl.hidden = totalPage <= 1
        self.srcItemContainer.contentSize = CGSizeMake(CGFloat(totalPage) * self.srcItemContainer.frame.width, self.srcItemContainer.frame.height)
        
        allSRCPlugins.forIndexEach { (i, p) -> Void in
            let page = i / self.onePageCount
            let indexOfPage = i % self.onePageCount
            let itemRow = indexOfPage / self.rowItemCount
            let itemColumn = indexOfPage % self.rowItemCount
            let x = CGFloat(page) * self.srcItemContainer.frame.width + self.edgeSpace + CGFloat(itemColumn) * (self.itemWidth + self.itemSpace)
            let y = self.menuTopInset + self.itemTopEdge + CGFloat(itemRow) * (self.itemHeight + self.rowSpace)
            let itemViewFrame = CGRectMake(x,y,self.itemWidth,self.itemHeight)
            let itemView = i < self.srcItemViews.count ? self.srcItemViews[i] : self.newItemView()
            itemView.index = i
            itemView.srcPlugin = p
            itemView.frame = itemViewFrame
            itemView.iconImageView.image = p.srcHeaderIcon
            itemView.nameLabel.text = p.srcName
            itemView.removeFromSuperview()
            self.srcItemContainer.addSubview(itemView)
        }
        self.srcItemContainer.backgroundColor = UIColor.clearColor()
    }
    
    private func newItemView()->SRCMenuItemView
    {
        let itemView = SRCMenuItemView()
        itemView.backgroundColor = UIColor.clearColor()
        let iconView = UIImageView()
        iconView.layer.cornerRadius = iconWidthHeight / 2
        iconView.frame = CGRectMake(iconEdge, 0, iconWidthHeight, iconWidthHeight)
        itemView.addSubview(iconView)
        itemView.iconImageView = iconView
        let nameLabel = UILabel(frame: CGRectMake(0,iconWidthHeight + 3,itemWidth,nameFontSize * 3 + 2))
        nameLabel.font = nameLabel.font.fontWithSize(nameFontSize)
        nameLabel.numberOfLines = 2
        nameLabel.textColor = UIColor.darkTextColor()
        nameLabel.textAlignment = .Center
        itemView.addSubview(nameLabel)
        itemView.nameLabel = nameLabel
        itemView.addGestureRecognizer(UITapGestureRecognizer(target: self, action: "srcItemClicked:"))
        itemView.userInteractionEnabled = true
        self.srcItemViews.append(itemView)
        return itemView
    }
    
    func srcItemClicked(a:UITapGestureRecognizer)
    {
        if let srcItemView = a.view as? SRCMenuItemView
        {
            srcItemView.animationMaxToMin()
            self.hideMenu()
            if let handler = self.delegate?.srcMenuItemDidClick
            {
                handler(srcItemView)
            }
        }
    }
    
    var isMenuHidden:Bool{
        return self.srcMenu.hidden
    }
    
    func hideSRCMenu(_:UITapGestureRecognizer)
    {
        hideMenu()
    }
    
    func showMenu()
    {
        if srcService.allSRCPlugins.count == 0
        {
            srcService.reloadSRC()
        }
        
        self.srcMenu.superview?.bringSubviewToFront(self.srcMenu)
        self.srcMenu.hidden = false
        self.srcMenu.alpha = 0
        UIView.animateWithDuration(0.3, animations: { () -> Void in
            self.srcMenu.alpha = 1
            }) { (flag) -> Void in
                if let handler = self.delegate?.srcMenuDidShown{
                    handler()
                }
        }
        
    }
    
    func hideMenu()
    {
        self.srcMenu.alpha = 1
        UIView.animateWithDuration(0.3, animations: { () -> Void in
            self.srcMenu.alpha = 0
            }) { (flag) -> Void in
                self.srcMenu.hidden = true
                if let handler = self.delegate?.srcMenuDidHidden{
                    handler()
                }
        }
    }
}