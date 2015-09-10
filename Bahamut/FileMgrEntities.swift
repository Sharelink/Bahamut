//
//  FileInfoEntity.swift
//  Bahamut
//
//  Created by AlexChow on 15/8/8.
//  Copyright (c) 2015年 GStudio. All rights reserved.
//

import Foundation
import CoreData

class FileInfoEntity: NSManagedObject {
    @NSManaged var fileId: String
    @NSManaged var localPath: String
    @NSManaged var fileType: NSNumber
}


class UploadTask: NSManagedObject {
    @NSManaged var fileId: String
    @NSManaged var fileServerUrl: String
    @NSManaged var localPath: String
    @NSManaged var status: NSNumber
    
}
