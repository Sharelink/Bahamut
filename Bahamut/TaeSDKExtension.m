//
//  TaeSDKExtension.m
//  Bahamut
//
//  Created by AlexChow on 15/11/12.
//  Copyright © 2015年 GStudio. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "TaeSDKExtension.h"

@implementation TaeSDK(QuPai)

-(id<ALBBQuPaiPluginPluginServiceProtocol>) getQuPaiSDk{
    id<ALBBQuPaiPluginPluginServiceProtocol> sdk = [[TaeSDK sharedInstance] getService:@protocol(ALBBQuPaiPluginPluginServiceProtocol)];
    return sdk;
}

@end