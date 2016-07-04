//
//  Bahamut-Bridging-Header.h
//  Bahamut
//
//  Created by AlexChow on 15/10/8.
//  Copyright © 2015年 GStudio. All rights reserved.
//

/*
 说明: 本文件SDK版本和APP发行版本共同使用，项目中通过使用swift或oc的条件编译实现版本分离
 Sharelink Scheme是APP发行版本，用于开发、测试、发行App，LLVM Processing和Swift Flags中加入了宏APP_VERSION
 SDKSharelink Scheme是SDK版本，用于SDK版本开发和测试使用，发布通过SharelinkKernel项目进行，LLVM Processing和Swift Flags中加入了宏SDK_VERSION
 */

#ifndef Bahamut_Bridging_Header_h
#define Bahamut_Bridging_Header_h

#import "BahamutRFKit.h"

#import "UIBarButtomItem-Badge/UIButton+Badge.h"
#import "UIBarButtomItem-Badge/UIbarButtonItem+Badge.h"

#import <ChatFramework/ChatFramework.h>

#ifdef APP_VERSION
#import "UMMobClick/MobClick.h"
#import "UMessage.h"
#import <ShareSDK/ShareSDK.h>
#import <TencentOpenAPI/TencentOAuth.h>
#import <TencentOpenAPI/QQApiInterface.h>
#import "WXApi.h"
#import <TAESDK/TaeSDK.h>
#import <ALBBQuPaiPlugin/ALBBQuPaiPluginPluginServiceProtocol.h>
#import <ALBBQuPaiPlugin/QPEffect.h>
#import <ALBBQuPaiPlugin/QPEffectMusic.h>
#import "TaeSDKExtension.h"
#endif

#endif
