//
//  SRCService.swift
//  Bahamut
//
//  Created by AlexChow on 16/1/19.
//  Copyright © 2016年 GStudio. All rights reserved.
//

import Foundation
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
    @objc static var ServiceName:String{return "src service"}
    private(set) var defaultSRCPlugins = [SRCPlugin](SharelinkSRCPlugins)
    private(set) var allSRCPlugins = [SRCPlugin]()
    private var srcPluginsMap = [String:SRCPlugin]()
    
    @objc func userLoginInit(userId:String)
    {
        self.reloadSRC()
        self.setServiceReady()
    }
    
    func userLogout(userId: String) {
    }
    
    private func reloadSRC()
    {
        allSRCPlugins.removeAll()
        loadSharelinkPlugins()
        loadCustomPlugins()
        mappingPlugins()
    }
    
    private func loadSharelinkPlugins()
    {
        allSRCPlugins.appendContentsOf(SharelinkSRCPlugins)
    }
    
    private func loadCustomPlugins()
    {
        
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