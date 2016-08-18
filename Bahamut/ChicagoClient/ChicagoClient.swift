//
//  ChatClient.swift
//  Bahamut
//
//  Created by AlexChow on 15/10/12.
//  Copyright © 2015年 GStudio. All rights reserved.
//

import Foundation
import EVReflection
import CocoaAsyncSocket

let AppTokenInvalided = "AppTokenInvalided"
let OtherDeviceLoginChicagoServer = "OtherDeviceLoginChicagoServer"

//MARK: ChicagoClient Common Route
class ChicagoClientCommonRoute
{
    
    static let validationRoute:ChicagoRoute = {
        let route = ChicagoRoute()
        route.ExtName = "BahamutUserValidation"
        route.CmdName = "Login"
        return route
    }()
    
    static let otherDeviceLoginRoute:ChicagoRoute = {
        let route = ChicagoRoute()
        route.ExtName = "BahamutUserValidation"
        route.CmdName = "OtherDeviceLogin"
        return route
    }()
    
    private static let logoutRoute:ChicagoRoute = {
        let route = ChicagoRoute()
        route.ExtName = "BahamutUserValidation"
        route.CmdName = "Logout"
        return route
    }()
    
    private static let registDeviceTokenRoute:ChicagoRoute = {
        let route = ChicagoRoute()
        route.ExtName = "NotificationCenter"
        route.CmdName = "RegistDeviceToken"
        return route
    }()
    
    private static let bahamutAppNotificationRoute:ChicagoRoute = {
        let route = ChicagoRoute()
        route.ExtName = "NotificationCenter"
        route.CmdName = "BahamutNotify"
        return route
    }()
    
    private static let heartBeatRoute:ChicagoRoute = {
        let route = ChicagoRoute()
        route.ExtName = "HeartBeat"
        route.CmdName = "Beat"
        return route
    }()
}


//MARK: Bahamut App Notification Model
let BahamutAppNotificationValue = "BahamutAppNotificationValue"
class BahamutAppNotification:EVObject
{
    var NotificationType:String!
    var Info:String!
}

//MARK: Chicago Client
class ChicagoClient :NSNotificationCenter,GCDAsyncSocketDelegate
{
    private static let heartBeatJson = "{}"
    private static var heartBeatTimer:NSTimer!
    private static var lastHeartBeatTime:NSDate!
    private static var heartBeatInterval:NSTimeInterval = 42
    
    class ValidationInfo: EVObject
    {
        var UserId:String!
        var AppToken:String!
        var Appkey:String!
    }
    private var socket:GCDAsyncSocket!
    
    private(set) var validationInfo:ValidationInfo!
    private(set) var appToken:String!
    private(set) var userId:String!
    
    private var deviceTokenSended:Bool = false
    private var deviceToken:String!
    private var sendDeviceTokenLock = NSRecursiveLock()
    
    private(set) var host:String!
    private(set) var port:UInt16 = 0
    private(set) var reConnectFailedTimes:Int = 0
    private(set) var clientState:ChicagoClientState = .Closed{
        didSet{
            if oldValue != clientState
            {
                NSLog("Chicago State:\(clientState)")
                var userInfo = [NSObject:AnyObject]()
                userInfo.updateValue(oldValue.rawValue, forKey: ChicagoClientBeforeChangedState)
                userInfo.updateValue(clientState.rawValue, forKey: ChicagoClientCurrentState)
                dispatch_async(dispatch_get_main_queue(), { () -> Void in
                    self.postNotificationName(ChicagoClientStateChanged, object: self,userInfo: userInfo)
                })
            }
        }
    }
    static let readHeadTag = 1
    static let readDataTag = 2
    private var tag:Int = 7
    static let sharedInstance:ChicagoClient = {
        return ChicagoClient()
    }()
    
