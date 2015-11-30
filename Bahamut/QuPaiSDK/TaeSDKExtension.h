//
//  TaeSDKExtension.h
//  Bahamut
//
//  Created by AlexChow on 15/11/12.
//  Copyright © 2015年 GStudio. All rights reserved.
//

#ifndef TaeSDKExtension_h
#define TaeSDKExtension_h
#import <TAESDK/TaeSDK.h>
#import <ALBBQuPaiPlugin/ALBBQuPaiPluginPluginServiceProtocol.h>
@interface TaeSDK (QuPai)
-(id<ALBBQuPaiPluginPluginServiceProtocol>) getQuPaiSDk;
@end

#endif /* TaeSDKExtension_h */
