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
    
    override func setReqHeader(_ req: BahamutRFRequestBase) -> BahamutRFRequestBase
    {
        req.headers.updateValue(BahamutRFKit.appkey, forKey: "appkey")
        return super.setReqHeader(req)
    }
}

private let BahamutFireClientType = "BahamutFireClientType"

extension BahamutRFKit{
    var fileApiServer:String!{
        get{
            return userInfos["fileApiServer"] as? String
        }
        set{
            userInfos["fileApiServer"] = newValue as AnyObject??
            
        }
    }
    
    @discardableResult
    func reuseFileApiServer(_ userId:String, token:String,fileApiServer:String) -> ClientProtocal
    {
        self.fileApiServer = fileApiServer
        let fileClient = BahamutFireClient(fileApiServer:self.fileApiServer,userId:userId,token:token)
        return useClient(fileClient, clientKey: BahamutFireClientType)
    }
    
    func getBahamutFireClient() -> BahamutFireClient
    {
        return clients[BahamutFireClientType] as! BahamutFireClient
    }
}

//MARK: Bahamut Fire Bucket Extension
extension BahamutFireClient{
    func sendFile(_ sendFileKey:FileAccessInfo,filePath:String)->UploadRequest
    {
        return sendFile(sendFileKey, filePathUrl: URL(fileURLWithPath: filePath))
    }
    
    func sendFile(_ sendFileKey:FileAccessInfo,filePathUrl:URL)->UploadRequest
    {
        let headers:HTTPHeaders = ["userId":self.userId,"token":self.token,"accessKey":sendFileKey.accessKey,"appkey":BahamutRFKit.appkey]
        return Alamofire.upload(filePathUrl, to: sendFileKey.server, method: .post, headers: headers)
        //return Alamofire.upload(Method.post, sendFileKey.server, headers: headers, file: filePathUrl)
    }
    
    func sendFile(_ sendFileKey:FileAccessInfo,fileData:Data)->UploadRequest
    {
        let headers :HTTPHeaders = ["userId":self.userId,"token":self.token,"accessKey":sendFileKey.accessKey,"appkey":BahamutRFKit.appkey]
        return Alamofire.upload(fileData, to: sendFileKey.server, method: .post, headers: headers)
        //return Alamofire.upload(.post, sendFileKey.server, headers: headers, data: fileData)
    }
    
    func downloadFile(_ fileId:String,filePath:String) -> DownloadRequest
    {
        let headers :HTTPHeaders = ["userId":self.userId,"token":self.token,"appkey":BahamutRFKit.appkey]
        let fileUrl = "\(self.apiServer)/Files/\(fileId)"
        return Alamofire.download(fileUrl, method: .get, parameters: nil, encoding: URLEncoding.default, headers: headers) { (url, response) -> (destinationURL: URL, options: DownloadRequest.DownloadOptions) in
            return (URL(fileURLWithPath: filePath),DownloadRequest.DownloadOptions.removePreviousFile)
        }
    }
}

/*
Get /BahamutFires/{fileId} : get a file request key for upload task
*/
open class GetBahamutFireRequest : BahamutRFRequestBase
{
    public override init()
    {
        super.init()
        self.api = "/BahamutFires"
        self.method = .get
    }
    
    open var fileId:String!{
        didSet{
            self.api = "/BahamutFires/\(fileId!)"
        }
    }
    
    open override func getMaxRequestCount() -> Int32 {
        return BahamutRFRequestBase.maxRequestNoLimitCount
    }
}

/*
POST /Files (fileType,fileSize) : get a new send file key for upload task
*/
open class NewBahamutFireRequest : BahamutRFRequestBase
{
    public override init()
    {
        super.init()
        self.api = "/BahamutFires"
        self.method = .post
    }
    
    open var fileType:FileType! = .noType{
        didSet{
            self.paramenters["fileType"] = "\(fileType.rawValue)"
        }
    }
    
    open var fileSize:Int = 512 * 1024{ //byte
        didSet{
            self.paramenters["fileSize"] = "\(fileSize)"
        }
    }
    
    open override func getMaxRequestCount() -> Int32 {
        return BahamutRFRequestBase.maxRequestNoLimitCount
    }
}
