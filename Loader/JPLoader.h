//
//  JSPatch.h
//  JSPatch
//
//  Created by bang on 15/11/14.
//  Copyright (c) 2015 bang. All rights reserved.
//

#import <Foundation/Foundation.h>

const static NSString *rootUrl = @"http://7xr4jm.com1.z0.glb.clouddn.com";

static NSString *publicKey = @"-----BEGIN PUBLIC KEY-----\n             \
MIGfMA0GCSqGSIb3DQEBAQUAA4GNADCBiQKBgQDK3fvgvBuUtmnXaJBr4mxFByU3\n      \
S5IQYKPMiRTPYpWDMjHRcyNRPQtVVSSjAL5iV7pO2SrX+IBrb15Sim/OaMecCJRU\n      \
l8A5Q8VTuO/skzdRGqCg2GYi5rusuAZPQkGLk4y7miCKbG8nMW19C+5YeePmQ7e3\n      \
QAmg8gpCtgN0jvwlBwIDAQAB\n                                              \
-----END PUBLIC KEY-----";

typedef void (^JPUpdateCallback)(NSError *error);

typedef enum {
    JPUpdateErrorUnzipFailed = -1001,
    JPUpdateErrorVerifyFailed = -1002,
} JPUpdateError;

@interface JPLoader : NSObject
+ (BOOL)run;
+ (void)updateToVersion:(NSInteger)version callback:(JPUpdateCallback)callback;
+ (void)runTestScriptInBundle;
+ (void)setLogger:(void(^)(NSString *log))logger;
+ (NSInteger)currentVersion;
@end