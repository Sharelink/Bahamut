//
//  BahamutTaskQueue.swift
//  Vessage
//
//  Created by AlexChow on 16/3/10.
//  Copyright © 2016年 Bahamut. All rights reserved.
//

import Foundation

public class BahamutTaskQueue:NSNotificationCenter{
    static let onTaskStepError = "onTaskStepError"
    static let onTaskProgress = "onTaskProgress"
    static let onTaskFinished = "onTaskFinished"
    static let onTaskCanceled = "onTaskCanceled"
    
    private var stepHandler = [String:BahamutTaskQueueStepHandler]()
    
    static var defaultInstance:BahamutTaskQueue = {
        return BahamutTaskQueue()
    }()
    
    weak var controller:UIViewController!{
        return UIApplication.currentShowingViewController
    }
    
    public func initQueue(userId:String){
        
    }
    
    public func releaseQueue() {
        releaseHandlers()
        
    }
    
    public func initHandlers(handlers:[String:BahamutTaskQueueStepHandler]){
        stepHandler.removeAll()
        handlers.forEach { (id,handler) in
            stepHandler.updateValue(handler, forKey: id)
        }
        stepHandler.values.forEach{$0.initHandler(self)}
    }
    
    private func releaseHandlers(){
        stepHandler.values.forEach{$0.releaseHandler()}
        stepHandler.removeAll()
    }
    
    private func getBahamutQueueTaskByTaskId(taskId:String) -> BahamutQueueTask?{
        return PersistentManager.sharedInstance.getModel(BahamutQueueTask.self, idValue: taskId)
    }
    
    func pushTask(queueTask:BahamutQueueTask) {
        queueTask.taskId = IdUtil.generateUniqueId()
        queueTask.currentStep = -1
        queueTask.saveModel()
        nextStep(queueTask)
    }
    
    func nextStep(task:BahamutQueueTask) {
        task.currentStep += 1
        task.saveModel()
        if task.isFinish() {
            finishTask(task)
        }else{
            startTask(task)
        }
    }
    
    private func finishTask(task:BahamutQueueTask){
        var userInfo = [NSObject:AnyObject]()
        userInfo.updateValue(task, forKey: kBahamutQueueTaskValue)
        PersistentManager.sharedInstance.removeModel(task)
        self.postNotificationNameWithMainAsync(BahamutTaskQueue.onTaskFinished, object: self, userInfo: userInfo)
        self.notifyTaskStepProgress(task, stepIndex: task.currentStep, stepProgress: 0)
        #if DEBUG
            print("BahamutQueueTaskId:\(task.taskId) -> Finished")
        #endif
    }
    
    func notifyTaskStepProgress(task:BahamutQueueTask,stepIndex:Int,stepProgress:Float) {
        
        let totalSteps = Float(task.steps.count)
        let stepProgressInTask = 1 / totalSteps * stepProgress
        let finishedProgress = Float(stepIndex) / totalSteps + stepProgressInTask
        
        var userInfo = [NSObject:AnyObject]()
        userInfo.updateValue(task, forKey: kBahamutQueueTaskValue)
        userInfo.updateValue(finishedProgress, forKey: kBahamutQueueTaskProgressValue)
        self.postNotificationNameWithMainAsync(BahamutTaskQueue.onTaskProgress, object: self, userInfo: userInfo)
        #if DEBUG
            print("BahamutQueueTaskId:\(task.taskId) -> Progress:\(finishedProgress * 100)%")
        #endif
    }
    
    func doTaskStepError(task:BahamutQueueTask,message:String?) {
        var userInfo = [NSObject:AnyObject]()
        userInfo.updateValue(task, forKey: kBahamutQueueTaskValue)
        if let msg = message{
            userInfo.updateValue(msg, forKey: kBahamutQueueTaskMessageValue)
        }
        self.postNotificationNameWithMainAsync(BahamutTaskQueue.onTaskStepError, object: self, userInfo: userInfo)
    }
    
    func cancelTask(task:BahamutQueueTask,message:String?) {
        var userInfo = [NSObject:AnyObject]()
        userInfo.updateValue(task, forKey: kBahamutQueueTaskValue)
        if let msg = message{
            userInfo.updateValue(msg, forKey: kBahamutQueueTaskMessageValue)
        }
        PersistentManager.sharedInstance.removeModel(task)
        self.postNotificationNameWithMainAsync(BahamutTaskQueue.onTaskCanceled, object: self, userInfo: userInfo)
        #if DEBUG
            print("BahamutQueueTaskId:\(task.taskId) -> Canceled")
        #endif
    }
    
    func startTask(task:BahamutQueueTask)  {
        notifyTaskStepProgress(task, stepIndex: task.currentStep, stepProgress: 0)
        if let step = task.getCurrentStep(){
            if let handler = self.stepHandler[step]{
                #if DEBUG
                    print("BahamutQueueTaskId:\(task.taskId) -> Do Work:\(step)")
                #endif
                handler.doTask(self, task: task)
            }
        }
    }
}