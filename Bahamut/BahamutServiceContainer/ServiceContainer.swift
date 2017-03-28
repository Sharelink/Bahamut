//
//  ServiceContainer.swift
//  Bahamut
//
//  Created by AlexChow on 15/7/29.
//  Copyright (c) 2015年 GStudio. All rights reserved.
//

import Foundation

let InitServiceFailedReason = "InitServiceFailedReason"
let ServiceContainerNotifyService = "ServiceContainerNotifyService"

extension String{
    func asNotificationName() -> Notification.Name {
        return Notification.Name(self)
    }
}

class ServiceContainer:NotificationCenter
{
    static let OnAllServicesReady = "AllServicesReady".asNotificationName()
    static let OnServiceInitFailed = "ServiceInitFailed".asNotificationName()
    
    static let OnServicesWillLogin = "OnServicesWillLogin".asNotificationName()
    static let OnServicesDidLogin = "OnServicesDidLogin".asNotificationName()
    static let OnServicesWillLogout = "OnServicesWillLogout".asNotificationName()
    static let OnServicesDidLogout = "OnServicesDidLogout".asNotificationName()
    static let OnServiceReady = "OnServiceReady".asNotificationName()
    
    static let instance:ServiceContainer = ServiceContainer()
    fileprivate var containerInited = false
    fileprivate var serviceDict:[String:ServiceProtocol]!
    fileprivate var serviceList:[ServiceProtocol]!
    fileprivate let serviceReadyLock = NSRecursiveLock()
    fileprivate var serviceReady = [String:Bool]()
    fileprivate var userId:String!
    fileprivate(set) static var appName = "BahamutServiceContainer"
    fileprivate override init()
    {
        
    }
    
    func initContainer(_ appName:String,services:ServiceListDict)
    {
        if containerInited {
            return
        }
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
        debugLog("Init Service Container Completed")
    }
    
    func postInitServiceFailed(_ reason:String)
    {
        self.userLogout()
        self.post(name: ServiceContainer.OnServiceInitFailed, object: nil, userInfo: [InitServiceFailedReason:reason])
    }
    
    func userLogin(_ userId:String)
    {
        self.userId = userId
        serviceReadyLock.lock()
        for (name,_) in self.serviceDict
        {
            serviceReady[name] = false
        }
        serviceReadyLock.unlock()
        self.post(name: ServiceContainer.OnServicesWillLogin, object: self)
        serviceList.forEach { (service) -> () in
            if let initHandler = service.userLoginInit
            {
                DispatchQueue.main.async(execute: { () -> Void in
                    initHandler(userId)
                })
            }
        }
        self.post(name: ServiceContainer.OnServicesDidLogin, object: self)
    }
    
    func userLogout()
    {
        serviceReadyLock.lock()
        serviceReady.removeAll()
        serviceReadyLock.unlock()
        self.post(name: ServiceContainer.OnServicesWillLogout, object: self)
        serviceList.forEach { (service) -> () in
            if let logoutHandler = service.userLogout
            {
                logoutHandler(userId)
            }
        }
        self.post(name: ServiceContainer.OnServicesDidLogout, object: self)
    }
    
    fileprivate func addService(_ serviceName:String,service:ServiceProtocol)
    {
        serviceList.append(service)
        serviceDict[serviceName] = service
    }
    
    static func getService(_ serviceName:String) -> ServiceProtocol?
    {
        return instance.serviceDict[serviceName]
    }
    
    static func getService<T:ServiceProtocol>(_ type:T.Type) -> T
    {
        return getService(T.ServiceName) as! T
    }
    
    fileprivate static func setServiceReady<T:ServiceProtocol>(_ service:T)
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
        debugLog("\(T.ServiceName) Ready!")
        instance.post(name: ServiceContainer.OnServiceReady, object: instance, userInfo: [ServiceContainerNotifyService:service])
        if isAllServiceReady
        {
            debugLog("All Services Ready!")
            instance.postNotificationNameWithMainAsync(ServiceContainer.OnAllServicesReady, object: instance,userInfo: nil)
        }
    }
    
    fileprivate static func setServiceNotReady<T:ServiceProtocol>(_ service:T)
    {
        instance.serviceReadyLock.lock()
        instance.serviceReady[T.ServiceName] = false
        instance.serviceReadyLock.unlock()
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
    
    static func isServiceReady(_ serviceName:String) -> Bool
    {
        if let isReady = instance.serviceReady[serviceName]
        {
            return isReady
        }
        return false
    }
    
    static func isServiceReady<T:ServiceProtocol>(_ service:T) -> Bool
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
    
    func setServiceNotReady() {
        ServiceContainer.setServiceReady(self)
    }
    
    var isServiceReady:Bool
    {
        return ServiceContainer.isServiceReady(self)
    }
}

//MARK: NSNotificationCenter Extension
extension NotificationCenter{
    func postNotificationNameWithMainAsync(_ aName: Notification.Name, object: AnyObject?, userInfo: [AnyHashable: Any]?){
        DispatchQueue.main.async { () -> Void in
            self.post(name: aName, object: object, userInfo: userInfo)
        }
    }
}
