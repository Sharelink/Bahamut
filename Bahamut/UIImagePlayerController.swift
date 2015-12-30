//
//  UIImagePlayerController.swift
//  Bahamut
//
//  Created by AlexChow on 15/9/6.
//  Copyright © 2015年 GStudio. All rights reserved.
//

import UIKit

protocol ImageProvider
{
    func getImageCount() -> Int
    func startLoad(index:Int)
    func getThumbnail(index:Int) -> UIImage?
    func registImagePlayerObserver(observer:LoadImageObserver)
}

class UIFetchImageView: UIScrollView,UIScrollViewDelegate
{
    private var progress:KDCircularProgress!{
        didSet{
            progress.trackColor = UIColor.blackColor()
            progress.IBColor1 = UIColor.whiteColor()
            progress.IBColor2 = UIColor.whiteColor()
            progress.IBColor3 = UIColor.whiteColor()
        }
    }
    private var refreshButton:UIButton!{
        didSet{
            refreshButton.titleLabel?.text = NSLocalizedString("LOAD_IMG_ERROR", comment: "Load Image Error")
            refreshButton.hidden = true
            refreshButton.addTarget(self, action: "refreshButtonClick:", forControlEvents: UIControlEvents.TouchUpInside)
            self.addSubview(refreshButton)
        }
    }
    private var imageView:UIImageView!
    
    func refreshButtonClick(_:UIButton)
    {
        startLoadImage()
    }
    
    func startLoadImage()
    {
        canScale = false
        refreshButton.hidden = true
        self.progress.setProgressValue(0)
    }
    
    func imageLoaded(image:UIImage)
    {
        self.progress.setProgressValue(0)
        dispatch_async(dispatch_get_main_queue()){
            self.imageView.image = image
            self.canScale = true
            self.refreshUI()
        }
    }
    
    func imageLoadError()
    {
        self.progress.setProgressValue(0)
        dispatch_async(dispatch_get_main_queue()){
            self.refreshButton.hidden = false
            self.canScale = false
            self.refreshUI()
        }
    }
    
    func loadImageProgress(progress:Float)
    {
        self.progress.setProgressValue(0)
    }
    
    func setThumbnail(thumbnail:UIImage)
    {
        self.canScale = false
        self.imageView.image = thumbnail
    }
    
    private func initImageView()
    {
        imageView = UIImageView()
        imageView.contentMode = .ScaleAspectFit
        self.addSubview(imageView)
    }
    
