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

//MARK: Chicago Client
class ChicagoClient :NSNotificationCenter,AsyncSocketDelegate
{
    private static let heartBeatJson = "{}"
    private static let heartBeatRoute:ChicagoRoute = {
        let route = ChicagoRoute()
        route.ExtName = "HeartBeat"
        route.CmdName = "Beat"
        return route
    }()
    
    private static var heartBeatTimer:NSTimer!
    private static var lastHeartBeatTime:NSDate!
    private static var heartBeatInterval:NSTimeInterval = 23
    
    static let validationRoute:ChicagoRoute = {
        let route = ChicagoRoute()
        route.ExtName = "SharelinkerValidation"
        route.CmdName = "Login"
        return route
    }()
    
    private static let logoutRoute:ChicagoRoute = {
        let route = ChicagoRoute()
        route.ExtName = "SharelinkerValidation"
        route.CmdName = "Logout"
        return route
    }()
    
    private static let registDeviceTokenRoute:ChicagoRoute = {
        let route = ChicagoRoute()
        route.ExtName = "NotificationCenter"
        route.CmdName = "RegistDeviceToken"
        return route
    }()
    
    class ValidationInfo: EVObject
    {
        var UserId:String!
        var AppToken:String!
        var Appkey:String!
    }
    private var socket:AsyncSocket!
    
    private(set) var validationInfo:ValidationInfo!
    private(set) var appToken:String!
    private(set) var userId:String!
    
    private var deviceTokenSended:Bool = false
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
        
        socket = AsyncSocket()
        socket.setDelegate(self)
        
        self.addChicagoObserver(ChicagoClient.validationRoute, observer: self, selector: "onValidationReturn:")
        self.addChicagoObserver(ChicagoClient.logoutRoute, observer: self, selector: "onLogoutReturn:")
        self.addChicagoObserver(ChicagoClient.heartBeatRoute, observer: self, selector: "onHeartBeatReturn:")
    }
    
    func startHeartBeat()
    {
        ChicagoClient.heartBeatTimer = NSTimer.scheduledTimerWithTimeInterval(ChicagoClient.heartBeatInterval, target: self, selector: "heartBeat:", userInfo: nil, repeats: true)
    }
    
    private func incTag() -> Int
    {
        return tag++
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
        sendChicagoMessage(ChicagoClient.validationRoute, json: validationInfo.toJsonString())
    }
    
    func registDeviceToken(deviceToken:String!)
    {
        sendDeviceTokenLock.lock()
        if String.isNullOrWhiteSpace(deviceToken) || deviceTokenSended || clientState != .Validated
        {
            return
        }else
        {
            deviceTokenSended = true
            sendChicagoMessage(ChicagoClient.registDeviceTokenRoute, json: "{ \"DeviceToken\":\"\(deviceToken)\" }")
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
        if sendChicagoMessage(ChicagoClient.logoutRoute, json: validationInfo.toJsonString())
        {
            self.clientState = .Closed
        }
    }
    
    func onLogoutReturn(a:NSNotification)
    {
        close()
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
                    self.registDeviceToken(SharelinkSetting.deviceToken)
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
                sendChicagoMessage(ChicagoClient.heartBeatRoute, json: ChicagoClient.heartBeatJson)
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
    func onSocket(sock: AsyncSocket!, willDisconnectWithError err: NSError!) {
        clientState = .Disconnected
    }
    
    func onSocket(sock: AsyncSocket!, shouldTimeoutWriteWithTag tag: Int, elapsed: NSTimeInterval, bytesDone length: UInt) -> NSTimeInterval {
        return 16
    }
    
    func onSocket(sock: AsyncSocket!, didReadData data: NSData!, withTag tag: Int)
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
    
    func onSocket(sock: AsyncSocket!, didWriteDataWithTag tag: Int)
    {
        
    }
    
    func onSocketWillConnect(sock: AsyncSocket!) -> Bool {
        return true
    }
    
    func onSocket(sock: AsyncSocket!, didConnectToHost host: String!, port: UInt16)
    {
        clientState = .Connected
        reConnectFailedTimes = 0;
        sock.readDataToLength(4, withTimeout: -1, tag: ChicagoClient.readHeadTag)
        validate()
    }
    
    func onSocketDidDisconnect(sock: AsyncSocket!)
    {
        deviceTokenSended = false
        if clientState == .Closed || clientState == .ValidatFailed
        {
            return
        }
        reConnectFailedTimes++
        if reConnectFailedTimes < 3
        {
            reConnect()
        }else
        {
            clientState = .Disconnected
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
        }
        connect(self.host, port: self.port)
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
        ChicagoClient.heartBeatTimer.invalidate()
        ChicagoClient.heartBeatTimer = nil
        self.clientState = .Closed
        socket.disconnect()
    }
    
}