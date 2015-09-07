//
//  UIImagePlayerController.swift
//  Bahamut
//
//  Created by AlexChow on 15/9/6.
//  Copyright © 2015年 GStudio. All rights reserved.
//

import UIKit
import Alamofire

protocol FileFetcher
{
    func startFetch(url:String,progress:(persent:Float)->Void,completed:(error:Bool,filePath:String!)->Void)
}

class UIFetchImageView: UIScrollView,UIScrollViewDelegate
{
    var progress:KDCircularProgress!{
        didSet{
            progress.trackColor = UIColor.blackColor()
            progress.IBColor1 = UIColor.whiteColor()
            progress.IBColor2 = UIColor.whiteColor()
            progress.IBColor3 = UIColor.whiteColor()
            
        }
    }
    var errorButton:UIButton!{
        didSet{
            errorButton.titleLabel?.text = "Load Image Error"
            errorButton.hidden = true
            errorButton.addTarget(self, action: "errorButtonClick:", forControlEvents: UIControlEvents.TouchUpInside)
            self.addSubview(errorButton)
        }
    }
    var fileFetcher:FileFetcher!
    var imageView:UIImageView!{
        didSet{
            
        }
    }
    
    var url:String!{
        didSet{
            startLoadImage()
        }
    }
    
    private func setProgressValue(value:Float)
    {
        progress.angle = Int(360 * value)
        if progress.angle > 0 && progress.angle <= 359
        {
            progress.hidden = false
        }else{
            progress.hidden = true
        }
    }
    
    func errorButtonClick(_:UIButton)
    {
        startLoadImage()
    }
    
    private func startLoadImage()
    {
        canScale = false
        errorButton.hidden = true
        setProgressValue(0)
        fileFetcher.startFetch(url, progress: { (persent) -> Void in
            self.setProgressValue(persent)
        }) { (error,image) -> Void in
            self.setProgressValue(0)
            if error
            {
                self.errorButton.hidden = false
            }else
            {
                self.imageView.image = UIImage(contentsOfFile: image)
                self.canScale = true
            }
        }
    }
    
    private func initImageView()
    {
        imageView = UIImageView()
        imageView.contentMode = .ScaleAspectFit
        self.addSubview(imageView)
    }
    
    private func initErrorButton()
    {
        self.errorButton = UIButton(type: UIButtonType.InfoDark)
    }
    
    private func initGesture()
    {
        self.minimumZoomScale = 1
        self.maximumZoomScale = 2
        self.userInteractionEnabled = true
        let doubleTapGesture = UITapGestureRecognizer(target: self, action: "doubleTap:")
        doubleTapGesture.numberOfTapsRequired = 2
        self.addGestureRecognizer(doubleTapGesture)
        
    }
    
    private func initProgress()
    {
        progress = KDCircularProgress(frame: CGRect(x: 0, y: 0, width: 32, height: 32))
        progress.startAngle = -90
        progress.progressThickness = 0.2
        progress.trackThickness = 0.6
        progress.clockwise = true
        progress.gradientRotateSpeed = 2
        progress.roundedCorners = false
        progress.glowMode = .Forward
        progress.glowAmount = 0.9
        progress.setColors(UIColor.cyanColor() ,UIColor.whiteColor(), UIColor.magentaColor(), UIColor.whiteColor(), UIColor.orangeColor())
        self.addSubview(progress)
        progress.hidden = true
    }
    
    override func layoutSubviews() {
        
        if !isScale && !isScrollling
        {
            progress.center = CGPoint(x: self.center.x, y: self.center.y)
            errorButton.center = CGPoint(x: self.center.x, y: self.center.y)
            imageView.frame = frame
        }
        super.layoutSubviews()
        
    }
    
    var isScale:Bool = false
    var isScrollling:Bool = false
    var canScale:Bool = false
    
    func doubleTap(ges:UITapGestureRecognizer)
    {
        if !canScale{return}
        let touchPoint = ges.locationInView(self)
        if (self.zoomScale != self.minimumZoomScale) {
            isScrollling = false
            self.setZoomScale(self.minimumZoomScale, animated: true)
        } else {
            let newZoomScale = CGFloat(2.0)
            let xsize = self.bounds.size.width / newZoomScale
            let ysize = self.bounds.size.height / newZoomScale
            self.zoomToRect(CGRectMake(touchPoint.x - xsize / 2, touchPoint.y - ysize / 2, xsize, ysize), animated: true)
        }
    }
    
    func viewForZoomingInScrollView(scrollView: UIScrollView) -> UIView? {
        return self.imageView
    }
    
    func scrollViewWillBeginDragging(scrollView: UIScrollView) {
        isScrollling = true
    }
    
