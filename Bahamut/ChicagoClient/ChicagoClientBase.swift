//
//  ChicagoClientBase.swift
//  Bahamut
//
//  Created by AlexChow on 15/12/2.
//  Copyright © 2015年 GStudio. All rights reserved.
//

import Foundation
import EVReflection
import CocoaAsyncSocket

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

let ChicagoClientBeforeChangedState = "ChicagoClientBeforeChangedState"
let ChicagoClientCurrentState = "ChicagoClientCurrentState"

enum ChicagoClientState : Int
{
    case Closed = 1
    case Connected = 2
    case Disconnected = 3
    case Connecting = 4
    case Validated = 5
    case ValidatFailed = 6
    case UserLogout = 7
}