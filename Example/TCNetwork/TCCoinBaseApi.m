//
//  TCCoinBaseApi.m
//  Client
//
//  Created by fengunion on 2020/6/24.
//  Copyright © 2020 xtuck. All rights reserved.
//

#import "TCCoinBaseApi.h"

static NSString * const kLoginExpiredCode = @"201";

@implementation TCCoinBaseApi


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
    return @[@"200"];
}

- (void)configHttpManager:(AFHTTPSessionManager *)manager {
    [super configHttpManager:manager];
    manager.requestSerializer.timeoutInterval = 15;
    //发送请求的格式为json text格式
    manager.requestSerializer = [AFJSONRequestSerializer serializer];
}

- (void)configRequestHeaders:(NSMutableDictionary *)headers {
    [super configRequestHeaders:headers];
    [headers setValue:kUserInfo.token forKey:@"Authorization"];
}

- (NSArray *)ignoreErrToastCodes {
    //取消请求的错误码是-999
    return @[@(APIErrorCode_HttpCancel),kLoginExpiredCode];
}

- (NSError *)requestFinish:(TCBaseApi *)api {
    if (api.code.intValue == kLoginExpiredCode.intValue) {
        //token失效，需重新登录
        [[NSNotificationCenter defaultCenter] postNotificationName:@"kNotifyUserLoginExpired" object:api.error];
    }
    //可以重新创建error，也可以继续用api.error
    return api.error;
}

@end