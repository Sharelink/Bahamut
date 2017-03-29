//
//  BahamutAPIClient.swift
//  Vessage
//
//  Created by Alex Chow on 2016/12/27.
//  Copyright © 2016年 Bahamut. All rights reserved.
//

import Foundation
private let BahamutRFClientType = "BahamutRFAPIClient"

extension BahamutRFKit{
    var appApiServer:String!{
        get{
            return userInfos["appApiServer"] as? String
        }
        set{
            userInfos["appApiServer"] = newValue
        }
    }
    
    @discardableResult
    func reuseApiServer(_ userId:String, token:String,appApiServer:String) -> ClientProtocal
    {
        self.appApiServer = appApiServer
        let client = BahamutRFClient(apiServer:self.appApiServer,userId:userId,token:token)
        return useClient(client, clientKey: BahamutRFClientType)
    }
    
    func getBahamutClient() -> ClientProtocal
    {
        if let client =  clients[BahamutRFClientType]{
            return client
        }
        let client = BahamutRFClient()
        client.setClientStart()
        return client
    }
}
