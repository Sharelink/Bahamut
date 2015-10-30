//
//  SharelinkCmd.swift
//  Bahamut
//
//  Created by AlexChow on 15/10/30.
//  Copyright © 2015年 GStudio. All rights reserved.
//

import Foundation

protocol HandleSharelinkCmdDelegate
{
    func handleSharelinkCmd(method:String,args:[String],object:AnyObject?)
}

class SharelinkCmd
{
    static let sharelinkUrlSchema = "sharelink"
    static let sharelinkUrlSchemaUrlPrefix = {
       return "\(sharelinkUrlSchema)://"
    }()
    
    static func isSharelinkCmdUrl(url:String) -> Bool
    {
        return url.lowercaseString.hasPrefix(sharelinkUrlSchemaUrlPrefix)
    }
    
    static func encodeSharelinkCmd(cmd:NSString) -> String
    {
        return cmd.base64UrlEncodedString()
    }
    
    static func decodeSharelinkCmd(cmdEncoded:String) -> String!
    {
        if cmdEncoded.isEmpty
        {
            return nil
        }
        if let data = NSData(base64UrlEncodedString: cmdEncoded)
        {
            return data.base64UrlEncodedString()
        }
        return nil
        
    }
    
    static func getCmdMethod(cmd:String) -> String!
    {
        let range = cmd.rangeOfString("(")
        if let startIndex = range?.first
        {
            return cmd.substringToIndex(startIndex)
        }
        return nil
    }
    
    static func getCmdParameters(cmd:String) -> [String]
    {
        let startIndex = cmd.rangeOfString("(")?.first?.advancedBy(1)
        let endIndex = cmd.rangeOfString(")")?.first
        if startIndex != nil && endIndex != nil
        {
            let parameters = cmd.substringWithRange(startIndex!, endIndex: endIndex!)
            return parameters.split(",")
        }
        return [String]()
    }
    
    static func getCmdFromUrl(sharelinkCmdUrl:String) -> String
    {
        let cmdEncoded = sharelinkCmdUrl.substringFromIndex(sharelinkUrlSchemaUrlPrefix.endIndex)
        return decodeSharelinkCmd(cmdEncoded)
    }
    
    static func generateSharelinkCmdEncoded(method:String,args:CVarArgType...) -> String
    {
        return generateSharelinkCmdEncodedBase(method, args: args)
    }
    
    static func generateSharelinkCmdEncodedBase(method:String,args:[CVarArgType]) -> String
    {
        var cmd:NSString
        if args.count == 0
        {
            cmd = "\(method)()"
        }else
        {
            cmd = "\(method)(\(args.map{ "\($0)" }.joinWithSeparator(",")))"
        }
        return encodeSharelinkCmd(cmd)
    }
    
    static func generateSharelinkCmdUrl(method:String,args:CVarArgType...) -> String
    {
        let cmd = generateSharelinkCmdEncodedBase(method, args: args)
        return "\(sharelinkUrlSchema)://\(cmd)"
    }
}