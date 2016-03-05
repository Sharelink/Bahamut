//
//  BahamutCmd.swift
//  Bahamut
//
//  Created by AlexChow on 15/10/30.
//  Copyright © 2015年 GStudio. All rights reserved.
//

import Foundation


protocol HandleBahamutCmdDelegate
{
    func handleBahamutCmd(method:String,args:[String],object:AnyObject?)
}

//MARK: BahamutCmd
class BahamutCmd
{
    private(set) static var cmdUrlSchema = "bahamut"
    static let cmdUrlSchemaUrlPrefix = {
       return "\(cmdUrlSchema)://"
    }()
    
    static func signBahamutCmdSchema(newSchema:String)
    {
        cmdUrlSchema = newSchema
    }
    
    static func isBahamutCmdUrl(url:String) -> Bool
    {
        return url.lowercaseString.hasPrefix(cmdUrlSchemaUrlPrefix)
    }
    
    static func encodeBahamutCmd(cmd:NSString) -> String
    {
        return cmd.base64UrlEncodedString()
    }
    
    static func decodeBahamutCmd(cmdEncoded:String) -> String!
    {
        if cmdEncoded.isEmpty
        {
            return nil
        }
        if let data = NSData(base64UrlEncodedString: cmdEncoded)
        {
            if data.length < 4
            {
                return nil
            }
            return NSString(data: data, encoding: NSUTF8StringEncoding) as? String
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
        let cmdEncoded = sharelinkCmdUrl.substringFromIndex(cmdUrlSchemaUrlPrefix.endIndex)
        return decodeBahamutCmd(cmdEncoded)
    }
    
    static func generateBahamutCmdEncoded(method:String,args:CVarArgType...) -> String
    {
        return generateBahamutCmdEncodedBase(method, args: args)
    }
    
    static func generateBahamutCmdEncodedBase(method:String,args:[CVarArgType]) -> String
    {
        var cmd:NSString
        if args.count == 0
        {
            cmd = "\(method)()"
        }else
        {
            cmd = "\(method)(\(args.map{ "\($0)" }.joinWithSeparator(",")))"
        }
        return encodeBahamutCmd(cmd)
    }
    
    static func buildBahamutCmdUrl(cmdEncoded:String) -> String
    {
        return "\(cmdUrlSchema)://\(cmdEncoded)"
    }
    
    static func generateBahamutCmdUrl(method:String,args:CVarArgType...) -> String
    {
        let cmd = generateBahamutCmdEncodedBase(method, args: args)
        return buildBahamutCmdUrl(cmd)
    }
}