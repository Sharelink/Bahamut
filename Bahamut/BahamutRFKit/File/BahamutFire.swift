//
//  BahamutFire.swift
//  Bahamut
//
//  Created by AlexChow on 15/11/25.
//  Copyright © 2015年 GStudio. All rights reserved.
//

import Foundation
import Alamofire

class BahamutFireClient : BahamutRFClient
{
    
    init(fileApiServer:String,userId:String,token:String)
    {
        super.init(apiServer: fileApiServer, userId: userId, token: token)
    }
    
    override func setReqHeader(req: BahamutRFRequestBase) -> BahamutRFRequestBase
    {
        req.headers.updateValue(BahamutRFKit.appkey, forKey: "appkey")
        return super.setReqHeader(req)
    }
    
    func sendFile(sendFileKey:FileAccessInfo,filePath:String)->Request
    {
        return sendFile(sendFileKey, filePathUrl: NSURL(fileURLWithPath: filePath))
    }
    
    func sendFile(sendFileKey:FileAccessInfo,filePathUrl:NSURL)->Request
    {
        let headers :[String:String] = ["userId":self.userId,"token":self.token,"accessKey":sendFileKey.accessKey,"appkey":BahamutRFKit.appkey]
        return Manager.sharedInstance.upload(Method.POST, sendFileKey.server, headers: headers, file: filePathUrl)
    }
    
    func sendFile(sendFileKey:FileAccessInfo,fileData:NSData)->Request
    {
        let headers :[String:String] = ["userId":self.userId,"token":self.token,"accessKey":sendFileKey.accessKey,"appkey":BahamutRFKit.appkey]
        return Manager.sharedInstance.upload(.POST, sendFileKey.server, headers: headers, data: fileData)
    }
    
    func downloadFile(fileId:String,filePath:String) -> Request
    {
        let headers :[String:String] = ["userId":self.userId,"token":self.token,"appkey":BahamutRFKit.appkey]
        let fileUrl = "\(self.apiServer)/Files/\(fileId)"
        let req = Manager.sharedInstance.download(Method.GET, fileUrl , headers: headers){ temporaryURL, response in
            return NSURL(fileURLWithPath: filePath)
        }
        return req
    }
}

/*
Get /BahamutFires/{fileId} : get a file request key for upload task
*/
public class GetBahamutFireRequest : BahamutRFRequestBase
{
    public override init()
    {
        super.init()
        self.api = "/BahamutFires"
        self.method = .GET
    }
    
    public var fileId:String!{
        didSet{
            self.api = "/BahamutFires/\(fileId)"
        }
    }
}

/*
POST /Files (fileType,fileSize) : get a new send file key for upload task
*/
public class NewBahamutFireRequest : BahamutRFRequestBase
{
    public override init()
    {
        super.init()
        self.api = "/BahamutFires"
        self.method = .POST
    }
    
    public var fileType:FileType! = .NoType{
        didSet{
            self.paramenters["fileType"] = "\(fileType.rawValue)"
        }
    }
    
    public var fileSize:Int = 512 * 1024{ //byte
        didSet{
            self.paramenters["fileSize"] = "\(fileSize)"
        }
    }
}
