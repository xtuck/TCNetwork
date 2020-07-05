//
//  NSMutableDictionary+paramsSet.m
//  RRT
//
//  Created by 涂操 on 15/9/10.
//  Copyright (c) 2015年 Asiainfo. All rights reserved.
//

#import "NSMutableDictionary+paramsSet.h"

@implementation NSMutableDictionary (paramsSet)

- (void)setParamsWithKey:(NSString *)key value:(id)value {
    if (key.length) {
        [self setValue:value forKey:key];
    }
}

- (void)removeValueWithKey:(NSString *)key {
    if (key.length) {
        [self removeObjectForKey:key];
    }
}
- (NSMutableDictionary *(^)(NSString *,id))addKV {
    return ^(NSString *key,id value){
        [self setParamsWithKey:key value:value];
        return self;
    };
}

+ (NSMutableDictionary *)maker {
    return [self dictionary];
}

@end
