//
//  BahamutCmdManager.swift
//  Bahamut
//
//  Created by AlexChow on 15/10/30.
//  Copyright © 2015年 GStudio. All rights reserved.
//

import Foundation

//MARK: BahamutCmdManager
class BahamutCmdManager
{
    fileprivate(set) static var sharedInstance:BahamutCmdManager = {
       return BahamutCmdManager()
    }()
    
    fileprivate var handlerList = [HandleBahamutCmdDelegate]()
    fileprivate var handlerCmdQueue = [(String,AnyObject?)]()
    
    func pushCmd(_ cmd:String,object:AnyObject? = nil)
    {
        handlerCmdQueue.append((cmd,object))
    }
    
    func handleCmdQueue()
    {
        let cmdCopy = handlerCmdQueue.map{$0}
        handlerCmdQueue.removeAll()
        for cmd in cmdCopy
        {
            self.handleBahamutCmd(cmd.0,object: cmd.1)
        }
    }
    
    func removeHandler(_ handler:HandleBahamutCmdDelegate)
    {
        handlerList.removeElement { (itemInArray) -> Bool in
            let a = itemInArray as! NSObject
            let b = handler as! NSObject
            if a == b
            {
                return true
            }
            return false
        }
    }
    
    func registHandler(_ handler:HandleBahamutCmdDelegate)
    {
        let exists = handlerList.contains{
            let a = $0 as! NSObject
            let b = handler as! NSObject
            return a == b
        }
        if exists == false
        {
            handlerList.append(handler)
        }
    }
    
    func handleBahamutEncodedCmd(_ cmdEncoded:String,object:AnyObject? = nil) {
        if let cmd = BahamutCmd.decodeBahamutCmd(cmdEncoded){
            handleBahamutCmd(cmd,object: object)
        }
    }
    
    func handleBahamutEncodedCmdWithMainQueue(_ cmdEncoded:String,object:AnyObject? = nil)
    {
        if let cmd = BahamutCmd.decodeBahamutCmd(cmdEncoded){
            handleBahamutCmdWithMainQueue(cmd,object: object)
        }
    }
    
    func handleBahamutEncodedCmdWithGlobalQueue(_ cmdEncoded:String,object:AnyObject? = nil)
    {
        if let cmd = BahamutCmd.decodeBahamutCmd(cmdEncoded){
            handleBahamutCmdWithGlobalQueue(cmd, object: object)
        }
    }
    
    func handleBahamutCmd(_ cmd:String,object:AnyObject? = nil)
    {
        
        if let method = BahamutCmd.getCmdMethod(cmd)
        {
            let args = BahamutCmd.getCmdParameters(cmd)
            for h in self.handlerList
            {
                h.handleBahamutCmd(method, args: args,object: object)
            }
        }
        
    }
    
    func handleBahamutCmdWithMainQueue(_ cmd:String,object:AnyObject? = nil)
    {
        DispatchQueue.main.async { () -> Void in
            self.handleBahamutCmd(cmd,object: object)
        }
    }
    
    func handleBahamutCmdWithGlobalQueue(_ cmd:String,object:AnyObject? = nil)
    {
        DispatchQueue.global().async { () -> Void in
            self.handleBahamutCmd(cmd,object: object)
        }
    }
    
    func clearHandler()
    {
        handlerList.removeAll()
    }
}
