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
    optional func taskProgress(taskIdentifier:String,persent:Float)
    func taskCompleted(taskIdentifier:String,result:AnyObject!)
    optional func taskFailed(taskIdentifier:String,result:AnyObject!)
}

enum TaskState:Int
{
    case Created = 0
    case Working = 1
    case Completed = 2
    case Failed = 3
    case Cancel = 4
}

class TaskRecord
{
    var id:String!
    var progress:Float = 0
    var result:AnyObject!
    var state = TaskState.Created
    var subTaskOfQueueTask:ProgressQueueTask!
    weak var delegate:ProgressTaskDelegate!
}

//MARK: TO DO: finish this
class ProgressQueueTask:NSObject,ProgressTaskDelegate
{
    let queueTaskId = IdUtil.generateUniqueId()
    private(set) var subTasks = [String:TaskRecord]()
    func addSubTask(subTask:TaskRecord)
    {
        subTasks.updateValue(subTask, forKey: subTask.id)
        subTask.subTaskOfQueueTask = self
    }
    
    func taskCompleted(taskIdentifier: String, result: AnyObject!) {
        var allCompleted = true
        subTasks.forEach({ (task) -> () in
            let taskRecord = task.1
            if taskRecord.state == .Failed
            {
                allCompleted = false
            }
        })
        if allCompleted
        {
            ProgressTaskWatcher.sharedInstance.missionCompleted(self.queueTaskId, result: nil)
        }
    }
    
    func taskFailed(taskIdentifier: String, result: AnyObject!) {
        
    }
    
    func taskProgress(taskIdentifier: String, persent: Float) {
        
    }
}

class ProgressTaskWatcher
{
    static let sharedInstance:ProgressTaskWatcher = {
        return ProgressTaskWatcher()
    }()
    
    private var dict = [String:NSMutableSet]()
    
    
    func addTaskObserver(taskIdentifier:String,delegate:ProgressTaskDelegate) -> TaskRecord
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
        return record
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
                        r.state = .Working
                        r.progress = persent
                        progress(taskIdentifier, persent: persent)
                    }
                    if let queueProgress = r.subTaskOfQueueTask?.taskProgress
                    {
                        queueProgress(taskIdentifier, persent: persent)
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
                    r.state = .Completed
                    r.result = result
                    r.progress = 0
                    r.delegate.taskCompleted(taskIdentifier, result: result)
                }
                if let taskCompleted = (record as? TaskRecord)?.subTaskOfQueueTask?.taskCompleted
                {
                    taskCompleted(taskIdentifier, result: result)
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
                        r.state = .Failed
                        r.result = result
                        r.progress = 0
                        taskFailed(taskIdentifier, result: result)
                    }
                    if let taskFailed = r.subTaskOfQueueTask?.taskFailed
                    {
                        taskFailed(taskIdentifier, result: result)
                    }
                }
            })
        }
        self.removeTaskObserver(taskIdentifier)
    }
}
