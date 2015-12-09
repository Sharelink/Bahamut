//
//  UpdateCoreDataConfig.swift
//  Bahamut
//
//  Created by AlexChow on 15/12/9.
//  Copyright © 2015年 GStudio. All rights reserved.
//

import Foundation

class NoUpdateCoreData : PersistentUpdateProtocol{
    func update(obj: AnyObject?) {
        let userId = obj as! String
        UpdateCoreDataHelper.setCoreDataVersion(userId)
    }
}

class UpdateCoreDataHelper
{
    static func getCoreDataVersion(userId:String) -> String?
    {
        if let version = NSUserDefaults.standardUserDefaults().objectForKey("\(userId)_core_data_version") as? String
        {
            return version
        }
        return nil
    }
    
    static func setCoreDataVersion(userId:String)
    {
        NSUserDefaults.standardUserDefaults().setObject(currentVersion, forKey: "\(userId)_core_data_version")
        NSLog("Set Core Data Version \(currentVersion)")
    }
    
    static func getUpdater(userId:String) -> PersistentUpdateProtocol
    {
        if let version = getCoreDataVersion(userId)
        {
            if let updater = config[version]
            {
                return updater
            }
            return NoUpdateCoreData()
        }else
        {
            return UpdateCoreData1()
        }
    }
    
    static let currentVersion = "2"
    static let config:[String:PersistentUpdateProtocol] =
    [
        "1":UpdateCoreData1()
    ]
}