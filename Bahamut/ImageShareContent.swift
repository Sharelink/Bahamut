//
//  ImageShareContent.swift
//  Bahamut
//
//  Created by AlexChow on 15/12/26.
//  Copyright © 2015年 GStudio. All rights reserved.
//

import Foundation

class ImageContent:NSObject,UIShareContentDelegate
{
    private var rows:Int = 0
    private var itemsPerRow:Int = 3
    private var imageSize = CGSizeMake(98, 98)
    private let imageSpace = CGFloat(7)
    private var images:[UIImage]! = [UIImage(named: "defaultView")!,UIImage(named: "defaultView")!,UIImage(named: "defaultView")!,UIImage(named: "defaultView")!,UIImage(named: "defaultView")!,UIImage(named: "defaultView")!,UIImage(named: "defaultView")!]
    private var shareCell:UIShareThing!
    private var view = UIView(){
        didSet{
            view.backgroundColor = UIColor.whiteColor()
            view.userInteractionEnabled = true
        }
    }
    private var imageViews = [UIImageView]()
    private var pWidth:CGFloat{
        return imageSize.width + imageSpace
    }
    
    private var pHeight:CGFloat{
        return imageSize.height + imageSpace
    }
    
    private func calRows(width:CGFloat,imageCount:Int)
    {
        let perRow = CGFloat(itemsPerRow)
        let hw = (width - (perRow + 1) * imageSpace) / perRow
        imageSize = CGSizeMake(hw, hw)
        rows = Int((imageCount + itemsPerRow - 1) / itemsPerRow)
    }
    
    func onTapImageView(a:UITapGestureRecognizer)
    {
        print("tap view")
        if let imgView = a.view as? UIImageView
        {
            print("tap view:\(imgView.tag)")
        }
    }
    
    func initContent(shareCell: UIShareThing, share: ShareThing) {
        self.shareCell = shareCell
        let width = shareCell.rootController.view.bounds.width - 23
        calRows(width, imageCount: images.count)
    }
    
    func getContentFrame(sender: UIShareThing, share: ShareThing?) -> CGRect {
        let width = sender.rootController.view.bounds.width - 23
        let height = pHeight * CGFloat(rows)
        self.view.frame = CGRectMake(0,0,width,height)
        return view.frame
    }
    
    func getContentView(sender: UIShareContent, share: ShareThing?) -> UIView {
        for i in 0..<rows
        {
            for j in 0..<itemsPerRow
            {
                let index = i * itemsPerRow + j
                if imageViews.count == index
                {
                    let img = UIImageView()
                    img.userInteractionEnabled = true
                    let tapGes = UITapGestureRecognizer(target: self, action: "onTapImageView:")
                    img.addGestureRecognizer(tapGes)
                    imageViews.append(img)
                    
                }
                let imgView = imageViews[index]
                imgView.frame = CGRectMake( CGFloat(j) * pWidth, CGFloat(i) * pHeight, imageSize.width, imageSize.height)
                view.addSubview(imgView)
            }
            
        }
        return view
    }
    
    func refresh(sender: UIShareContent, share: ShareThing?){
        for i in 0..<images.count{
            let img = imageViews[i]
            img.tag = i
            img.image = images[i]
        }
    }
    
}