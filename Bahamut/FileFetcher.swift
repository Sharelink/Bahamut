//
//  FileFetcher.swift
//  Bahamut
//
//  Created by AlexChow on 15/9/8.
//  Copyright © 2015年 GStudio. All rights reserved.
//

import Foundation

protocol FileFetcher
{
    func startFetch(resourceUri:String,delegate:FileFetcherDelegate)
}

@objc
protocol FileFetcherDelegate
{
    optional func fetchFileProgress(persent:Float)->Void
    optional func fetchFileCompleted(filePath:String!)->Void
}

@objc
protocol FileUploadDelegate
{
    optional func uploadFileProgress(persent:Float)->Void
    optional func uploadFileCompleted(fileId:String,isSuc:Bool)->Void
}