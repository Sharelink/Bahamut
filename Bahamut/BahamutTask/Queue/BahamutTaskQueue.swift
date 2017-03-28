//
//  BahamutTaskQueue.swift
//  Vessage
//
//  Created by AlexChow on 16/3/10.
//  Copyright © 2016年 Bahamut. All rights reserved.
//

import Foundation

open class BahamutTaskQueue:NotificationCenter{
    static let onTaskStepError = "onTaskStepError".asNotificationName()
    static let onTaskProgress = "onTaskProgress".asNotificationName()
    static let onTaskFinished = "onTaskFinished".asNotificationName()
    static let onTaskCanceled = "onTaskCanceled".asNotificationName()
    
    fileprivate var stepHandler = [String:BahamutTaskQueueStepHandler]()
    
    static var defaultInstance:BahamutTaskQueue = {
        return BahamutTaskQueue()
    }()
    
    weak var controller:UIViewController!{
        return UIApplication.currentShowingViewController
    }
    
    open func initQueue(_ userId:String){
        
    }
    
    open func releaseQueue() {
        releaseHandlers()
        
    }
    
    open func useHandlers(_ handlers:[String:BahamutTaskQueueStepHandler]){
        handlers.forEach { (id,handler) in
            self.useHandler(id,handler: handler)
        }
    }
    
    open func useHandler(_ key:String,handler:BahamutTaskQueueStepHandler){
        stepHandler.updateValue(handler, forKey: key)
        handler.initHandler(self)
    }
    
    fileprivate func releaseHandlers(){
        stepHandler.values.forEach{$0.releaseHandler()}
        stepHandler.removeAll()
    }
    
    fileprivate func getBahamutQueueTaskByTaskId(_ taskId:String) -> BahamutQueueTask?{
        return PersistentManager.sharedInstance.getModel(BahamutQueueTask.self, idValue: taskId)
    }
    
    func pushTask(_ queueTask:BahamutQueueTask) {
        queueTask.taskId = IdUtil.generateUniqueId()
        queueTask.currentStep = -1
        nextStep(queueTask)
    }
    
    func nextStep(_ task:BahamutQueueTask) {
        task.currentStep += 1
        if task.isFinish() {
            finishTask(task)
        }else{
            startTask(task)
        }
    }
    
    fileprivate func finishTask(_ task:BahamutQueueTask){
        var userInfo = [AnyHashable: Any]()
        userInfo.updateValue(task, forKey: kBahamutQueueTaskValue)
        PersistentManager.sharedInstance.removeModel(task)
        self.postNotificationNameWithMainAsync(BahamutTaskQueue.onTaskFinished, object: self, userInfo: userInfo)
        self.notifyTaskStepProgress(task, stepIndex: task.currentStep, stepProgress: 0)
        #if DEBUG
            print("BahamutQueueTaskId:\(task.taskId!) -> Finished")
        #endif
    }
    
    func notifyTaskStepProgress(_ task:BahamutQueueTask,stepIndex:Int,stepProgress:Float) {
        
        let totalSteps = Float(task.steps.count)
        let stepProgressInTask = 1 / totalSteps * stepProgress
        let finishedProgress = Float(stepIndex) / totalSteps + stepProgressInTask
        
        var userInfo = [AnyHashable: Any]()
        userInfo.updateValue(task, forKey: kBahamutQueueTaskValue)
        userInfo.updateValue(finishedProgress, forKey: kBahamutQueueTaskProgressValue)
        self.postNotificationNameWithMainAsync(BahamutTaskQueue.onTaskProgress, object: self, userInfo: userInfo)
        #if DEBUG
            print("BahamutQueueTaskId:\(task.taskId!) -> Progress:\(finishedProgress * 100)%")
        #endif
    }
    
    func doTaskStepError(_ task:BahamutQueueTask,message:String?) {
        var userInfo = [AnyHashable: Any]()
        userInfo.updateValue(task, forKey: kBahamutQueueTaskValue)
        if let msg = message{
            userInfo.updateValue(msg, forKey: kBahamutQueueTaskMessageValue)
        }
        self.postNotificationNameWithMainAsync(BahamutTaskQueue.onTaskStepError, object: self, userInfo: userInfo)
    }
    
    func cancelTask(_ task:BahamutQueueTask,message:String?) {
        var userInfo = [AnyHashable: Any]()
        userInfo.updateValue(task, forKey: kBahamutQueueTaskValue)
        if let msg = message{
            userInfo.updateValue(msg, forKey: kBahamutQueueTaskMessageValue)
        }
        PersistentManager.sharedInstance.removeModel(task)
        self.postNotificationNameWithMainAsync(BahamutTaskQueue.onTaskCanceled, object: self, userInfo: userInfo)
        #if DEBUG
            print("BahamutQueueTaskId:\(task.taskId!) -> Canceled")
        #endif
    }
    
    func startTask(_ task:BahamutQueueTask)  {
        notifyTaskStepProgress(task, stepIndex: task.currentStep, stepProgress: 0)
        if let step = task.getCurrentStep(){
            if let handler = self.stepHandler[step]{
                #if DEBUG
                    print("BahamutQueueTaskId:\(task.taskId!) -> Do Work:\(step)")
                #endif
                handler.doTask(self, task: task)
            }
        }
    }
}
