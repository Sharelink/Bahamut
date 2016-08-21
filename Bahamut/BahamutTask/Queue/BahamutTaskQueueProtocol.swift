//
//  BahamutTaskHandler.swift
//  Vessage
//
//  Created by AlexChow on 16/8/21.
//  Copyright © 2016年 Bahamut. All rights reserved.
//

import Foundation

public protocol BahamutTaskQueueStepHandler{
    func initHandler(queue:BahamutTaskQueue)
    func releaseHandler()
    func doTask(queue:BahamutTaskQueue,task:BahamutQueueTask)
}

public class BahamutQueueTask:BahamutObject{
    override public func getObjectUniqueIdName() -> String {
        return "taskId"
    }
    
    var taskId:String!
    var steps:[String]!
    var currentStep = 0
    
    func getCurrentStep() -> String? {
        return steps?[currentStep]
    }
    
    func isFinish() -> Bool {
        return currentStep == steps.count
    }
}

let kBahamutQueueTaskValue = "TaskValue"
let kBahamutQueueTaskMessageValue = "TaskMessageValue"
let kBahamutQueueTaskProgressValue = "TaskMessageValue"