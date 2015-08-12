//
//  ServiceContainer.swift
//  Bahamut
//
//  Created by AlexChow on 15/7/29.
//  Copyright (c) 2015年 GStudio. All rights reserved.
//

import Foundation

class ServiceContainer
{
    static let instance:ServiceContainer! = ServiceContainer()
    private var serviceDict:[String:ServiceProtocol]!
    
    private init()
    {
        serviceDict = [String:ServiceProtocol]()
        for (serviceName,service) in ServiceConfig.Services
        {
            addService(serviceName,service: service)
        }
        
        for (_,service) in serviceDict
        {
            service.initService()
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
}

