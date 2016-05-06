//
//  DynamicPatchManager.h
//
//
//  Created by KYao on 16/1/28.
//  Copyright © 2016年 XXXX. All rights reserved.
//


typedef void (^DynamicPatchReturnBlock)(NSError *error, NSDictionary *dynamicPatchConfiguration);

typedef NS_ENUM(NSUInteger, DynamicPatchErrorCode) {
    
    DynamicPatch_ScriptCrash = 10000,
    DynamicPatch_ScriptNonExistent,
    DynamicPatch_ScriptVerifyError,
    DynamicPatch_ScriptRepeatRequest,
};


@interface DynamicPatchManager : NSObject

+ (instancetype)sharedManager;

/**
 *  返回当前脚本
 *
 *  @return <#return value description#>
 */
- (NSString *)decryptPatchScript;


/**
 *  执行本地MainBundle中的脚本
 *
 *  @param name <#name description#>
 *  @param type <#type description#>
 */
- (void)evaluateScriptInMainBundleForName:(NSString *)name type:(NSString *)type;


/**
 *  执行已经请求的最新脚本，Block返回脚本信息
 *
 *  @param completeBlock <#completeBlock description#>
 */
- (void)excutePatchScript:(DynamicPatchReturnBlock)completeBlock;


/**
 *  请求最新脚本，Block返回脚本信息
 *
 *  @param completeBlock <#completeBlock description#>
 */
- (void)requestPatchScriptWithCompleteBlock:(DynamicPatchReturnBlock)completeBlock;


/**
 *  请求最新脚本并执行, Block返回脚本信息 （这个只是合并上面2个接口）
 *
 *  @param completeBlock <#completeBlock description#>
 */
- (void)requestPatchScriptAndRunWithCompleteBlock:(DynamicPatchReturnBlock)completeBlock;



@end
