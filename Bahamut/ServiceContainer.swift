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
    static let instance:ServiceContainer = ServiceContainer()
    private var serviceDict:[String:ServiceProtocol]!
    private var userId:String!
    private init()
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
            service.appStartInit()
        }
    }
    
    func userLogin(userId:String)
    {
        self.userId = userId
        
        for (_,service) in ServiceConfig.Services
        {
            if let initHandler = service.userLoginInit
            {
                initHandler(userId)
            }
        }
    }
    
    func userLogout()
    {
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
}

