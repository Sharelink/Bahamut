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
    func handleBahamutCmd(_ method:String,args:[String],object:AnyObject?)
}

//MARK: BahamutCmd
class BahamutCmd
{
    fileprivate(set) static var cmdUrlSchema = "bahamut"
    static let cmdUrlSchemaUrlPrefix = {
       return "\(cmdUrlSchema)://"
    }()
    
    static func signBahamutCmdSchema(_ newSchema:String)
    {
        cmdUrlSchema = newSchema
    }
    
    static func isBahamutCmdUrl(_ url:String) -> Bool
    {
        return url.lowercased().hasPrefix(cmdUrlSchemaUrlPrefix)
    }
    
    static func encodeBahamutCmd(_ cmd:NSString) -> String
    {
        return cmd.base64UrlEncoded()
    }
    
    static func decodeBahamutCmd(_ cmdEncoded:String) -> String!
    {
        if cmdEncoded.isEmpty
        {
            return nil
        }
        
        if let data = Data(base64Encoded: cmdEncoded)
        {
            if data.count < 4
            {
                return nil
            }
            return NSString(data: data as Data, encoding: String.Encoding.utf8.rawValue) as? String
        }
        return nil
        
    }
    
    static func getCmdMethod(_ cmd:String) -> String!
    {
        let range = cmd.range(of: "(")
        if let startIndex = range?.lowerBound
        {
            return cmd.substring(to: startIndex)
        }
        return nil
    }
    
    static func getCmdParameters(_ cmd:String) -> [String]
    {
        
        if let low = cmd.range(of: "(")?.lowerBound,let endIndex = cmd.range(of: ")")?.lowerBound{
            let startIndex = cmd.index(low, offsetBy: 1)
            let parameters = cmd.substringWithRange(startIndex, endIndex: endIndex)
            return parameters.split(",")
        }
        return [String]()
    }
    
    static func getCmdFromUrl(_ bahamutCmdUrl:String) -> String
    {
        let cmdEncoded = bahamutCmdUrl.substring(from: cmdUrlSchemaUrlPrefix.endIndex)
        return decodeBahamutCmd(cmdEncoded)
    }
    
    static func generateBahamutCmdEncoded(_ method:String,args:CVarArg...) -> String
    {
        return generateBahamutCmdEncodedBase(method, args: args)
    }
    
    static func generateBahamutCmdEncodedBase(_ method:String,args:[CVarArg]) -> String
    {
        var cmd:NSString
        if args.count == 0
        {
            cmd = "\(method)()" as NSString
        }else
        {
            cmd = "\(method)(\(args.map{ "\($0)" }.joined(separator: ",")))" as NSString
        }
        return encodeBahamutCmd(cmd)
    }
    
    static func buildBahamutCmdUrl(_ cmdEncoded:String) -> String
    {
        return "\(cmdUrlSchema)://\(cmdEncoded)"
    }
    
    static func generateBahamutCmdUrl(_ method:String,args:CVarArg...) -> String
    {
        let cmd = generateBahamutCmdEncodedBase(method, args: args)
        return buildBahamutCmdUrl(cmd)
    }
}
