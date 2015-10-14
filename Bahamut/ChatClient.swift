//
//  ChatClient.swift
//  Bahamut
//
//  Created by AlexChow on 15/10/12.
//  Copyright © 2015年 GStudio. All rights reserved.
//

import Foundation
import CocoaAsyncSocket
import EVReflection

class ChicagoRoute : EVObject
{
    var ExtName:String!
    var CmdId:Int = -1
    var CmdName:String!
}

class ChicagoProtocolUtil
{
    static func getChicagoRouteFromData(data:NSData) -> ChicagoRoute
    {
        var headLength:Int = 0
        data.getBytes(&headLength, length: 4)
        let routeData = data.subdataWithRange(NSMakeRange(4, headLength))
        let json = String(data: routeData, encoding: NSUTF8StringEncoding)
        return ChicagoRoute(json: json)
    }
    
    static func getChicagoMessageJsonFromData(data:NSData) -> String?
    {
        var headLength:Int = 0
        data.getBytes(&headLength, length: 4)
        let routeInfoLenght = 4 + headLength
        let jsonData = data.subdataWithRange(NSMakeRange(routeInfoLenght, data.length - routeInfoLenght))
        return String(data: jsonData, encoding: NSUTF8StringEncoding)
    }
    
    static func getDataWithChicagoRouteAndJson(chicagoRoute:ChicagoRoute,jsonString:String) -> NSData
    {
        let jsonData = jsonString.toUTF8EncodingData()
        let routeData = chicagoRoute.toJsonString().toUTF8EncodingData()
        var dataLength = Int32(routeData.length)
        let lengthData = NSData(bytes: &dataLength, length: 4)
        let package = NSMutableData()
        package.appendData(lengthData)
        package.appendData(routeData)
        package.appendData(jsonData)
        return package
    }
}

let ChicagoClientReturnJsonValue = "ChicagoReturnJsonValue"
let ChicagoClientStateChanged = "ChicagoClientStateChanged"

enum ChicagoClientState
{
    case Connected
    case Disconnected
    case Connecting
}

class ChicagoClient :NSNotificationCenter,AsyncSocketDelegate
{
    class ValidationInfo: EVObject
    {
        var UserId:String!
        var AppToken:String!
        var Appkey:String!
        
    }
    var socket:AsyncSocket!
    
    private(set) var validationInfo:ValidationInfo!
    private(set) var appToken:String!
    private(set) var userId:String!
    
    private(set) var host:String!
    private(set) var port:UInt16 = 0
    private(set) var reConnectFailedTimes:Int = 0
    private(set) var clientState:ChicagoClientState = .Disconnected{
        didSet{
            self.postNotificationName(ChicagoClientStateChanged, object: self)
        }
    }
    static let readHeadTag = 1
    static let readDataTag = 2
    private var tag:Int = 7
    static var sharedInstance:ChicagoClient = {
        return ChicagoClient()
    }()
    
    override init() {
        super.init()
        socket = AsyncSocket()
        socket.setDelegate(self)
    }
    
    private func incTag() -> Int
    {
        return tag++
    }
    
    private func sendMessage(data:NSData) -> Int
    {
        var dataLength = Int32(data.length)
        let packageLengthData = NSData(bytes: &dataLength, length: 4)
        let package = NSMutableData()
        package.appendData(packageLengthData)
        package.appendData(data)
        let tag = incTag()
        socket.writeData(package, withTimeout: -1, tag: tag)
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
    
    func validate()
    {
        let route = ChicagoRoute()
        route.ExtName = "SharelinkerValidation"
        route.CmdName = "Login"
        
        sendChicagoMessage(route, json: validationInfo.toJsonString())
    }
    
    func heartBeat()
    {
        let dict = [":)":":>"]
        let msg = EVObject(dictionary: dict)
        
        let route = ChicagoRoute()
        route.ExtName = "HeartBeat"
        route.CmdName = "Beat"
        
        sendChicagoMessage(route, json: msg.toJsonString())
    }
    
    func sendChicagoMessage(chicagoRoute:ChicagoRoute,json:String)
    {
        let package = ChicagoProtocolUtil.getDataWithChicagoRouteAndJson(chicagoRoute, jsonString: json)
        sendMessage(package)
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
    
    func onSocket(sock: AsyncSocket!, didReadData data: NSData!, withTag tag: Int)
    {
        if tag == ChicagoClient.readHeadTag
        {
            var head:Int32 = 0
            data.getBytes(&head, length: 4)
            sock.readDataToLength(UInt(head), withTimeout: 0, tag: ChicagoClient.readDataTag)
        }else if tag == ChicagoClient.readDataTag
        {
            let route = ChicagoProtocolUtil.getChicagoRouteFromData(data)
            let json = ChicagoProtocolUtil.getChicagoMessageJsonFromData(data)
            print(json)
            self.postNotificationName(getAName(route), object: self, userInfo: [ChicagoClientReturnJsonValue : json!])
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
        clientState = .Disconnected
        reConnectFailedTimes++
        if reConnectFailedTimes < 3
        {
            reConnect()
        }
    }
    
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
        }catch
        {
            clientState = .Disconnected
        }
    }
    
    func reConnect()
    {
        connect(self.host, port: self.port)
    }
    
    func close()
    {
        socket.disconnect()
    }
    
}