//
//  UIImagePlayerController.swift
//  Bahamut
//
//  Created by AlexChow on 15/9/6.
//  Copyright © 2015年 GStudio. All rights reserved.
//

import UIKit

class UIWebImageView: UIImageView
{
    var progress:KDCircularProgress!{
        didSet{
            progress.trackColor = UIColor.blackColor()
            progress.IBColor1 = UIColor.whiteColor()
            progress.IBColor2 = UIColor.whiteColor()
            progress.IBColor3 = UIColor.whiteColor()
            
        }
    }
    
    var url:String!{
        didSet{
            self.image = UIImage(named: url)
            
        }
    }
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        progress = KDCircularProgress()
        progress.startAngle = 100
        contentMode = .ScaleAspectFit
        bringSubviewToFront(progress)
        progress.frame = CGRectMake(self.bounds.width/2, self.bounds.height/2, 64, 64)
        self.addSubview(progress)
    }
    
    required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
    }
}

class UIImagePlayerController: UIViewController,UIScrollViewDelegate
{
    private var imageWidth:CGFloat{
        return scrollView.frame.width
    }
    private var imageHeight:CGFloat{
        return scrollView.frame.height
    }
    var imageUrls:[String]!{
        didSet{
            if pageControl != nil
            {
                pageControl.hidden = imageUrls.count <= 1
            }
        }
    }
    
    var images = [UIImageView]()
    @IBOutlet weak var scrollView: UIScrollView!{
        didSet{
            scrollView.backgroundColor = UIColor.blackColor()
            scrollView.showsHorizontalScrollIndicator = false
            scrollView.showsVerticalScrollIndicator = false
        }
    }
    
    var currentIndex:Int = 0{
        didSet{
            if imageUrls != nil && imageUrls.count > 0 && images.count > currentIndex
            {
                images[currentIndex].image = UIImage(named: imageUrls[currentIndex])
                let x:CGFloat = CGFloat(integerLiteral: currentIndex) * self.scrollView.frame.width;
                self.scrollView.contentOffset = CGPointMake(x, 0);
            }
        }
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
    }
    
    override func viewDidAppear(animated: Bool) {
        super.viewDidAppear(animated)
        initScrollView()
        initPageControl()
    }
    
    private func initPageControl()
    {
        self.pageControl.numberOfPages = imageUrls.count
    }

    @IBOutlet weak var pageControl: UIPageControl!{
        didSet{
            
        }
    }
    
    func initScrollView()
    {
        for var i:Int = 0; i < imageUrls.count;i++
        {
            let imageX = CGFloat(integerLiteral: i) * imageWidth
            let frame = CGRectMake( imageX , 0, imageWidth, imageHeight)
            let uiImageView = UIWebImageView(frame: frame)
            uiImageView.frame = frame
            scrollView.addSubview(uiImageView)
            uiImageView.url = imageUrls[i]
            images.append(uiImageView)
        }
        scrollView.contentSize = CGSizeMake(CGFloat(integerLiteral:imageUrls.count) * imageWidth, 0)
        scrollView.pagingEnabled = true
        scrollView.delegate = self
        scrollView.contentOffset = CGPointMake(0, 0)
        let tapScollView = UITapGestureRecognizer(target: self, action: "tapScollView:")
        scrollView.addGestureRecognizer(tapScollView)
    }
    
    func scrollViewDidScroll(scrollView: UIScrollView) {
        
        let scrollviewW:CGFloat =  scrollView.frame.width;
        let x = scrollView.contentOffset.x;
        let page:Int = Int((x + scrollviewW / 2) /  scrollviewW);
        if pageControl != nil
        {
            self.pageControl.currentPage = page
        }
        
    }
    
    func tapScollView(_:UIGestureRecognizer)
    {
        self.dismissViewControllerAnimated(true) { () -> Void in
        }
    }
    
    func scale(ges:UIPinchGestureRecognizer)
    {
        
    }

    static func showImagePlayer(currentNavigationController:UIViewController,imageUrls:[String],imageIndex:Int = 0)
    {
        let controller = instanceFromStoryBoard("Component", identifier: "imagePlayerController") as!UIImagePlayerController
        controller.imageUrls = imageUrls
        controller.currentIndex = imageIndex
        currentNavigationController.presentViewController(controller, animated: true) { () -> Void in
            
            
        }
    }
    
}
