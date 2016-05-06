//
//  NSData+Encryption.h
//
//
//  Copyright (c) 2015年 xxxxx. All rights reserved.
//加密解密处理类

#import <Foundation/Foundation.h>

@interface NSData (Encryption)
- (NSData *)AES256ParmEncryptWithKey:(NSString *)key;
- (NSData *)AES256ParmDecryptWithKey:(NSString *)key;

- (NSData *)AES128ParmEncryptWithKey:(NSString *)key;
- (NSData *)AES128ParmDecryptWithKey:(NSString *)key;

@end
