//
//  DynamicPatchManager.m
//
//
//  Created by KYao on 16/1/28.
//  Copyright © 2016年 XXXX. All rights reserved.
//

#import "DynamicPatchManager.h"
#import <JPEngine.h>
#import "NSData+Encryption.h"
#import "JPLoader.h"

static NSString *AES256Key = @"KDYNAMICPATCHxxxxx";


#define APP_DYNAMIC_PATCH_CLEANUP_KEY                       @"CleanupKey"
#define APP_DYNAMIC_PATCH_CONFIGURATION_FILE_NAME           @"ConfigurationFileName.dat"
#define APP_DYNAMIC_PATCH_CURRENT_PATCH_MD5                 @"MD5Code"
#define APP_DYNAMIC_PATCH_CURRENT_VERSION                   @"Version"
#define APP_DYNAMIC_PATCH_SCRIPT_DIRECTORY                  @"ScriptDirectory"


#define DISPATCH_SEMAPHORE_WAIT(sema)   dispatch_semaphore_wait(sema, DISPATCH_TIME_FOREVER);
#define DISPATCH_SEMAPHORE_SIGNAL(sema) dispatch_semaphore_signal(sema);


static NSMutableDictionary *dynamicPatchConfiguration = nil;
static NSUncaughtExceptionHandler *originalExceptionHandler = NULL;
static NSString *currentPatchScript = @"";

@interface DynamicPatchManager ()

+ (void)synchronizeConfiguration;

@property (nonatomic,strong)dispatch_semaphore_t    configurationSemaphore;

@property (nonatomic,assign)NSTimeInterval requestPatchScriptTime;

@property (nonatomic,copy) NSString *serverUrlString;
@property (nonatomic,copy) NSString *pwd;

@end

static void hotFixExceptionHandler(NSException *exception)
{
    [exception.callStackSymbols enumerateObjectsUsingBlock:^(NSString * _Nonnull lib, NSUInteger idx, BOOL * _Nonnull stop) {
        
        if ([lib rangeOfString:@"JPEngine"].length != 0) {
            
            [dynamicPatchConfiguration setObject:@"YES" forKey:APP_DYNAMIC_PATCH_CLEANUP_KEY];
            [dynamicPatchConfiguration setObject:[currentPatchScript MD5String] forKey:APP_DYNAMIC_PATCH_CURRENT_PATCH_MD5];
            [DynamicPatchManager synchronizeConfiguration];

            *stop = YES;
        }

    }];
    
    if (originalExceptionHandler) {
        originalExceptionHandler(exception);
    }
}

@implementation DynamicPatchManager

+ (void)load
{
}

+ (instancetype)sharedManager
{
    //Singleton instance
    static DynamicPatchManager *dynamicPatchManager;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        
        dynamicPatchManager = [[self alloc] init];
    });
    
    return dynamicPatchManager;
}

- (instancetype)init
{
    if ((self = [super init])) {

        _configurationSemaphore = dispatch_semaphore_create(1);

        dynamicPatchConfiguration = [NSMutableDictionary dictionaryWithContentsOfFile:[[self class] dynamicPatchConfigurationPath]];
        
        if (dynamicPatchConfiguration == nil) {
            dynamicPatchConfiguration = [NSMutableDictionary dictionary];
        }
        
        originalExceptionHandler = NSGetUncaughtExceptionHandler();
        NSSetUncaughtExceptionHandler(&hotFixExceptionHandler);
        
    }
    return self;
}

- (NSString *)decryptPatchScript
{
    NSString *scriptDirectory = [[self class] fetchScriptDirectory];
    NSString *scriptPath = [scriptDirectory stringByAppendingPathComponent:@"main.js"];
    
    if ([[NSFileManager defaultManager] fileExistsAtPath:scriptPath]) {
        
        NSString *jsPatchScript = [self decryptPatchScriptWithPath:scriptPath];
        if (jsPatchScript && ![[jsPatchScript MD5String] isEqualToString:[dynamicPatchConfiguration stringForKey:APP_DYNAMIC_PATCH_CURRENT_PATCH_MD5]]) {
            
            return jsPatchScript;
        }
    }

    return nil;
}

- (void)excutePatchScript:(DynamicPatchReturnBlock)completeBlock
{
    //[self LogDynamicPatchConfiguration:dynamicPatchConfiguration];
    void(^Block)(NSError *error) = ^(NSError *error) {
        
        if (completeBlock) {
            
            completeBlock(error, dynamicPatchConfiguration);
        }
    };
    
    [self runPatchScriptWithConfiguration:dynamicPatchConfiguration completeBlock:Block];
}

