//
//  ServiceContainer.swift
//  Bahamut
//
//  Created by AlexChow on 15/7/29.
//  Copyright (c) 2015年 GStudio. All rights reserved.
//

import Foundation

public class ServiceContainer:NSNotificationCenter
{
    public static let AllServicesReady = "AllServicesReady"
    public static let instance:ServiceContainer = ServiceContainer()
    private var serviceDict:[String:ServiceProtocol]!
    private let serviceReadyLock = NSRecursiveLock()
    private var serviceReady = [String:Bool]()
    private var userId:String!
    private override init()
    {
        
    }
    
    public func initContainer()
    {
        serviceDict = [String:ServiceProtocol]()
        for (name,service) in ServiceConfig.Services
        {
            addService(name,service: service)
        }
        
        for (_,service) in serviceDict
        {
            if let handler = service.appStartInit
            {
                handler()
            }
        }
    }
    
    public func userLogin(userId:String)
    {
        self.userId = userId
        serviceReadyLock.lock()
        for (name,_) in ServiceConfig.Services
        {
            serviceReady[name] = false
        }
        serviceReadyLock.unlock()
        for (_,service) in ServiceConfig.Services
        {
            if let initHandler = service.userLoginInit
            {
                dispatch_async(dispatch_get_main_queue(), { () -> Void in
                    initHandler(userId)
                })
            }
        }
    }
    
    public func userLogout()
    {
        serviceReadyLock.lock()
        serviceReady.removeAll()
        serviceReadyLock.unlock()
        for (_,service) in ServiceConfig.Services
        {
            if let logoutHandler = service.userLogout
            {
                logoutHandler(userId)
            }
        }
    }
    
    private func addService(serviceName:String,service:ServiceProtocol)
    {
        serviceDict[serviceName] = service
    }
    
    public static func getService(serviceName:String) -> ServiceProtocol?
    {
        return instance.serviceDict[serviceName]
    }
    
    public static func getService<T:ServiceProtocol>(type:T.Type) -> T
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
    
    public static var isAllServiceReady:Bool{
        for (serviceName,_) in ServiceConfig.Services
        {
            if isServiceReady(serviceName) == false
            {
                return false
            }
        }
        return true
    }
    
    public static func isServiceReady(serviceName:String) -> Bool
    {
        if let isReady = instance.serviceReady[serviceName]
        {
            return isReady
        }
        return false
    }
    
    public static func isServiceReady<T:ServiceProtocol>(service:T) -> Bool
    {
        return isServiceReady(T.ServiceName)
    }
}

public extension ServiceProtocol
{
    public func setServiceReady()
    {
        ServiceContainer.setServiceReady(self)
    }
    
    public var isServiceReady:Bool
    {
        return ServiceContainer.isServiceReady(self)
    }
}