    override init() {
        super.init()
        
        socket = GCDAsyncSocket()
        socket.setDelegate(self,delegateQueue: dispatch_get_main_queue())
        self.addChicagoObserver(ChicagoClientCommonRoute.validationRoute, observer: self, selector: #selector(ChicagoClient.onValidationReturn(_:)))
        self.addChicagoObserver(ChicagoClientCommonRoute.logoutRoute, observer: self, selector: #selector(ChicagoClient.onLogoutReturn(_:)))
        self.addChicagoObserver(ChicagoClientCommonRoute.heartBeatRoute, observer: self, selector: #selector(ChicagoClient.onHeartBeatReturn(_:)))
        self.addChicagoObserver(ChicagoClientCommonRoute.otherDeviceLoginRoute, observer: self, selector: #selector(ChicagoClient.onOtherDeviceLogin(_:)))
        self.addChicagoObserver(ChicagoClientCommonRoute.bahamutAppNotificationRoute, observer: self, selector: #selector(ChicagoClient.onBahamutAppNotification(_:)))
    }
    
    func startHeartBeat()
    {
        ChicagoClient.heartBeatTimer = NSTimer.scheduledTimerWithTimeInterval(ChicagoClient.heartBeatInterval, target: self, selector: #selector(ChicagoClient.heartBeat(_:)), userInfo: nil, repeats: true)
    }
    
    private func incTag() -> Int
    {
        let t = tag
        tag += 1
        return t
    }
    
    private func sendMessage(data:NSData) -> Int
    {
        if self.clientState != .Connected && self.clientState != .Validated && self.clientState != .UserLogout
        {
            return -1
        }
        var dataLength = Int32(data.length)
        let packageLengthData = NSData(bytes: &dataLength, length: 4)
        let package = NSMutableData()
        package.appendData(packageLengthData)
        package.appendData(data)
        let tag = incTag()
        socket.writeData(package, withTimeout: 7, tag: tag)
        return tag
    }
    
    func useValidationInfo(userId:String,appkey:String,apptoken:String)
    {
        if self.validationInfo == nil
        {
            self.validationInfo = ValidationInfo()
        }
        self.validationInfo.UserId = userId;
        self.validationInfo.Appkey = appkey;
        self.validationInfo.AppToken = apptoken
    }
    
    private func validate()
    {
        sendChicagoMessage(ChicagoClientCommonRoute.validationRoute, json: validationInfo.toJsonString())
    }
    
    func registDeviceToken(deviceToken:String!)
    {
        sendDeviceTokenLock.lock()
        self.deviceToken = deviceToken
        if String.isNullOrWhiteSpace(deviceToken) || deviceTokenSended || clientState != .Validated
        {
            return
        }else
        {
            deviceTokenSended = true
            sendChicagoMessage(ChicagoClientCommonRoute.registDeviceTokenRoute, json: "{ \"DeviceToken\":\"\(deviceToken)\",\"DeviceType\":\"iOS\" }")
        }
        sendDeviceTokenLock.unlock()
    }
    
    func logout()
    {
        if ChicagoClient.heartBeatTimer != nil{
            ChicagoClient.heartBeatTimer.invalidate()
            ChicagoClient.heartBeatTimer = nil
        }
        self.clientState = .UserLogout
        if validationInfo != nil{
            if sendChicagoMessage(ChicagoClientCommonRoute.logoutRoute, json: validationInfo.toJsonString())
            {
                self.clientState = .Closed
            }
        }else{
            close()
        }
    }
    
    func onLogoutReturn(a:NSNotification)
    {
        close()
    }
    
    func onOtherDeviceLogin(a:NSNotification)
    {
        clientState = .ValidatFailed
        socket.disconnect()
        self.postNotificationName(OtherDeviceLoginChicagoServer, object: self)
        NSLog("Chicago:Other Device Login Chicago Server")
    }
    
    func onBahamutAppNotification(a:NSNotification)
    {
        if let json = a.userInfo?[ChicagoClientReturnJsonValue] as? String
        {
            let notification = BahamutAppNotification(json:json)
            self.postNotificationName("BahamutAppNotify:\(notification.NotificationType)", object: self, userInfo: [BahamutAppNotificationValue:notification])
        }
        
    }
    
    func addBahamutAppNotificationObserver(observer:AnyObject,notificationType:String,selector:Selector,object:AnyObject?)
    {
        self.addObserver(observer, selector: selector, name: "BahamutAppNotify:\(notificationType)", object: object)
    }
    
    func removeBahamutAppNotificationObserver(observer:AnyObject,notificationType:String,object:AnyObject?)
    {
        self.removeObserver(observer, name: "BahamutAppNotify:\(notificationType)", object: object)
    }
    
    func onValidationReturn(a:NSNotification)
    {
        class ValidationReturn:EVObject
        {
            var IsValidate:String!
        }
        if let userInfo = a.userInfo
        {
            if let json = userInfo[ChicagoClientReturnJsonValue] as? String
            {
                if json.containsString("true")
                {
                    clientState = .Validated
                    ChicagoClient.lastHeartBeatTime = NSDate()
                    if String.isNullOrWhiteSpace(self.deviceToken) == false
                    {
                        self.registDeviceToken(self.deviceToken)
                    }
                }else
                {
                    clientState = .ValidatFailed
                    socket.disconnect()
                    self.postNotificationName(AppTokenInvalided, object: self)
                    NSLog("Chicago:Validate Failed")
                }
            }
            
        }
    }
    
    func heartBeat(_:NSTimer)
    {
        if self.clientState == .Validated
        {
            let now = NSDate()
            if now.timeIntervalSinceDate(ChicagoClient.lastHeartBeatTime) > ChicagoClient.heartBeatInterval * 1.5
            {
                NSLog("Chicago Server No Heart Beat Response")
                clientState = .Disconnected
                socket.disconnect()
            }else
            {
                sendChicagoMessage(ChicagoClientCommonRoute.heartBeatRoute, json: ChicagoClient.heartBeatJson)
            }
        }
    }
    
    func onHeartBeatReturn(a:NSNotification)
    {
        ChicagoClient.lastHeartBeatTime = NSDate()
    }

    func sendChicagoMessage(chicagoRoute:ChicagoRoute,json:String) -> Bool
    {
        let package = ChicagoProtocolUtil.getDataWithChicagoRouteAndJson(chicagoRoute, jsonString: json)
        return sendMessage(package) > 0
    }
    
    private func getAName(route:ChicagoRoute) -> String
    {
        let aName = "\(route.ExtName):" + (route.CmdId == -1 ? "\(route.CmdName)":"CmdId:\(route.CmdId)")
        return aName
    }
    
    func addChicagoObserver(route:ChicagoRoute,observer:AnyObject,selector:Selector)
    {
        self.addObserver(observer, selector: selector, name: getAName(route), object: nil)
    }
    
    //MARK: socket delegate
    func onSocket(sock: GCDAsyncSocket!, shouldTimeoutWriteWithTag tag: Int, elapsed: NSTimeInterval, bytesDone length: UInt) -> NSTimeInterval {
        return 16
    }
    
    func onSocket(sock: GCDAsyncSocket!, didReadData data: NSData!, withTag tag: Int)
    {
        if tag == ChicagoClient.readHeadTag
        {
            var head:Int32 = 0
            data.getBytes(&head, length: 4)
            sock.readDataToLength(UInt(head), withTimeout: -1, tag: ChicagoClient.readDataTag)
        }else if tag == ChicagoClient.readDataTag
        {
            let route = ChicagoProtocolUtil.getChicagoRouteFromData(data)
            let json = ChicagoProtocolUtil.getChicagoMessageJsonFromData(data)
            sock.readDataToLength(4, withTimeout: -1, tag: ChicagoClient.readHeadTag)
            if clientState == .Connected || clientState == .Validated
            {
                self.postNotificationName(getAName(route), object: self, userInfo: [ChicagoClientReturnJsonValue : json!])
            }
        }
    }
    
    func onSocket(sock: GCDAsyncSocket!, didWriteDataWithTag tag: Int)
    {
        
    }
    
    func onSocketWillConnect(sock: GCDAsyncSocket!) -> Bool {
        return true
    }
    
    func onSocket(sock: GCDAsyncSocket!, didConnectToHost host: String!, port: UInt16)
    {
        clientState = .Connected
        reConnectFailedTimes = 0;
        sock.readDataToLength(4, withTimeout: -1, tag: ChicagoClient.readHeadTag)
        validate()
    }
    
    func onSocketDidDisconnect(sock: GCDAsyncSocket!)
    {
        deviceTokenSended = false
        if clientState == .Closed || clientState == .ValidatFailed
        {
            return
        }
        reConnectFailedTimes += 1
        if reConnectFailedTimes < 3
        {
            start()
            connect(self.host, port: self.port)
        }
    }
    
    //MARK: actions
    func connect(host:String, port:UInt16)
    {
        if clientState != .Disconnected
        {
            return
        }
        self.host = host
        self.port = port
        do
        {
            clientState = .Connecting
            try socket.connectToHost(host, onPort: port)
        }catch let error as NSError
        {
            clientState = .Disconnected
            NSLog("Chicago:Connect Error:\(error.description)")
        }
    }
    
    func reConnect()
    {
        if clientState == .ValidatFailed || clientState == .Closed
        {
            ChicagoClient.sharedInstance.start()
            connect(self.host, port: self.port)
        }
    }
    
    func start()
    {
        socket.disconnect()
        clientState = .Disconnected
    }
    
    func inBackground()
    {
        self.clientState = .Closed
        socket.disconnect()
    }
    
    func close()
    {
        if let timer = ChicagoClient.heartBeatTimer{
            timer.invalidate()
        }
        ChicagoClient.heartBeatTimer = nil
        self.clientState = .Closed
        socket.disconnect()
    }
    
}