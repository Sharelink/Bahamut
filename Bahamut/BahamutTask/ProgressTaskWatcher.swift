//
//  FileFetcher.swift
//  Bahamut
//
//  Created by AlexChow on 15/9/8.
//  Copyright © 2015年 GStudio. All rights reserved.
//

import Foundation

@objc
protocol ProgressTaskDelegate
{
    @objc optional func taskProgress(_ taskIdentifier:String,persent:Float)
    func taskCompleted(_ taskIdentifier:String,result:Any!)
    @objc optional func taskFailed(_ taskIdentifier:String,result:Any!)
}

enum TaskState:Int
{
    case created = 0
    case working = 1
    case completed = 2
    case failed = 3
    case cancel = 4
}

class TaskRecord
{
    var id:String!
    var progress:Float = 0
    var result:Any!
    var state = TaskState.created
    var subTaskOfQueueTask:ProgressQueueTask!
    var delegate:ProgressTaskDelegate!
}

//MARK:ProgressQueueTask
class ProgressQueueTask:NSObject,ProgressTaskDelegate
{
    let queueTaskId = IdUtil.generateUniqueId()
    fileprivate(set) var subTasks = [String:TaskRecord]()
    func addSubTask(_ subTask:TaskRecord)
    {
        subTasks.updateValue(subTask, forKey: subTask.id)
        subTask.subTaskOfQueueTask = self
    }
    
    func taskCompleted(_ taskIdentifier: String, result: Any!) {
        var allCompleted = true
        subTasks.forEach({ (task) -> () in
            let taskRecord = task.1
            if taskRecord.state == .failed
            {
                allCompleted = false
            }
        })
        if allCompleted
        {
            ProgressTaskWatcher.sharedInstance.missionCompleted(self.queueTaskId, result: nil)
        }
    }
    
    func taskFailed(_ taskIdentifier: String, result: Any!) {
        
    }
    
    func taskProgress(_ taskIdentifier: String, persent: Float) {
        
    }
}

class ProgressTaskWatcher
{
    static let sharedInstance:ProgressTaskWatcher = {
        return ProgressTaskWatcher()
    }()
    
    fileprivate var dict = [String:NSMutableSet]()
    
    @discardableResult
    func addTaskObserver(_ taskIdentifier:String,delegate:ProgressTaskDelegate) -> TaskRecord
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
        list?.add(record)
        return record
    }
    
    fileprivate func removeTaskObserver(_ taskIdentifier:String)
    {
        if let list = dict.removeValue(forKey: taskIdentifier){
            list.forEach({ a in
                if let record = a as? TaskRecord{
                    record.delegate = nil
                }
            })
        }
    }
    
    func setProgress(_ taskIdentifier:String,persent:Float)
    {
        if let list = dict[taskIdentifier]
        {
            list.forEach({ (record) -> () in
                if let r = record as? TaskRecord
                {
                    if let progress = r.delegate.taskProgress
                    {
                        r.state = .working
                        r.progress = persent
                        progress(taskIdentifier, persent)
                    }
                    if let queueProgress = r.subTaskOfQueueTask?.taskProgress
                    {
                        queueProgress(taskIdentifier, persent)
                    }
                }
            })
        }
    }
    
    func missionCompleted(_ taskIdentifier:String,result:Any!)
    {
        if let list = dict[taskIdentifier]
        {
            list.forEach({ (record) -> () in
                if let r = record as? TaskRecord
                {
                    r.state = .completed
                    r.result = result
                    r.progress = 0
                    r.delegate.taskCompleted(taskIdentifier, result: result)
                }
                if let taskCompleted = (record as? TaskRecord)?.subTaskOfQueueTask?.taskCompleted
                {
                    taskCompleted(taskIdentifier, result)
                }
            })
        }
        self.removeTaskObserver(taskIdentifier)
    }
    
    func missionFailed(_ taskIdentifier:String,result:Any!)
    {
        if let list = dict[taskIdentifier]
        {
            list.forEach({ (record) -> () in
                if let r = record as? TaskRecord
                {
                    if let taskFailed = r.delegate.taskFailed
                    {
                        r.state = .failed
                        r.result = result
                        r.progress = 0
                        taskFailed(taskIdentifier, result)
                    }
                    if let taskFailed = r.subTaskOfQueueTask?.taskFailed
                    {
                        taskFailed(taskIdentifier, result)
                    }
                }
            })
        }
        self.removeTaskObserver(taskIdentifier)
    }
}
