//
//  ModelEntity.swift
//  Bahamut
//
//  Created by AlexChow on 15/8/8.
//  Copyright (c) 2015年 GStudio. All rights reserved.
//

import Foundation
import CoreData

class ModelEntity: NSManagedObject {

    @NSManaged var id: String
    @NSManaged var modelType: String
    @NSManaged var serializableValue: String

}