    private func initErrorButton()
    {
        self.refreshButton = UIButton(type: UIButtonType.InfoDark)
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
    
    private func refreshUI()
    {
        self.setZoomScale(self.minimumZoomScale, animated: true)
        progress.center = CGPoint(x: self.center.x, y: self.center.y)
        refreshButton.center = CGPoint(x: self.center.x, y: self.center.y)
        imageView.frame = UIApplication.sharedApplication().keyWindow!.bounds
        imageView.layoutIfNeeded()
    }
    
    private var isScale:Bool = false
    private var isScrollling:Bool = false
    private var canScale:Bool = false
    
    func doubleTap(ges:UITapGestureRecognizer)
    {
        if !canScale{return}
        let touchPoint = ges.locationInView(self)
        if (self.zoomScale != self.minimumZoomScale) {
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
    
    func scrollViewWillBeginZooming(scrollView: UIScrollView, withView view: UIView?) {
        self.scrollEnabled = true
    }
    
    func scrollViewDidZoom(scrollView: UIScrollView) {
        self.setNeedsLayout()
        self.setNeedsDisplay()
    }
    
    convenience init()
    {
        self.init(frame: CGRectZero)
    }
    
    override init(frame: CGRect)
    {
        super.init(frame: frame)
        initScrollView()
        initImageView()
        initProgress()
        initErrorButton()
        initGesture()
    }
    
    private func initScrollView()
    {
        self.delegate = self
        self.showsHorizontalScrollIndicator = false
        self.showsVerticalScrollIndicator = false
        self.decelerationRate = UIScrollViewDecelerationRateFast
        self.autoresizingMask = [UIViewAutoresizing.FlexibleWidth, UIViewAutoresizing.FlexibleHeight]
    }
    
    required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
    }
}

protocol LoadImageObserver
{
    func imageLoaded(index:Int,image:UIImage)
    func imageLoadError(index:Int)
    func imageLoadingProgress(index:Int,progress:Float)
}

class UIImagePlayerController: UIViewController,UIScrollViewDelegate,LoadImageObserver
{
    private var imageCount:Int = 0
    private let spaceOfItem:CGFloat = 23
    var imageProvider:ImageProvider!{
        didSet{
            imageProvider.registImagePlayerObserver(self)
            imageCount = imageProvider.getImageCount()
        }
    }
    
    var images = [UIFetchImageView]()
    
    func supportedViewOrientations() -> UIInterfaceOrientationMask
    {
        return UIInterfaceOrientationMask.All
    }
    
    @IBOutlet weak var scrollView: UIScrollView!{
        didSet{
            scrollView.backgroundColor = UIColor.blackColor()
            scrollView.showsHorizontalScrollIndicator = false
            scrollView.showsVerticalScrollIndicator = false
            scrollView.pagingEnabled = false
            scrollView.delegate = self
        }
    }
    
    var currentIndex:Int = -1{
        didSet{
            if currentIndex >= 0 && currentIndex != oldValue && currentIndex < imageCount
            {
                images[currentIndex].startLoadImage()
                if let thumb = imageProvider.getThumbnail(currentIndex)
                {
                    images[currentIndex].setThumbnail(thumb)
                }
                self.imageProvider.startLoad(currentIndex)
            }
        }
    }
    
    private func scrollToCurrentIndex()
    {
        let x:CGFloat = CGFloat(integerLiteral: currentIndex) * (self.scrollView.frame.width  + spaceOfItem);
        self.scrollView.contentOffset = CGPointMake(x, 0);
    }
    
    private func getNearestTargetPoint(offset:CGPoint) -> CGPoint{
        let pageSize = self.scrollView.frame.width + spaceOfItem
        let targetIndex = Int(roundf(Float(offset.x / pageSize)))
        currentIndex += targetIndex == currentIndex ? 0 : targetIndex > currentIndex ? 1 : -1
        let targetX = pageSize * CGFloat(currentIndex);
        return CGPointMake(targetX, offset.y);
    }
    
    func scrollViewWillEndDragging(scrollView: UIScrollView, withVelocity velocity: CGPoint, targetContentOffset: UnsafeMutablePointer<CGPoint>) {
        let offset = getNearestTargetPoint(targetContentOffset.memory)
        targetContentOffset.memory.x = offset.x
    }
    
    func imageLoaded(index: Int, image: UIImage) {
        if images.count > index{
            images[index].imageLoaded(image)
        }
    }
    
    func imageLoadError(index: Int) {
        if images.count > index{
            images[index].imageLoadError()
        }
    }
    
    func imageLoadingProgress(index: Int, progress: Float) {
        if images.count > index{
            images[index].loadImageProgress(progress)
        }
    }
    
    override func shouldAutorotate() -> Bool {
        return true
    }
    
    override func supportedInterfaceOrientations() -> UIInterfaceOrientationMask {
        return [UIInterfaceOrientationMask.Portrait,UIInterfaceOrientationMask.Landscape]
    }
    
    override func viewWillAppear(animated: Bool) {
        super.viewWillAppear(animated)
        initImageViews()
        initPageControl()
        initObserver()
    }
    
    override func viewWillDisappear(animated: Bool) {
        super.viewWillDisappear(animated)
        deinitObserver()
    }
    
    override func viewWillLayoutSubviews() {
        super.viewWillLayoutSubviews()
        resizeScrollView()
    }
    
    private func initPageControl()
    {
        self.pageControl.numberOfPages = imageCount
    }

    @IBOutlet weak var pageControl: UIPageControl!{
        didSet{
            if pageControl != nil
            {
                pageControl.hidden = imageCount <= 1
            }
        }
    }
    
    func initImageViews()
    {
        for _ in 0..<imageCount
        {
            let uiImageView = UIFetchImageView()
            scrollView.addSubview(uiImageView)
            images.append(uiImageView)
        }
        let tapGesture = UITapGestureRecognizer(target: self, action: "tapScollView:")
        let doubleTapGesture = UITapGestureRecognizer(target: self, action: "doubleTapScollView:")
        doubleTapGesture.numberOfTapsRequired = 2
        tapGesture.requireGestureRecognizerToFail(doubleTapGesture)
        tapGesture.delaysTouchesBegan = true
        self.view.addGestureRecognizer(tapGesture)
        self.view.addGestureRecognizer(doubleTapGesture)
    }
    
    private func initObserver()
    {
        NSNotificationCenter.defaultCenter().addObserver(self, selector: "didChangeStatusBarOrientation:", name: UIApplicationDidChangeStatusBarOrientationNotification, object: UIApplication.sharedApplication())
    }
    
    private func deinitObserver()
    {
        NSNotificationCenter.defaultCenter().removeObserver(self)
    }
    
    func didChangeStatusBarOrientation(_: NSNotification)
    {
        resizeScrollView()
    }
    
    func resizeScrollView()
    {
        let svFrame = UIApplication.sharedApplication().keyWindow!.bounds
        let imageWidth = svFrame.width
        let imageHeight = svFrame.height
        let pageSize = imageWidth + spaceOfItem
        for var i:Int = 0; i < images.count;i++
        {
            let imageX = CGFloat(integerLiteral: i) * pageSize
            let frame = CGRectMake( imageX , 0, imageWidth, imageHeight)
            images[i].frame = frame
            images[i].refreshUI()
        }
        scrollView.frame = svFrame
        scrollView.contentSize = CGSizeMake(CGFloat(integerLiteral:imageCount) * pageSize, imageHeight)
    }
    
    enum OrientationAngle:CGFloat
    {
        case Portrait = 0.0
        case LandscapeLeft = 270.0
        case LandscapeRight = 90.0
        case PortraitUpsideDown = 180.0
    }
    
    func getRotationAngle() -> OrientationAngle
    {
        switch UIApplication.sharedApplication().statusBarOrientation
        {
            case .Portrait: return OrientationAngle.Portrait
            case .LandscapeLeft: return OrientationAngle.LandscapeLeft
            case .LandscapeRight: return OrientationAngle.LandscapeRight
            case .PortraitUpsideDown: return OrientationAngle.PortraitUpsideDown
            case .Unknown: return OrientationAngle.Portrait
        }
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
        self.dismissViewControllerAnimated(false) { () -> Void in
        }
    }
    
    deinit
    {
        NSNotificationCenter.defaultCenter().removeObserver(self)
    }
    
    static func showImagePlayer(currentController:UIViewController,imageProvider:ImageProvider,imageIndex:Int = 0)
    {
        let controller = instanceFromStoryBoard("Component", identifier: "imagePlayerController") as!UIImagePlayerController
        controller.imageProvider = imageProvider
        currentController.presentViewController(controller, animated: true, completion: { () -> Void in
            controller.currentIndex = imageIndex
            controller.scrollToCurrentIndex()
        })
        
    }
    
}
