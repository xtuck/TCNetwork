//
//  MyBaseApi.m
//  TCNetwork_Example
//
//  Created by fengunion on 2020/6/2.
//  Copyright © 2020 xtuck. All rights reserved.
//

#import "MyBaseApi.h"
#import "CocoaSecurity.h"


#pragma mark - baseUrl也可以写在自己的其他独立的配置文件中，便于统一管理维护。不需要重写的方法，可以不写

@implementation MyBaseApi

+ (NSString *)baseUrl {
    return @"http://154.85.49.201:8881";
}

- (NSString *)codeKey {
    return @"code";
}

- (NSString *)msgKey {
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
}

- (void)configRequestParams:(NSObject *)params {
}

- (void)configRequestHeaders:(NSMutableDictionary *)headers {
}

- (BOOL)printLog {
    return [super printLog];
}


- (NSError *)requestFinish:(TCBaseApi *)api {
    if (api.code.intValue == 10010) {
        //token失效，需重新登录
        [[NSNotificationCenter defaultCenter] postNotificationName:@"kNotifyUserLoginExpired" object:nil];
    } if (api.code.intValue == 10000) {
        //你的账号已在别处登录
        [[NSNotificationCenter defaultCenter] postNotificationName:@"kNotifyUserLoginSqueezed" object:nil];
    }
    //可以重新创建error，也可以继续用api.error
    return api.error;
}
@end