- (void)runPatchScriptWithConfiguration:(NSDictionary *)configuration completeBlock:(void(^)(NSError *error))completeBlock
{
    NSError *error = nil;
    
    NSString *cleanUp = configuration[APP_DYNAMIC_PATCH_CLEANUP_KEY];

    if ([cleanUp isEqualToString:@"YES"]) {
        
        error = [NSError errorWithDomain:@"" code:DynamicPatch_ScriptCrash userInfo:nil];

#ifdef DEBUG
        NSLog(@"Clean Up because of crash last time in js file.");
#endif

        DISPATCH_SEMAPHORE_WAIT(_configurationSemaphore);
        [dynamicPatchConfiguration removeObjectForKey:APP_DYNAMIC_PATCH_CLEANUP_KEY];
        [[self class] synchronizeConfiguration];
        DISPATCH_SEMAPHORE_SIGNAL(_configurationSemaphore);

        
    } else {
        
        NSString *scriptDirectory = [[self class] fetchScriptDirectory];
        NSString *scriptPath = [scriptDirectory stringByAppendingPathComponent:@"main.js"];
        if ([[NSFileManager defaultManager] fileExistsAtPath:scriptPath]) {
            
            NSString *jsPatchScript = [self decryptPatchScriptWithPath:scriptPath];
            if (jsPatchScript && [jsPatchScript isKindOfClass:[NSString class]] && ![[jsPatchScript MD5String] isEqualToString:[dynamicPatchConfiguration stringForKey:APP_DYNAMIC_PATCH_CURRENT_PATCH_MD5]]) {
                
                currentPatchScript = jsPatchScript;
                [self startEvaluateScript:jsPatchScript];

            } else {
                
                error = [NSError errorWithDomain:@"" code:DynamicPatch_ScriptVerifyError userInfo:nil];
            }
            
        } else {
            
            error = [NSError errorWithDomain:@"" code:DynamicPatch_ScriptNonExistent userInfo:nil];
        }

    }
    
    if (completeBlock) completeBlock(error);

   
}

- (void)startEvaluateScript:(NSString *)jsPatchScript
{
    dispatch_async(dispatch_get_main_queue(), ^ {
        
        [JPEngine startEngine];
        [JPEngine addExtensions:@[@"JPLoaderInclude"]];
        [JPEngine evaluateScript:jsPatchScript];
    });
}

-(void)evaluateScriptInMainBundleForName:(NSString *)name type:(NSString *)type
{
    NSData *data = [NSData dataWithContentsOfFile:[[NSBundle mainBundle] pathForResource:name ofType:type]];
    if (data && [data length] > 0) {
        
        NSString *jsPatchScript = [[NSString alloc] initWithData:data encoding:NSUTF8StringEncoding];
        if (jsPatchScript && [jsPatchScript isKindOfClass:[NSString class]] && [jsPatchScript length]) {
            
            currentPatchScript = jsPatchScript;
            [self startEvaluateScript:jsPatchScript];
            
        }
    }

}

- (NSString *)decryptPatchScriptWithPath:(NSString *)path
{
    NSData *data = [NSData dataWithContentsOfFile:path];
    if (data) {
        
        NSData *decryptData = [data AES256ParmDecryptWithKey:AES256Key];
        if (decryptData) {
            
            return [NSString stringWithCString:decryptData.bytes encoding:NSASCIIStringEncoding];
        }
    }
    
    return nil;
}

- (void)requestPatchScriptAndRunWithCompleteBlock:(DynamicPatchReturnBlock)completeBlock
{
    [self requestPatchScriptWithCompleteBlock:^(NSError *error, NSDictionary *dynamicPatchConfiguration) {
        
        if (!error) {
            
            [self excutePatchScript:^(NSError *error, NSDictionary *dynamicPatchConfiguration) {
                
                if (completeBlock) completeBlock(error, dynamicPatchConfiguration);

            }];
            
        } else {
            
            if (completeBlock) completeBlock(error, dynamicPatchConfiguration);
            
        }
    }];
}

- (void)requestPatchScriptWithCompleteBlock:(DynamicPatchReturnBlock)completeBlock
{
    if ([[NSDate date] timeIntervalSince1970] - self.requestPatchScriptTime < 60 * 5) {
        
        if (completeBlock) {
           completeBlock([NSError errorWithDomain:@"" code:DynamicPatch_ScriptRepeatRequest userInfo:nil], dynamicPatchConfiguration);
        }
        return;
    }
    self.requestPatchScriptTime = [[NSDate date] timeIntervalSince1970];

    NSInteger buildVersion = [CURRENT_APP_BUILDVERSION integerValue];

    [self requestUpdateToVersion:buildVersion completeBlock:^(NSError *error) {
        
        if (!error) {
            
            DISPATCH_SEMAPHORE_WAIT(_configurationSemaphore);
            [dynamicPatchConfiguration setObject:@(buildVersion) forKey:APP_DYNAMIC_PATCH_CURRENT_VERSION];
            [dynamicPatchConfiguration setObject:[[self class] fetchScriptDirectory] forKey:APP_DYNAMIC_PATCH_SCRIPT_DIRECTORY];
            [[self class] synchronizeConfiguration];
            DISPATCH_SEMAPHORE_SIGNAL(_configurationSemaphore);

        }
        if (completeBlock) completeBlock(error, dynamicPatchConfiguration);
    }];

}

- (void)requestUpdateToVersion:(NSInteger)version completeBlock:(void(^)(NSError *error))completeBlock
{
    [JPLoader updateToVersion:version callback:^(NSError *error) {
        
        if (completeBlock) {
            
            completeBlock(error);
        }
        
    }];
}

+ (void)synchronizeConfiguration
{
    [dynamicPatchConfiguration writeToFile:[self dynamicPatchConfigurationPath] atomically:YES];
}

+ (NSString *)fetchScriptDirectory
{
    NSString *appVersion = [[[NSBundle mainBundle] infoDictionary] objectForKey:@"CFBundleShortVersionString"];
    NSString *libraryDirectory = [NSSearchPathForDirectoriesInDomains(NSLibraryDirectory, NSUserDomainMask, YES) firstObject];
    NSString *scriptDirectory = [libraryDirectory stringByAppendingPathComponent:[NSString stringWithFormat:@"JSPatch/%@/", appVersion]];
    return scriptDirectory;
}

+ (NSString *)dynamicPatchConfigurationPath
{
    return [[self fetchScriptDirectory] stringByAppendingPathComponent:APP_DYNAMIC_PATCH_CONFIGURATION_FILE_NAME];
}

@end
