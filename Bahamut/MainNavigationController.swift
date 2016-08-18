//
//  MainNavigationController.swift
//  Bahamut
//
//  Created by AlexChow on 15/7/29.
//  Copyright (c) 2015年 GStudio. All rights reserved.
//

import UIKit

@objc
class MainNavigationController: UINavigationController,HandleBahamutCmdDelegate
{
    struct SegueIdentifier
    {
        static let ShowSignView = "Show Sign View"
        static let ShowMainView = "Show Main Navigation"
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        ServiceContainer.instance.initContainer("Sharelink", services: ServiceConfig.Services)
        setWaitingScreen()
        BahamutRFKit.sharedInstance.addObserver(self, selector: #selector(MainNavigationController.onAppTokenInvalid(_:)), name: BahamutRFKit.onTokenInvalidated, object: nil)
        ChicagoClient.sharedInstance.addObserver(self, selector: #selector(MainNavigationController.onAppTokenInvalid(_:)), name: AppTokenInvalided, object: nil)
        ChicagoClient.sharedInstance.addObserver(self, selector: #selector(MainNavigationController.onOtherDeviceLogin(_:)), name: OtherDeviceLoginChicagoServer, object: nil)
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
        ServiceContainer.instance.removeObserver(self)
        ChicagoClient.sharedInstance.removeObserver(self)
        BahamutRFKit.sharedInstance.removeObserver(self)
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
    
    func initServicesFailed(a:AnyObject)
    {
        ServiceContainer.instance.removeObserver(self)
        let reason = a.userInfo![InitServiceFailedReason] as! String
        let action = UIAlertAction(title: "OK".localizedString(), style: .Cancel) { (action) -> Void in
            MainNavigationController.start()
        }
        self.showAlert(nil, msg: reason, actions: [action])
    }
    
    func onOtherDeviceLogin(_:AnyObject)
    {
        let alert = UIAlertController(title: nil, message: "OTHER_DEVICE_HAD_LOGIN".localizedString() , preferredStyle: .Alert)
        alert.addAction(UIAlertAction(title: "I_SEE".localizedString(), style: .Default, handler: { (action) -> Void in
            ServiceContainer.instance.userLogout()
            MainNavigationController.start()
        }))
        self.showAlert(alert)
    }
    
    func onAppTokenInvalid(_:AnyObject)
    {
        let alert = UIAlertController(title: nil, message: "USER_APP_TOKEN_TIMEOUT".localizedString() , preferredStyle: .Alert)
        alert.addAction(UIAlertAction(title: "I_SEE".localizedString(), style: .Default, handler: { (action) -> Void in
            ServiceContainer.instance.userLogout()
            MainNavigationController.start()
        }))
        self.showAlert(alert)
    }
    
    private func go()
    {
        ServiceContainer.instance.addObserver(self, selector: #selector(MainNavigationController.allServicesReady(_:)), name: ServiceContainer.OnAllServicesReady, object: nil)
        ServiceContainer.instance.addObserver(self, selector: #selector(MainNavigationController.initServicesFailed(_:)), name: ServiceContainer.OnServiceInitFailed, object: nil)
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
    
    let screenWaitTimeInterval = 0.3
    private func showSignView()
    {
        NSTimer.scheduledTimerWithTimeInterval(screenWaitTimeInterval, target: self, selector: #selector(MainNavigationController.waitTimeShowSignView(_:)), userInfo: nil, repeats: false)
    }
    
    func waitTimeShowSignView(_:AnyObject?)
    {
        performSegueWithIdentifier(SegueIdentifier.ShowSignView, sender: self)
    }
    
    private func showMainView()
    {
        NSTimer.scheduledTimerWithTimeInterval(screenWaitTimeInterval, target: self, selector: #selector(MainNavigationController.waitTimeShowMainView(_:)), userInfo: nil, repeats: false)
    }
    
    func waitTimeShowMainView(_:AnyObject?)
    {
        BahamutCmdManager.sharedInstance.registHandler(self)
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
            if let navc = UIApplication.currentNavigationController
            {
                userService.showUserProfileViewController(navc, userId: sharelinkerId)
            }
        }else
        {
            let title = "SHARELINK".localizedString()
            let msg = String(format: "SEND_LINK_REQUEST_TO".localizedString(),sharelinkerNick)
            let alertController = UIAlertController(title: title, message: msg, preferredStyle: .Alert)
            alertController.addTextFieldWithConfigurationHandler({ (textfield) -> Void in
                textfield.placeholder = "YOUR_SHOW_NAME".localizedString()
                textfield.borderStyle = .None
                textfield.text = userService.myUserModel.nickName
            })
            
            let yes = UIAlertAction(title: "YES".localizedString() , style: .Default, handler: { (action) -> Void in
                var askNick = alertController.textFields?[0].text ?? ""
                if String.isNullOrEmpty(askNick)
                {
                    askNick = userService.myUserModel.nickName
                }
                userService.askSharelinkForLink(sharelinkerId, askNick:askNick, callback: { (isSuc) -> Void in
                    if isSuc
                    {
                        self.showAlert("Sharelink" ,msg:"LINK_REQUEST_SENDED".localizedString() )
                    }
                })
            })
            let no = UIAlertAction(title: "NO".localizedString(), style: .Cancel,handler:nil)
            alertController.addAction(no)
            alertController.addAction(yes)
            self.showAlert(alertController)
        }
    }
    
    func handleBahamutCmd(method: String, args: [String],object:AnyObject?) {
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
