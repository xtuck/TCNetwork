//
//  CoinLoginApi.m
//  TCNetwork_Example
//
//  Created by fengunion on 2020/6/3.
//  Copyright © 2020 xtuck. All rights reserved.
//

#import "CoinLoginApi.h"

@implementation CoinLoginApi


+ (NSString *)baseUrl {
   return @"http://xxxxxxxxxxxxxxxxx";
}

- (void)configHttpManager:(AFHTTPSessionManager *)manager {
    [super configHttpManager:manager];
    //发送请求的格式为json text格式
    manager.requestSerializer = [AFJSONRequestSerializer serializer];
}

- (void)configRequestHeaders:(NSMutableDictionary *)headers {
    [super configRequestHeaders:headers];
    [headers setValue:@"zh-CN" forKey:@"Accept-Language"];
}

//登录接口
+ (TCBaseApi *)loginWithUsername:(NSString *)username pwd:(NSString *)pwd {
    NSMutableDictionary *param = NSMutableDictionary.maker;
    param.addKV(@"mobile",username);
    param.addKV(@"password",pwd);
    return self.apiInitURLJoin(self.baseUrl,@"contract/auth/login",nil).l_params(param).l_loadOnView(UIView.appWindow);
}

@end
