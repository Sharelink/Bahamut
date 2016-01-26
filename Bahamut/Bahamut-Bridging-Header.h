//
//  Bahamut-Bridging-Header.h
//  Bahamut
//
//  Created by AlexChow on 15/10/8.
//  Copyright © 2015年 GStudio. All rights reserved.
//

#ifndef Bahamut_Bridging_Header_h
#define Bahamut_Bridging_Header_h

#define APP_VERSION 1

#import "SharelinkSDK.h"

#import "UIBarButtomItem-Badge/UIButton+Badge.h"
#import "UIBarButtomItem-Badge/UIbarButtonItem+Badge.h"

#import <ChatFramework/ChatFramework.h>

#ifdef APP_VERSION

#import "UMessage.h"
#import <ShareSDK/ShareSDK.h>
#import <TencentOpenAPI/TencentOAuth.h>
#import <TencentOpenAPI/QQApiInterface.h>
#import "WXApi.h"
#import "MobClick.h"
#import "MobClickSocialAnalytics.h"
#import <TAESDK/TaeSDK.h>
#import <ALBBQuPaiPlugin/ALBBQuPaiPluginPluginServiceProtocol.h>
#import <ALBBQuPaiPlugin/QPEffect.h>
#import <ALBBQuPaiPlugin/QPEffectMusic.h>
#import "TaeSDKExtension.h"
#endif

#endif /* Bahamut_Bridging_Header_h */
