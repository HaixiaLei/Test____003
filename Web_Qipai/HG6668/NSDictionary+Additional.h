//
//  NSDictionary+Additional.h
//  ShowMessage
//
//  Created by Heguiting on 8/17/15.
//  Copyright (c) 2015 Heguiting. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface NSDictionary (Additional)

/**
 *  转化为json格式
 */
-(NSString *)JSONString;

/**
 *  安全返回对应的值,否则返回nil
 */
- (NSString*)stringForKey:(NSString*)key;
- (NSNumber*)numberForKey:(NSString*)key;
- (NSArray*)arrayForKey:(NSString*)key;
- (NSDictionary*)dictionaryForKey:(NSString*)key;
- (NSInteger)integerForKey:(id)key;
- (BOOL)boolForKey:(id)key;
- (float)floatForKey:(id)key;
- (double)doubleForKey:(id)key;

@end
