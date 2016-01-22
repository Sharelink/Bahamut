//
//  SRCService.swift
//  Bahamut
//
//  Created by AlexChow on 16/1/19.
//  Copyright © 2016年 GStudio. All rights reserved.
//

import Foundation

//MARK: Sharelink SRCPlugin
let SharelinkSRCHeaderIconNamePrefix = "new_share_header_icon_"
let SharelinkSRCPluginConfig =
[
    (shareType:ShareThingType.shareFilm,cellId:NewShareFilmCell.reuseableId,name:"SHARE_HEADER_TITLE_VIDEO",controllerTitle:"SHARE_VIEW_TITLE_NEW_FILM"),
    (shareType:ShareThingType.shareText,cellId:NewShareTextCell.reuseableId,name:"SHARE_HEADER_TITLE_TEXT",controllerTitle:"SHARE_VIEW_TITLE_NEW_TEXT"),
    (shareType:ShareThingType.shareImage,cellId:NewShareImageCell.reuseableId,name:"SHARE_HEADER_TITLE_IMAGE",controllerTitle:"SHARE_VIEW_TITLE_NEW_IMAGE"),
    (shareType:ShareThingType.shareUrl,cellId:NewShareUrlCell.reuseableId,name:"SHARE_HEADER_TITLE_LINK",controllerTitle:"SHARE_VIEW_TITLE_NEW_URL")
]

let SharelinkSystemSRCId = "SharelinkDefault"

let SharelinkSRCPlugins:[SRCPlugin] = {
    var result = [SRCPlugin]()
    for config in SharelinkSRCPluginConfig
    {
        let plugin = SRCPlugin()
        plugin.srcId = "\(config.shareType.rawValue):\(SharelinkSystemSRCId)"
        plugin.srcName = config.name.localizedString
        plugin.controllerTitle = config.controllerTitle.localizedString
        plugin.srcCellId = config.cellId
        plugin.shareType = config.shareType.rawValue
        plugin.srcHeaderTitle = config.name.localizedString
        plugin.srcHeaderIcon = UIImage(named:"\(SharelinkSRCHeaderIconNamePrefix)\(config.shareType.getShareTypeName()!)")
        result.append(plugin)
    }
    return result
}()

//MARK: SRCService
class SRCService: NSNotificationCenter,ServiceProtocol
{
    @objc static var ServiceName:String{return "SRC Service"}
    static let allSRCPluginsReloaded = "allSRCPluginsReloaded"
    static let allSRCPluginsLoading = "allSRCPluginsLoading"
    private(set) var defaultSRCPlugins = [SRCPlugin](SharelinkSRCPlugins)
    private(set) var allSRCPlugins = [SRCPlugin]()
    private var userSRCPluginDir:NSURL!
    private var srcPluginsMap = [String:SRCPlugin]()
    
    @objc func userLoginInit(userId:String)
    {
        self.initSRCPluginDir(userId)
        self.setServiceReady()
    }
    
    func userLogout(userId: String) {
    }
    
    private func initSRCPluginDir(userId:String)
    {
        self.userSRCPluginDir = PersistentManager.sharedInstance.rootUrl.URLByAppendingPathComponent("SRCPlugin/\(userId)", isDirectory: true)
        PersistentManager.sharedInstance.createDir(userSRCPluginDir)
        copySRCTestFolder()
    }
    
    private func copySRCTestFolder()
    {
        //let dir = "SRCPluginTemplate"
        let url = Sharelink.mainBundle.URLForResource("SRCPluginTemplate", withExtension: nil)!
        do
        {
            try NSFileManager.defaultManager().copyItemAtURL(url, toURL: self.userSRCPluginDir.URLByAppendingPathComponent(IdUtil.generateUniqueId()))
        }catch let err as NSError
        {
            print(err.description)
        }
    }
    
    func reloadSRC()
    {
        self.postNotificationName(SRCService.allSRCPluginsLoading, object: nil)
        dispatch_async(dispatch_get_main_queue()) { () -> Void in
            self.allSRCPlugins.removeAll()
            self.loadSharelinkPlugins()
            self.loadCustomPlugins()
            self.mappingPlugins()
            self.postNotificationName(SRCService.allSRCPluginsReloaded, object: nil)
        }
    }
    
    private func loadSharelinkPlugins()
    {
        allSRCPlugins.appendContentsOf(SharelinkSRCPlugins)
    }
    
    private func loadCustomPlugins()
    {
        let fileManager = NSFileManager.defaultManager()
        self.userSRCPluginDir.pathComponents
        do
        {
            
            let files = try fileManager.contentsOfDirectoryAtURL(self.userSRCPluginDir, includingPropertiesForKeys: nil, options: NSDirectoryEnumerationOptions.SkipsHiddenFiles)
            files.forEach { (url) -> () in
                let pluginJsonUrl = url.URLByAppendingPathComponent("info.json")
                if PersistentFileHelper.isDirectory(url) && PersistentFileHelper.fileExists(pluginJsonUrl)
                {
                    if let pluginJson = PersistentFileHelper.readTextFile(pluginJsonUrl)
                    {
                        if let pluginInfo = generateSRCPluginInfoModel(pluginJson)
                        {
                            if pluginInfo.isInlegal() == false
                            {
                                if let plugin = pluginInfo.generateSRCPlugin()
                                {
                                    plugin.shareType = ShareThingType.shareCSRC.getCSRCShareType(plugin.srcId)
                                    plugin.srcCellId = NewCustomSRCCell.reuseableId
                                    self.allSRCPlugins.append(plugin)
                                }
                            }
                            
                        }
                    }
                }
            }
        }catch let err as NSError{
            NSLog("Error To Load Custom SRCPlugins %@", err.description)
        }
        
    }
    
    private func mappingPlugins()
    {
        srcPluginsMap.removeAll()
        allSRCPlugins.forEach { (p) -> () in
            if p.srcId == SharelinkSystemSRCId
            {
                srcPluginsMap[p.srcId] = p
            }else
            {
                srcPluginsMap["\(p.shareType):\(p.srcId)"] = p
            }
        }
    }
    
    func getSRCPlugin(shareType:String) -> SRCPlugin!
    {
        return srcPluginsMap[shareType]
    }
}