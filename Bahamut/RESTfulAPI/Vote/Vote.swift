//
//  Vote.swift
//  BahamutRFKit
//
//  Created by AlexChow on 15/8/3.
//  Copyright (c) 2015年 GStudio. All rights reserved.
//

import Foundation
import EVReflection
import Alamofire

//MARK: Entities
public class Vote: BahamutObject
{
    public var voteId:String!
    public var shareId:String!
    
    public override func getObjectUniqueIdName() -> String {
        return "voteId"
    }
}

//MARK: Requests
/*
GET /Votes/{shareId} : return the shareId's votes
*/
public class VotesRequestBase : BahamutRFRequestBase
{
    public override init() {
        super.init()
        self.api = "/Votes"
        self.method = .GET
    }
    
    public var shareId:String!{
        didSet{
            self.api = "/Votes/\(shareId)"
        }
    }

}

/*
POST /Votes/{shareId} : vote sharething of shareId
*/
public class AddVoteRequest : VotesRequestBase
{
    public override init() {
        super.init()
        self.method = Method.POST
    }
    
}

/*
DELETE /Votes/{shareId} : vote sharething of shareId
*/
public class DeleteVoteRequest : VotesRequestBase
{
    public override init() {
        super.init()
        self.method = Method.DELETE
    }
}