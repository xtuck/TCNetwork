//
//  MyBaseApi.m
//  TCNetwork_Example
//
//  Created by fengunion on 2020/6/2.
//  Copyright © 2020 xtuck. All rights reserved.
//

#import "MyBaseApi.h"
#import "CocoaSecurity.h"

static NSString * const kNotLoginCode = @"10001";
static NSString * const kLoginExpiredCode = @"20001";

#pragma mark - baseUrl也可以写在自己的其他独立的配置文件中，便于统一管理维护。不需要重写的方法，可以不写

@implementation MyBaseApi

+ (NSString *)baseUrl {
    return @"http://154.85.49.201:8881";
}

- (void)apiCustomConfig {
    self.successCodeArray = @[@"0"];
    self.ignoreErrToastCodeArray = @[@(APIErrorCode_HttpCancel)];
    self.barrierErrCodeArray = @[kNotLoginCode,kLoginExpiredCode];
    self.requstSerializerType = TCRequest_JSON;
}

- (void)configHttpManager:(AFHTTPSessionManager *)manager {
    [super configHttpManager:manager];
    if (!manager.completionQueue) {
        manager.completionQueue = dispatch_queue_create("com.TCNetwork.completionQueue", DISPATCH_QUEUE_CONCURRENT);
    }
}

- (void)configRequestHeaders:(NSMutableDictionary *)headers {
    [super configRequestHeaders:headers];
    //"token"是登录接口返回的的数据
    [headers setValue:@"<token>" forKey:@"token"];
}

- (TCBaseApi *)requestBarrier:(TCBaseApi *)api {
    if (api.code.intValue == kLoginExpiredCode.intValue) {
        //刷新token
        return MyBaseApi.apiInitURLJoin(MyBaseApi.baseUrl,@"refreshToken",nil)
//        .l_params(@{@"token":TCUserDataUtil.userToken?:@""})
        .l_parseModelClass_parseKey(NSString.class,TCPInData(@"token"))
        .l_loadOnView_errOnView(nil,UIView.appWindow)
        .l_customConfigBlock(^(TCBaseApi *a){
            //a.barrierType = @"refreshToken";//这里可以自定义，也可省略
        })
        .l_successResultInterceptorBlock(^NSError *(MyBaseApi *a) {
//            TCUserinfo *info = TCUserDataUtil.sharedInstance.userinfo?:[[TCUserinfo alloc] init];
//            info.token = a.resultParseObject;
//            [TCUserDataUtil saveUserInfo:info];
            return nil;
        });
    } else if (api.code.intValue == kNotLoginCode.intValue) {
//        [TCLoginViewModel showLoginVC];
        [UIView.appWindow toastWithText:api.msg];
        return nil;
        
        //以下代码供自动登录测试
        NSString *testPhone = @"136xxxxx520";
        NSString *testPwd = @"111111";
        NSMutableDictionary *params = NSMutableDictionary.maker;
        params.addKV(@"tel",testPhone);
        params.addKV(@"password",testPwd.md5HexLower);
        return MyBaseApi.apiInitURLJoin(MyBaseApi.baseUrl,@"login/app",nil)
        .l_params(params)
        .l_parseModelClass_parseKey(NSString.class,TCPInData(@"token"))
        .l_loadOnView(UIView.appWindow)
        .l_successResultInterceptorBlock(^NSError *(MyBaseApi *api) {
//            TCUserinfo *info = [[TCUserinfo alloc] init];
//            info.token = api.resultParseObject;
//            info.phone = testPhone;
//            info.pwd = testPwd;
//            [TCUserDataUtil saveUserInfo:info];
//            [[NSNotificationCenter defaultCenter] postNotificationName:kNotifyUserLoginStatus object:@(YES)];
            [UIView.appWindow toastWithText:@"登录成功"];
            return nil;
        });
    }
    return nil;
}

@end
