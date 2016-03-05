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
    private(set) static var sharedInstance:BahamutCmdManager = {
       return BahamutCmdManager()
    }()
    
    private var handlerList = [HandleBahamutCmdDelegate]()
    private var handlerCmdQueue = [(String,AnyObject?)]()
    
    func pushCmd(cmd:String,object:AnyObject? = nil)
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
    
    func removeHandler(handler:HandleBahamutCmdDelegate)
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
    
    func registHandler(handler:HandleBahamutCmdDelegate)
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
    
    func handleBahamutCmd(cmd:String,object:AnyObject? = nil)
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
    
    func handleBahamutCmdWithMainQueue(cmd:String,object:AnyObject? = nil)
    {
        dispatch_async(dispatch_get_main_queue()) { () -> Void in
            self.handleBahamutCmd(cmd,object: object)
        }
    }
    
    func handleBahamutCmdWithGlobalQueue(cmd:String,object:AnyObject? = nil)
    {
        dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0)) { () -> Void in
            self.handleBahamutCmd(cmd,object: object)
        }
    }
    
    func clearHandler()
    {
        handlerList.removeAll()
    }
}