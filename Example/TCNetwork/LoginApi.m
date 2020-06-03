//
//  LoginApi.m
//  TCNetwork_Example
//
//  Created by fengunion on 2020/6/2.
//  Copyright © 2020 xtuck. All rights reserved.
//

#import "LoginApi.h"
#import "CocoaSecurity.h"


//我写例子代码的时候，服务器用的是两个服务器的接口，所以没有把通用配置放基类

#pragma mark ---  此类中的大部分配置应该放在自己的基类中作为通用配置，大家可以根据实际应用场景进行灵活配置-----


@implementation LoginApi

+ (NSString *)baseUrl {
   return @"https://xxxxxxxxxxxxxxxxx";
}

- (NSString *)kSignSecret {
    return @"xxxxxxxxxxxxxxxxx";
}

- (NSString *)kSignKey {
    return @"xxxxxxxxxxxxxxxxx";
}

- (NSArray *)successCodes {
    return @[@"0001"];
}

- (void)configHttpManager:(AFHTTPSessionManager *)manager {
    [super configHttpManager:manager];
    //发送请求的格式为form格式,也是默认的序列化器
    manager.requestSerializer = [AFHTTPRequestSerializer serializer];
}

- (void)configRequestHeaders:(NSMutableDictionary *)headers {
    [super configRequestHeaders:headers];
    [headers setValue:@"student" forKey:@"Api-Requested-With"];
}

- (void)configRequestParams:(NSMutableDictionary *)params {
    [super configRequestParams:params];
    NSArray *allKeys = params.allKeys;
    NSArray *sortArray = [allKeys sortedArrayUsingSelector:@selector(compare:)];
    NSString *signString = [[NSString alloc] init];
    for (NSString *key in sortArray) {
        NSString *value = params[key];
        signString = [signString stringByAppendingFormat:@"%@%@",key,value];
    }
    signString = [NSString stringWithFormat:@"%@%@%@",self.kSignSecret,signString,self.kSignSecret];
    [params setValue:[CocoaSecurity md5:signString].hexLower forKey:@"_sign"];
    [params setValue:self.kSignKey forKey:@"_key"];
}


//登录接口
+ (TCBaseApi *)loginWithUsername:(NSString *)username pwd:(NSString *)pwd {
    NSMutableDictionary *param = NSMutableDictionary.maker;
    param.addKV(@"loginName",username);
    param.addKV(@"password",[CocoaSecurity md5:pwd].hexLower);
    
    //参数设置时，如果初始化时和接口调用时都设置了同一个参数，则以最后设置的为最终设置，比如下面设置了.l_loadOnView(UIView.appWindow)
    //但是调用的时候又设置了.l_loadOnView(self.view)，所以最后loading框会显示在self.view上
    
    return self.apiInitURLJoin(self.baseUrl,@"/user/login",nil).l_params(param).l_loadOnView(UIView.appWindow)
    .l_interceptorBlock(^NSError *(NSDictionary *res){
        //此处举例说明interceptorBlock的用法
        //res是登录成功返回的信息，但是在业务逻辑上可能需要判断用户角色或身份是否可以在当前客户端登录
        NSString *userType = res[@"type"];
        if (userType.intValue==2) {
            return [NSError errorCode:@"10086" msg:@"老师账号无法在学生端登录"];
        }
        return nil;//返回nil，表示不拦截登录
    });
}

@end
