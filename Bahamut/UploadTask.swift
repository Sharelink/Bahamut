//
//  UploadTask.swift
//  Bahamut
//
//  Created by AlexChow on 15/8/8.
//  Copyright (c) 2015年 GStudio. All rights reserved.
//

import Foundation
import CoreData

class UploadTask: NSManagedObject {

    @NSManaged var accessKey: String
    @NSManaged var fileId: String
    @NSManaged var fileServerUrl: String
    @NSManaged var fileType: NSNumber
    @NSManaged var localPath: String
    @NSManaged var status: NSNumber
    @NSManaged var taskId: String

}