    func scrollViewWillBeginZooming(scrollView: UIScrollView, withView view: UIView?) {
        isScale = true
        self.scrollEnabled = true
    }
    
    func scrollViewDidEndZooming(scrollView: UIScrollView, withView view: UIView?, atScale scale: CGFloat) {
        isScale = false
    }
    
    func scrollViewDidZoom(scrollView: UIScrollView) {
        self.setNeedsLayout()
        self.setNeedsDisplay()
    }
    
    convenience init()
    {
        self.init(frame:CGRectMake(0, 0, 0, 0))
    }
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        self.delegate = self
        self.showsHorizontalScrollIndicator = false
        self.showsVerticalScrollIndicator = false
        self.decelerationRate = UIScrollViewDecelerationRateFast
        self.autoresizingMask = [UIViewAutoresizing.FlexibleWidth, UIViewAutoresizing.FlexibleHeight]
        initImageView()
        initProgress()
        initErrorButton()
        initGesture()
    }
    
    required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
    }
}

class UIImagePlayerController: UIViewController,UIScrollViewDelegate
{
    private var imageWidth:CGFloat{
        return scrollView.bounds.width
    }
    private var imageHeight:CGFloat{
        return scrollView.bounds.height
    }
    var imageUrls:[String]!{
        didSet{
            if pageControl != nil
            {
                pageControl.hidden = imageUrls.count <= 1
            }
        }
    }
    
    var images = [UIFetchImageView]()
    var imageFileFetcher:FileFetcher!
    
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
                images[currentIndex].url = imageUrls[currentIndex]
                let x:CGFloat = CGFloat(integerLiteral: currentIndex) * self.scrollView.frame.width;
                self.scrollView.contentOffset = CGPointMake(x, 0);
            }
        }
    }
    
    override func shouldAutorotate() -> Bool {
        return true
    }
    
    override func supportedInterfaceOrientations() -> UIInterfaceOrientationMask {
        return [UIInterfaceOrientationMask.Portrait,UIInterfaceOrientationMask.Landscape]
    }
    
    override func viewDidAppear(animated: Bool) {
        super.viewDidAppear(animated)
        initScrollView()
        initPageControl()
    }
    
    override func viewWillLayoutSubviews() {
        super.viewWillLayoutSubviews()
        resizeScrollView()
    }
    
    private func initPageControl()
    {
        self.pageControl.numberOfPages = imageUrls.count
    }

    @IBOutlet weak var pageControl: UIPageControl!{
        didSet{
            if pageControl != nil
            {
                pageControl.hidden = imageUrls.count <= 1
            }
        }
    }
    
    func initScrollView()
    {
        for var i:Int = 0; i < imageUrls.count;i++
        {
            let uiImageView = UIFetchImageView()
            uiImageView.fileFetcher = imageFileFetcher
            scrollView.addSubview(uiImageView)
            uiImageView.url = imageUrls[i]
            images.append(uiImageView)
        }
        
        scrollView.pagingEnabled = true
        scrollView.delegate = self
        let tapGesture = UITapGestureRecognizer(target: self, action: "tapScollView:")
        let doubleTapGesture = UITapGestureRecognizer(target: self, action: "doubleTapScollView:")
        doubleTapGesture.numberOfTapsRequired = 2
        tapGesture.requireGestureRecognizerToFail(doubleTapGesture)
        tapGesture.delaysTouchesBegan = true
        self.view.addGestureRecognizer(tapGesture)
        self.view.addGestureRecognizer(doubleTapGesture)
    }
    
    func resizeScrollView()
    {
        for var i:Int = 0; i < images.count;i++
        {
            let imageX = CGFloat(integerLiteral: i) * imageWidth
            let frame = CGRectMake( imageX , 0, imageWidth, imageHeight)
            images[i].frame = frame
            images[i].contentMode = .ScaleAspectFit
        }
        scrollView.contentSize = CGSizeMake(CGFloat(integerLiteral:imageUrls.count) * imageWidth, 0)
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
    
    func doubleTapScollView(_:UIGestureRecognizer)
    {
    }
    
    func tapScollView(_:UIGestureRecognizer)
    {
        self.dismissViewControllerAnimated(true) { () -> Void in
        }
    }

    static func showImagePlayer(currentNavigationController:UIViewController,imageUrls:[String],imageFileFetcher:FileFetcher,imageIndex:Int = 0)
    {
        let controller = instanceFromStoryBoard("Component", identifier: "imagePlayerController") as!UIImagePlayerController
        controller.imageUrls = imageUrls
        controller.currentIndex = imageIndex
        controller.imageFileFetcher = imageFileFetcher
        currentNavigationController.presentViewController(controller, animated: true) { () -> Void in
        }
    }
    
}
