//
//  NSMutableDictionary+paramsSet.h
//  RRT
//
//  Created by 涂操 on 15/9/10.
//  Copyright (c) 2015年 Asiainfo. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface NSMutableDictionary (paramsSet)

- (void)setParamsWithKey:(NSString *)key value:(id)value;

- (void)removeValueWithKey:(NSString *)key;

- (NSMutableDictionary *(^)(NSString *,id))addKV;

+ (NSMutableDictionary *)maker;

@end
