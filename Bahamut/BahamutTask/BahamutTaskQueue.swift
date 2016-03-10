//
//  BahamutTaskQueue.swift
//  Vessage
//
//  Created by AlexChow on 16/3/10.
//  Copyright © 2016年 Bahamut. All rights reserved.
//

import Foundation

enum BahamutTaskStepStatus:String
{
    case Ready = "ready"
    case Working = "working"
    case Finished = "finished"
    case Failed = "failed"
}

enum BahamutTaskStatus:String{
    case Ready = "ready"
    case Working = "working"
    case Paused = "paused"
    case Finished = "finished"
    case Failed = "failed"
    case Canceled = "cancel"
}

class BahamutTaskStepModel: BahamutObject{
    var stepName:String!
    var stepStatus:String!
}

class BahamutTaskModel: BahamutObject {
    var taskId:String!
    var queueIdentifier:String!
    var isSequence:Bool = true
    var isAutoStart:Bool = true
    var taskStatus:String!
    var retryTimes:NSNumber = 0
    var time:NSNumber = 0
    var stepModels:[BahamutTaskStepModel]!
    var taskUserInfo:String!
}

class BahamutTask {
    var taskModel:BahamutTaskModel!
    var steps:[String:BahamutTaskStep]!
    
    private func finishedStep(stepName:String){
        if let index = (taskModel.stepModels.indexOf{$0.stepName == stepName}){
            taskModel.stepModels[index].stepStatus = BahamutTaskStepStatus.Finished.rawValue
            taskModel.saveModel()
            
            if taskModel.taskStatus != BahamutTaskStatus.Working.rawValue{
                return
            }
            
            if isAllStepFinished{
                taskModel.taskStatus = BahamutTaskStatus.Finished.rawValue
                return
            }
            
            if taskModel.isSequence && taskModel.stepModels.count > index + 1{
                let stepModel = taskModel.stepModels[index + 1]
                if let step = steps[stepModel.stepName]{
                    stepModel.stepStatus = BahamutTaskStepStatus.Working.rawValue
                    step.worker.taskStepStart(self, step: step, taskModel: taskModel)
                    taskModel.saveModel()
                }
            }
        }
    }
    
    private var isAllStepFinished:Bool{
        var result = true
        for i in 0..<taskModel.stepModels.count{
            if BahamutTaskStepStatus.Finished.rawValue != taskModel.stepModels[i].stepStatus{
                result = false
                break
            }
        }
        return result
    }
    
    private func failedStep(stepName:String){
        if let index = (taskModel.stepModels.indexOf{$0.stepName == stepName}){
            taskModel.stepModels[index].stepStatus = BahamutTaskStepStatus.Failed.rawValue
            taskModel.saveModel()
        }
    }
    
    private func startTask(){
        if taskModel.taskStatus == BahamutTaskStatus.Ready.rawValue{
            let firstStep = taskModel.stepModels.first!
            if let step = steps[firstStep.stepName]{
                taskModel.taskStatus = BahamutTaskStatus.Working.rawValue
                taskModel.saveModel()
                step.worker.taskStepStart(self, step: step, taskModel: taskModel)
            }
        }
    }
    
    private func cancelTask(){
        taskModel.taskStatus = BahamutTaskStatus.Canceled.rawValue
        taskModel.saveModel()
    }
    
    private func pauseTask(){
        if taskModel.taskStatus == BahamutTaskStatus.Working.rawValue{
            taskModel.taskStatus = BahamutTaskStatus.Paused.rawValue
            taskModel.saveModel()
        }
    }
    
    private func resumeTask(){
        if taskModel.taskStatus == BahamutTaskStatus.Paused.rawValue{
            taskModel.taskStatus = BahamutTaskStatus.Working.rawValue
            taskModel.saveModel()
        }
    }
    
    private func finishTask(){
        if taskModel.taskStatus == BahamutTaskStatus.Working.rawValue{
            taskModel.taskStatus = BahamutTaskStatus.Finished.rawValue
            taskModel.saveModel()
            BahamutTaskQueue.getQueue(taskModel.queueIdentifier).nextTask()
        }
    }
}

protocol BahamutTaskStepWorker
{
    func taskStepStart(task:BahamutTask, step:BahamutTaskStep, taskModel:BahamutTaskModel)
    
}

