//
//  MyBaseApi.m
//  TCNetwork_Example
//
//  Created by fengunion on 2020/6/2.
//  Copyright © 2020 xtuck. All rights reserved.
//

#import "MyBaseApi.h"
#import "CocoaSecurity.h"

@implementation MyBaseApi

+ (NSString *)baseUrl {
    return @"http://xxxxxxxxxx:8181";
}

- (NSString *)codeKey {
    return @"code";
}

- (NSString *)messageKey {
    return @"msg";
}

- (NSString *)dataObjectKey {
    return @"data";
}

//数组中的元素：number和string都可以
- (NSArray *)successCodes {
    return @[@"0"];
}


- (void)configHttpManager:(AFHTTPSessionManager *)manager {
    manager.requestSerializer.timeoutInterval = 10;
}

- (void)configRequestParams:(NSMutableDictionary *)params {
    
}

- (BOOL)printLog {
    return [super printLog];
}


//以下三个方法：如果自定义toast，请return YES

- (BOOL)showCustomTost:(UIView *)onView text:(NSString *)text {
    return NO;
}

- (BOOL)showCustomTostLoading:(UIView *)onView {
    return NO;
}
- (BOOL)hideCustomTost:(UIView *)onView {
    return NO;
}



- (Class)propertyExtensionClass {
    return MyBaseApi.class;
}

@end
