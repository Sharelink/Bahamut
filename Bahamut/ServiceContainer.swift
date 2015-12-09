//
//  ServiceContainer.swift
//  Bahamut
//
//  Created by AlexChow on 15/7/29.
//  Copyright (c) 2015年 GStudio. All rights reserved.
//

import Foundation

class ServiceContainer:NSNotificationCenter
{
    static let AllServicesReady = "AllServicesReady"
    static let instance:ServiceContainer = ServiceContainer()
    private var serviceDict:[String:ServiceProtocol]!
    private var serviceReady = [String:Bool]()
    private var userId:String!
    private override init()
    {
        
    }
    
    func initContainer()
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
    
    func userLogin(userId:String)
    {
        self.userId = userId
        
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
    
    func userLogout()
    {
        serviceReady.removeAll()
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
        instance.serviceReady[T.ServiceName] = true
        NSLog("\(T.ServiceName) Ready!")
        if isAllServiceReady
        {
            dispatch_async(dispatch_get_main_queue(), { () -> Void in
                instance.postNotificationName(ServiceContainer.AllServicesReady, object: instance)
            })
        }
    }
    
    private static func setServiceNotReady<T:ServiceProtocol>(service:T)
    {
        instance.serviceReady[T.ServiceName] = false
    }
    
    static var isAllServiceReady:Bool{
        for (serviceName,_) in ServiceConfig.Services
        {
            if let isReady = instance.serviceReady[serviceName]
            {
                if !isReady
                {
                    return false
                }
            }else
            {
                return false
            }
        }
        return true
    }
}

extension ServiceProtocol
{
    func setServiceReady()
    {
        ServiceContainer.setServiceReady(self)
    }
}

