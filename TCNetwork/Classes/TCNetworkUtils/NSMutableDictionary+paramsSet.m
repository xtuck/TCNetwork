//
//  NSMutableDictionary+paramsSet.m
//  RRT
//
//  Created by xtuck on 15/9/10.
//  Copyright (c) 2015年 Asiainfo. All rights reserved.
//

#import "NSMutableDictionary+paramsSet.h"

@implementation NSMutableDictionary (paramsSet)

- (void)setParamsWithKey:(NSString *)key value:(id)value {
    if (key) {
        [self setValue:value forKey:key];
    }
}

- (void)removeValueWithKey:(NSString *)key {
    if (key) {
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

/*
@interface NSDictionary (TCDeform)
@end

@implementation NSDictionary (TCDeform)

- (NSMutableDictionary *)tc_deform {
    NSMutableDictionary *dic = [self mutableCopy];
    NSArray *allKey = dic.allKeys;
    for (NSString *key in allKey) {
        NSDictionary *value = dic[key];
        if ([value isKindOfClass:NSDictionary.class]) {
            NSArray *dicKeys = value.allKeys;
            if (dicKeys.count==2 &&
                (([dicKeys[0] isEqualToString:@"id"]&&[dicKeys[1] isEqualToString:@"text"])||
                 ([dicKeys[1] isEqualToString:@"id"]&&[dicKeys[0] isEqualToString:@"text"]))) {
                [dic setValue:value[@"id"] forKey:key];
            } else {
                value = [value tc_deform];
                [dic setValue:value forKey:key];
            }
        } else if ([value isKindOfClass:NSArray.class]) {
            NSMutableArray *array = [NSDictionary tc_deformArray:(id)value];
            [dic setValue:array forKey:key];
        } else if ([value isKindOfClass:NSNumber.class]) {
            NSString *doubleString = [NSString stringWithFormat:@"%.8f",[(NSNumber *)value doubleValue]];
            NSDecimalNumber *decNumber = [NSDecimalNumber decimalNumberWithString:doubleString];
            [dic setValue:decNumber forKey:key];
        }
    }
    return dic;
}

+ (NSMutableArray *)tc_deformArray:(NSArray *)array {
    NSMutableArray *mArray = [array mutableCopy];
    for (int i=0;i<array.count;i++) {
        NSDictionary *obj = array[i];
        if ([obj isKindOfClass:NSDictionary.class]) {
            obj = [obj tc_deform];
            [mArray replaceObjectAtIndex:i withObject:obj];
        } else if ([obj isKindOfClass:NSArray.class]) {
            obj = (id)[self tc_deformArray:(id)obj];
            [mArray replaceObjectAtIndex:i withObject:obj];
        }
    }
    return mArray;
}

@end
*/
