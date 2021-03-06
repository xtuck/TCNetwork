//
//  TCNetworkHelp.m
//  TCNetwork
//
//  Created by fengunion on 2020/7/10.
//

#import "TCNetworkHelp.h"
#import <objc/runtime.h>

NSString * const kDCodeKey = @"code";
NSString * const kDMsgKey = @"msg";
NSString * const kDTimeKey = @"time";
NSString * const kDDataKey = @"data";
NSString * const kDOtherKey = @"other";


NSString * const kParseArray = @"()";//指定解析结果为数组，单独传入此值时，表示解析dataObjectKey对应的数组数据
NSString * const kParseRoot = @"~";//解析根节点Response
NSString * const kParseData = @"#";//解析dataObjectKey对应的数据
NSString * const kParseFlag = @"?";//解析的key加上标记，便于后面根据标记查询结果


extern NSString * TCPArray(NSString *key) {
    if ([key hasSuffix:@")"]) {
        return key;
    }
    if (key.length) {
        NSInteger loc = [key rangeOfString:kParseFlag options:NSBackwardsSearch].location;
        if (loc != NSNotFound) {
            //kParseFlag需要在parseKey末尾
            NSMutableString *mstr = [key mutableCopy];
            [mstr insertString:kParseArray atIndex:loc];
            return mstr;
        }
    }
    return [NSString stringWithFormat:@"%@%@",key?:@"",kParseArray];
}

extern NSString * TCPInData(NSString *key) {
    if ([key hasPrefix:kParseData]) {
        return key;
    }
    if (!key.length) {
        return kParseData;
    }
    if ([key hasPrefix:@"."]) {
        return [kParseData stringByAppendingString:key];
    }
    return [NSString stringWithFormat:@"%@.%@",kParseData,key];
}

extern NSString * TCPArrayInData(NSString *key) {
    return TCPArray(TCPInData(key));
}

extern NSString * TCPAddFlag(NSString *key, NSString *flag) {
    NSString *parseKey = key?:@"";
    if (key.length) {
        NSInteger loc = [key rangeOfString:kParseFlag options:NSBackwardsSearch].location;
        if (loc != NSNotFound) {
            parseKey = [key substringToIndex:loc];
        }
    }
    return [NSString stringWithFormat:@"%@%@%@",parseKey,kParseFlag,flag?:@""];
}

@implementation TCNetworkHelp

@end

#pragma mark - TCNWeakContainer

@implementation TCNWeakContainer

- (instancetype)initWithWeakObj:(id)obj {
    self = [super init];
    if (self) {
        _weakObj = obj;
    }
    return self;
}

@end

