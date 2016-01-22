//
//  SRCModelCommon.swift
//  Bahamut
//
//  Created by AlexChow on 16/1/21.
//  Copyright © 2016年 GStudio. All rights reserved.
//

import Foundation
import EVReflection

//MARK: SRCPlugin
class SRCPlugin
{
    var srcId:String!
    var srcName:String!
    var controllerTitle:String!
    var srcCellId:String!
    var shareType:String!
    var srcHeaderTitle:String!
    var srcHeaderIcon:UIImage!
}

//MARK: SRCPluginInfoModel
class SRCPluginInfoModelBase:EVObject
{
    var version:String!
    
    func generateSRCPlugin() -> SRCPlugin?
    {
        return nil
    }
    
    func isInlegal() -> Bool
    {
        return false
    }
}

let SRCPluginInfoVersionRegexMatcher = RegexMatcher("\"version\"\\s*:\\s*\"[0-9.]+\"")
let SRCPluginInfoVersionValueRegexMatcher = RegexMatcher("[0-9.]+")

func generateSRCPluginInfoModel(json:String) -> SRCPluginInfoModelBase?
{
    if let versionInfo = SRCPluginInfoVersionRegexMatcher.matchFirstString(json)
    {
        if let version = SRCPluginInfoVersionValueRegexMatcher.matchFirstString(versionInfo)
        {
            if let template = SRCPluginInfoModelTemplateMap[version]
            {
                return newSRCPluginInfoJsonModel(template as! SRCPluginInfoModelBase.Type, json: json)
            }
        }
    }
    return nil
}

func newSRCPluginInfoJsonModel<T:SRCPluginInfoModelBase>(modelTemplate:T.Type,json:String) -> T?
{
    return modelTemplate.init(json: json)
}

//MARK: SRCPluginInfoModel Config Map
let SRCPluginInfoModelTemplateMap:[String:AnyObject] =
[
    "1.0":SRCPluginInfoModelV1.self
]

//MARK: SRCPluginInfoModel

class SRCPluginInfoModelV1:SRCPluginInfoModelBase
{
    var srcId:String!
    var srcName:String!
    var srcTitle:String!
    var srcIcon:String!
    
    var previewPage:String!
    var detailPage:String!
    
    var editMiniPage:String!
    var editMaxPage:String!
    override func generateSRCPlugin() -> SRCPlugin? {
        let p = SRCPlugin()
        p.srcId = self.srcId
        p.controllerTitle = self.srcTitle
        p.srcHeaderTitle = self.srcTitle
        p.srcHeaderIcon = ImageAssetsConstants.defaultCustomSRCIcon
        p.srcName = self.srcName
        return p
    }
    
    override func isInlegal() -> Bool {
        return String.isNullOrWhiteSpace(self.srcId) ||
        String.isNullOrWhiteSpace(self.srcName) ||
        String.isNullOrWhiteSpace(self.srcTitle)
    }
}


