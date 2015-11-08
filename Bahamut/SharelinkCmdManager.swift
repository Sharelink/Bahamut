//
//  SharelinkCmdManager.swift
//  Bahamut
//
//  Created by AlexChow on 15/10/30.
//  Copyright © 2015年 GStudio. All rights reserved.
//

import Foundation

class SharelinkCmdManager
{
    private(set) static var sharedInstance:SharelinkCmdManager = {
       return SharelinkCmdManager()
    }()
    
    private var handlerList = [HandleSharelinkCmdDelegate]()
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
            self.handleSharelinkCmd(cmd.0,object: cmd.1)
        }
    }
    
    func registHandler(handler:HandleSharelinkCmdDelegate)
    {
        handlerList.append(handler)
    }
    
    func handleSharelinkCmd(cmd:String,object:AnyObject? = nil)
    {
        
        if let method = SharelinkCmd.getCmdMethod(cmd)
        {
            let args = SharelinkCmd.getCmdParameters(cmd)
            for h in self.handlerList
            {
                h.handleSharelinkCmd(method, args: args,object: object)
            }
        }
        
    }
    
    func handleSharelinkCmdWithMainQueue(cmd:String,object:AnyObject? = nil)
    {
        dispatch_async(dispatch_get_main_queue()) { () -> Void in
            self.handleSharelinkCmd(cmd,object: object)
        }
    }
    
    func handleSharelinkCmdWithGlobalQueue(cmd:String,object:AnyObject? = nil)
    {
        dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0)) { () -> Void in
            self.handleSharelinkCmd(cmd,object: object)
        }
    }
    
    func clearHandler()
    {
        handlerList.removeAll()
    }
}