class BahamutTaskStep {
    var queueIdentifier:String!
    var taskId:String!
    var stepName:String!
    var worker:BahamutTaskStepWorker!
    
    func finishedStep(result:AnyObject?){
        if let task = BahamutTaskQueue.getQueue(queueIdentifier).getTask(taskId){
            task.finishedStep(stepName)
        }
    }
    
    func failStep(result:AnyObject?){
        if let task = BahamutTaskQueue.getQueue(queueIdentifier).getTask(taskId){
            task.failedStep(stepName)
        }
    }
}

protocol BahamutTaskQueueTaskStepProvider{
    func getStep(stepName:String) -> BahamutTaskStepWorker
}

class BahamutTaskQueue {
    private var identifier:String!
    private static var queues = [String:BahamutTaskQueue]()
    private static var stepProviders = [String:BahamutTaskQueueTaskStepProvider]()
    
    static func registBahamutTaskStepProvider(queueIdentifier:String, provider:BahamutTaskQueueTaskStepProvider){
        stepProviders[queueIdentifier] = provider
    }
    
    static func getQueue(identifier:String)->BahamutTaskQueue{
        if let q = queues[identifier]{
            return q
        }else{
            return restoreQueue(identifier)
        }
    }
    
    private static func restoreQueue(identifier:String) -> BahamutTaskQueue{
        let q = BahamutTaskQueue()
        PersistentManager.sharedInstance.getAllModelFromCache(BahamutTaskModel).forEach { (model) -> () in
            if model.queueIdentifier == identifier{
                q.taskqueue.append(generateTask(model))
            }
        }
        q.identifier = identifier
        q.taskqueue.sortInPlace { (a, b) -> Bool in
            return a.taskModel.time.doubleValue < b.taskModel.time.doubleValue
        }
        queues[identifier] = q
        return q
    }
    
    private static func generateTask(taskModel:BahamutTaskModel) -> BahamutTask{
        let task = BahamutTask()
        task.taskModel = taskModel
        task.steps = [String:BahamutTaskStep]()
        taskModel.stepModels.forEach { (sm) -> () in
            let step = generateTaskStep(sm)
            step.queueIdentifier = taskModel.queueIdentifier
            step.taskId = taskModel.taskId
            step.worker = BahamutTaskQueue.stepProviders[taskModel.queueIdentifier]!.getStep(step.stepName)
            task.steps[sm.stepName] = step
        }
        return task
    }
    
    private static func generateTaskStep(stepModel:BahamutTaskStepModel) -> BahamutTaskStep{
        let step = BahamutTaskStep()
        step.stepName = stepModel.stepName
        return step
    }
    
    private var taskqueue = [BahamutTask]()
    
    func pushTask(userInfo:String,step:[String]) -> BahamutTaskModel{
        let taskModel = BahamutTaskModel()
        taskModel.queueIdentifier = identifier
        taskModel.taskId = IdUtil.generateUniqueId()
        taskModel.taskStatus = BahamutTaskStatus.Ready.rawValue
        taskModel.taskUserInfo = userInfo
        taskModel.time = NSDate().timeIntervalSince1970
        taskModel.stepModels = [BahamutTaskStepModel]()
        step.forEach { (sn) -> () in
            let sm = BahamutTaskStepModel()
            sm.stepName = sn
            sm.stepStatus = BahamutTaskStepStatus.Ready.rawValue
            taskModel.stepModels.append(sm)
        }
        let task = BahamutTaskQueue.generateTask(taskModel)
        taskqueue.append(task)
        if taskqueue.count == 1{
            task.startTask()
        }
        return taskModel
    }
    
    func nextTask(){
        for i in 0..<taskqueue.count{
            if taskqueue[i].taskModel.taskStatus == BahamutTaskStatus.Ready.rawValue{
                taskqueue[i].startTask()
            }
        }
    }
    
    func cancelTask(taskId:String){
        if let task = getTask(taskId){
            task.cancelTask()
        }
    }
    
    private func getTask(taskId:String) -> BahamutTask?{
        for i in 0..<taskqueue.count{
            if taskqueue[i].taskModel.taskId == taskId{
                return taskqueue[i]
            }
        }
        return nil
    }
}