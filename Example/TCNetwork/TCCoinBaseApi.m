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

- (NSString *)msgKey {
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
    //这里加判断，是避免重复设置
    if (![manager.requestSerializer.class isMemberOfClass:AFJSONRequestSerializer.class]) {
        //发送请求的格式为json text格式
        manager.requestSerializer = [AFJSONRequestSerializer serializer];   //这个每次都是重新创建的serializer
        manager.requestSerializer.timeoutInterval = 15;                     //所以这个timeout设置要放后面
    }
}

- (void)configRequestHeaders:(NSMutableDictionary *)headers {
    [super configRequestHeaders:headers];
    //"token"是登录接口返回的的数据
    [headers setValue:@"<token>" forKey:@"Authorization"];
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

#ifdef DEBUG
//实现下面方法，可以自定义toast样式，实现代码可以自己写，可以使用其他第三方库的toast库
- (void)customTost:(UIView *)onView text:(NSString *)msg action:(TCToastActionType)type {
    if (type==TCToast_Hide) {
        [onView toastHide];
    } else {
        MBProgressHUD *hud = nil;
        if (type == TCToast_Error) {
            hud = [onView toastWithText:msg];
        } else {
            hud = [onView toastLoadingWithText:msg];
        }
        hud.bezelView.blurEffectStyle = UIBlurEffectStyleLight;
        hud.contentColor = [UIColor systemPinkColor];
    }
}

//实现下面方法，可以使用其他的字典转model的第三方库，返回解析结果给api对象
//- (id)customParse:(id)source clazz:(Class)modelClass isArray:(BOOL)isArray err:(NSError **)err {
//    return nil;
//}

#endif


@end
