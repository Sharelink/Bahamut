//
//  FileRelationshipEntity.swift
//  Bahamut
//
//  Created by AlexChow on 15/8/8.
//  Copyright (c) 2015年 GStudio. All rights reserved.
//

import Foundation
import CoreData

class FileRelationshipEntity: NSManagedObject {

    @NSManaged var fileData: NSData
    @NSManaged var fileId: String
    @NSManaged var filePath: String
    @NSManaged var fileServerUrl: String

}
