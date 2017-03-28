//
//  BahamutTaskHandler.swift
//  Vessage
//
//  Created by AlexChow on 16/8/21.
//  Copyright © 2016年 Bahamut. All rights reserved.
//

import Foundation

public protocol BahamutTaskQueueStepHandler{
    func initHandler(_ queue:BahamutTaskQueue)
    func releaseHandler()
    func doTask(_ queue:BahamutTaskQueue,task:BahamutQueueTask)
}

open class BahamutQueueTask:BahamutObject{
    override open func getObjectUniqueIdName() -> String {
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
