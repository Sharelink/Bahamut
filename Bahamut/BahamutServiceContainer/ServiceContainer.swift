//
//  ServiceContainer.swift
//  Bahamut
//
//  Created by AlexChow on 15/7/29.
//  Copyright (c) 2015年 GStudio. All rights reserved.
//

import Foundation

let InitServiceFailedReason = "ServiceInitFailed"

class ServiceContainer:NSNotificationCenter
{
    static let AllServicesReady = "AllServicesReady"
    static let ServiceInitFailed = "ServiceInitFailed"
    static let instance:ServiceContainer = ServiceContainer()
    private var serviceDict:[String:ServiceProtocol]!
    private var serviceList:[ServiceProtocol]!
    private let serviceReadyLock = NSRecursiveLock()
    private var serviceReady = [String:Bool]()
    private var userId:String!
    private(set) static var appName = "BahamutServiceContainer"
    private override init()
    {
        
    }
    
    func initContainer(appName:String,services:ServiceListDict)
    {
        ServiceContainer.appName = appName
        serviceDict = [String:ServiceProtocol]()
        serviceList = [ServiceProtocol]()
        for (name,service) in services
        {
            addService(name,service: service)
        }
        
        for (_,service) in serviceDict
        {
            if let handler = service.appStartInit
            {
                handler(ServiceContainer.appName)
            }
        }
        NSLog("Init Service Container Completed")
    }
    
    func postInitServiceFailed(reason:String)
    {
        self.userLogout()
        self.postNotificationName(ServiceContainer.ServiceInitFailed, object: nil, userInfo: [InitServiceFailedReason:reason])
    }
    
    func userLogin(userId:String)
    {
        self.userId = userId
        serviceReadyLock.lock()
        for (name,_) in self.serviceDict
        {
            serviceReady[name] = false
        }
        serviceReadyLock.unlock()
        serviceList.forEach { (service) -> () in
            if let initHandler = service.userLoginInit
            {
                dispatch_async(dispatch_get_main_queue(), { () -> Void in
                    initHandler(userId)
                })
            }
        }
    }
    
    func userLogout()
    {
        serviceReadyLock.lock()
        serviceReady.removeAll()
        serviceReadyLock.unlock()
        serviceList.forEach { (service) -> () in
            if let logoutHandler = service.userLogout
            {
                logoutHandler(userId)
            }
        }
    }
    
    private func addService(serviceName:String,service:ServiceProtocol)
    {
        serviceList.append(service)
        serviceDict[serviceName] = service
    }
    
    static func getService(serviceName:String) -> ServiceProtocol?
    {
        return instance.serviceDict[serviceName]
    }
    
    static func getService<T:ServiceProtocol>(type:T.Type) -> T
    {
        return getService(T.ServiceName) as! T
    }
    
    private static func setServiceReady<T:ServiceProtocol>(service:T)
    {
        instance.serviceReadyLock.lock()
        let value = instance.serviceReady[T.ServiceName]
        if value == nil || value == true
        {
            instance.serviceReadyLock.unlock()
            return
        }
        instance.serviceReady[T.ServiceName] = true
        instance.serviceReadyLock.unlock()
        NSLog("\(T.ServiceName) Ready!")
        if isAllServiceReady
        {
            NSLog("All Services Ready!")
            dispatch_async(dispatch_get_main_queue(), { () -> Void in
                instance.postNotificationName(ServiceContainer.AllServicesReady, object: instance)
            })
        }
    }
    
    static var isAllServiceReady:Bool{
        if let list = self.instance.serviceList
        {
            for service in list
            {
                if service.isServiceReady == false
                {
                    return false
                }
            }
            return true
        }else
        {
            return false
        }
        
    }
    
    static func isServiceReady(serviceName:String) -> Bool
    {
        if let isReady = instance.serviceReady[serviceName]
        {
            return isReady
        }
        return false
    }
    
    static func isServiceReady<T:ServiceProtocol>(service:T) -> Bool
    {
        return isServiceReady(T.ServiceName)
    }
}

extension ServiceProtocol
{
    func setServiceReady()
    {
        ServiceContainer.setServiceReady(self)
    }
    
    var isServiceReady:Bool
    {
        return ServiceContainer.isServiceReady(self)
    }
}

