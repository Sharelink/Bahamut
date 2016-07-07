//
//  iCloudDocumentManager.swift
//  iDiaries
//
//  Created by AlexChow on 15/12/8.
//  Copyright © 2015年 GStudio. All rights reserved.
//

import Foundation
import iCloudDocumentSync

//MARK: PersistentsManger extension
extension PersistentManager
{
    func useiCloudExtension(iCloudContainerIdentifier:String){
        self.useExtension(iCloudExtension()) { (ext) -> Void in
            iCloudExtension.defaultInstance = ext
            ext.iCloudManager.setupiCloudDocumentSyncWithUbiquityContainer(iCloudContainerIdentifier)
            ext.iCloudManager.verboseLogging = true
            ext.iCloudManager.verboseAvailabilityLogging = true
            ext.iCloudManager.checkCloudAvailability()
            ext.iCloudManager.checkCloudUbiquityContainer()
        }
    }
}

class iCloudExtension:NSObject,iCloudDocumentDelegate,iCloudDelegate,PersistentExtensionProtocol
{
    private(set) static var defaultInstance:iCloudExtension!
    private(set) var iCloudManager = iCloud.sharedCloud(){
        didSet{
            iCloud.sharedCloud().delegate = self
        }
    }
    func resetExtension(){

    }
    
    func destroyExtension() {
        
    }
    
    func releaseExtension() {
        iCloud.sharedCloud().delegate = nil
        iCloudManager = nil
        iCloudExtension.defaultInstance = nil
    }
    
    func storeImmediately() {
        
    }
    
    func iCloudDocumentErrorOccured(error: NSError!) {
        NSLog("iCloud", error.description)
    }
}