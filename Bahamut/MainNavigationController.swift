//
//  MainNavigationController.swift
//  Bahamut
//
//  Created by AlexChow on 15/7/29.
//  Copyright (c) 2015年 GStudio. All rights reserved.
//

import UIKit

@objc
class MainNavigationController: UINavigationController,HandleSharelinkCmdDelegate
{
    struct SegueIdentifier
    {
        static let ShowSignView = "Show Sign View"
        static let ShowMainView = "Show Main Navigation"
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        setWaitingScreen()
        ChicagoClient.sharedInstance.addObserver(self, selector: "onAppTokenInvalid:", name: AppTokenInvalided, object: nil)
    }
    
    private var launchScr:UIView!
    private func setWaitingScreen()
    {
        self.view.backgroundColor = UIColor.whiteColor()
        launchScr = MainNavigationController.getLaunchScreen(self.view.bounds)
        self.view.addSubview(launchScr)
        
    }
    
    static func getLaunchScreen(frame:CGRect) -> UIView
    {
        let launchScr = Sharelink.mainBundle().loadNibNamed("LaunchScreen", owner: nil, options: nil).filter{$0 is UIView}.first as! UIView
        launchScr.frame = frame
        if let indicator = launchScr.viewWithTag(1) as? UIActivityIndicatorView
        {
            indicator.hidden = false
        }
        if let mottoLabel = launchScr.viewWithTag(2) as? UILabel
        {
            mottoLabel.text = SharelinkConfig.SharelinkMotto
            mottoLabel.hidden = false
        }
        return launchScr
    }
    
    func deInitController(){
        ChicagoClient.sharedInstance.removeObserver(self)
    }
    
    override func viewDidAppear(animated: Bool) {
        super.viewDidAppear(animated)
        go()
    }
    
    func allServicesReady(_:AnyObject)
    {
        ServiceContainer.instance.removeObserver(self)
        if let _ = self.presentedViewController
        {
            let notiService = ServiceContainer.getService(NotificationService)
            notiService.setMute(false)
            notiService.setVibration(true)
            MainNavigationController.start()
        }else
        {
            showMainView()
        }
    }
    
    func onAppTokenInvalid(_:AnyObject)
    {
        let alert = UIAlertController(title: nil, message: "USER_APP_TOKEN_TIMEOUT".localizedString() , preferredStyle: .Alert)
        alert.addAction(UIAlertAction(title: "I_SEE".localizedString(), style: .Default, handler: { (action) -> Void in
            ServiceContainer.instance.userLogout()
            MainNavigationController.start()
        }))
        showAlert(self,alertController: alert)
    }
    
    private func go()
    {
        ServiceContainer.instance.addObserver(self, selector: "allServicesReady:", name: ServiceContainer.AllServicesReady, object: nil)
        if UserSetting.isUserLogined
        {
            if ServiceContainer.isAllServiceReady
            {
                ServiceContainer.instance.removeObserver(self)
                showMainView()
            }else
            {
                ServiceContainer.instance.userLogin(UserSetting.userId)
            }
        }else
        {
            showSignView()
        }
    }
    
    let screenWaitTimeInterval = 0.7
    private func showSignView()
    {
        NSTimer.scheduledTimerWithTimeInterval(screenWaitTimeInterval, target: self, selector: "waitTimeShowSignView:", userInfo: nil, repeats: false)
    }
    
    func waitTimeShowSignView(_:AnyObject?)
    {
        performSegueWithIdentifier(SegueIdentifier.ShowSignView, sender: self)
    }
    
    private func showMainView()
    {
        NSTimer.scheduledTimerWithTimeInterval(screenWaitTimeInterval, target: self, selector: "waitTimeShowMainView:", userInfo: nil, repeats: false)
    }
    
    func waitTimeShowMainView(_:AnyObject?)
    {
        SharelinkCmdManager.sharedInstance.registHandler(self)
        self.performSegueWithIdentifier(SegueIdentifier.ShowMainView, sender: self)
        if self.launchScr != nil
        {
            self.launchScr.removeFromSuperview()
        }
    }
    
    //MARK: handle sharelinkMessage
    let linkMeParameterCount = 3
    func linkMe(method: String, args: [String],object:AnyObject?)
    {
        if args.count < linkMeParameterCount
        {
            self.showAlert("Sharelink", msg: "UNKNOW_SHARELINK_CMD".localizedString() )
            return
        }
        let sharelinkerId = args[0]
        let sharelinkerNick = args[1]
        let expriedAt = args[2].dateTimeOfString
        if expriedAt.timeIntervalSince1970 < NSDate().timeIntervalSince1970
        {
            self.showAlert("Sharelink", msg: "SHARELINK_CMD_TIMEOUT".localizedString())
            return
        }
        let userService = ServiceContainer.getService(UserService)
        if userService.isSharelinkerLinked(sharelinkerId)
        {
            if let navc = MainViewTabBarController.currentNavicationController
            {
                userService.showUserProfileViewController(navc, userId: sharelinkerId)
            }
        }else
        {
            let yes = UIAlertAction(title: "YES".localizedString() , style: .Default, handler: { (action) -> Void in
                userService.askSharelinkForLink(sharelinkerId, callback: { (isSuc) -> Void in
                    if isSuc
                    {
                        self.showAlert("Sharelink" ,msg:"LINK_REQUEST_SENDED".localizedString() )
                    }
                })
            })
            let no = UIAlertAction(title: "NO".localizedString(), style: .Cancel,handler:nil)
            let title = "SHARELINK".localizedString()
            let msg = String(format: "SEND_LINK_REQUEST_TO".localizedString(),sharelinkerNick)
            self.showAlert(title, msg:msg, actions: [yes,no])
        }
    }
    
    func handleSharelinkCmd(method: String, args: [String],object:AnyObject?) {
        switch method
        {
        case "linkMe":linkMe(method, args: args, object: object)
        default:break
        }
    }
    
    private static func instanceFromStoryBoard() -> MainNavigationController
    {
        return instanceFromStoryBoard("SharelinkMain", identifier: "mainNavigationController",bundle: Sharelink.mainBundle()) as! MainNavigationController
    }
    
    static func start()
    {
        dispatch_async(dispatch_get_main_queue(), { () -> Void in
            if let mnc = UIApplication.sharedApplication().delegate?.window!?.rootViewController as? MainNavigationController{
                mnc.deInitController()
            }
            UIApplication.sharedApplication().delegate?.window!?.rootViewController = instanceFromStoryBoard()
        })
    }
}
