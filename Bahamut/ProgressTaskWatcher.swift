//
//  FileFetcher.swift
//  Bahamut
//
//  Created by AlexChow on 15/9/8.
//  Copyright © 2015年 GStudio. All rights reserved.
//

import Foundation

class ProgressTaskWatcher
{
    static let sharedInstance:ProgressTaskWatcher = {
        return ProgressTaskWatcher()
        }()
    
    private var dict = [String:NSMutableSet]()

    class TaskRecord
    {
        var id:String!
        var delegate:ProgressTaskDelegate!
    }
    
    func addTaskObserver(taskIdentifier:String,delegate:ProgressTaskDelegate)
    {
        var list = dict[taskIdentifier]
        if list == nil
        {
            list = NSMutableSet()
            dict[taskIdentifier] = list
        }
        let record = TaskRecord()
        record.delegate = delegate
        record.id = taskIdentifier
        list?.addObject(record)
    }
    
    private func removeTaskObserver(taskIdentifier:String)
    {
        dict.removeValueForKey(taskIdentifier)
    }
    
    func setProgress(taskIdentifier:String,persent:Float)
    {
        if let list = dict[taskIdentifier]
        {
            list.forEach({ (record) -> () in
                if let r = record as? TaskRecord
                {
                    if let progress = r.delegate.taskProgress
                    {
                        progress(taskIdentifier, persent: persent)
                    }
                }
            })
        }
    }
    
    func missionCompleted(taskIdentifier:String,result:AnyObject!)
    {
        if let list = dict[taskIdentifier]
        {
            list.forEach({ (record) -> () in
                if let r = record as? TaskRecord
                {
                    r.delegate.taskCompleted(taskIdentifier, result: result)
                }
            })
        }
        self.removeTaskObserver(taskIdentifier)
    }
    
    func missionFailed(taskIdentifier:String,result:AnyObject!)
    {
        if let list = dict[taskIdentifier]
        {
            list.forEach({ (record) -> () in
                if let r = record as? TaskRecord
                {
                    if let taskFailed = r.delegate.taskFailed
                    {
                        taskFailed(taskIdentifier, result: result)
                    }
                }
            })
        }
        self.removeTaskObserver(taskIdentifier)
    }
}


@objc
protocol ProgressTaskDelegate
{
    optional func taskProgress(taskIdentifier:String,persent:Float)
    func taskCompleted(taskIdentifier:String,result:AnyObject!)
    optional func taskFailed(taskIdentifier:String,result:AnyObject!)
}