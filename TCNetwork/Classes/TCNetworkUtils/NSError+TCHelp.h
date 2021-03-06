//
//  NSError+TCHelp.h
//
//  Created by xtuck on 2018/1/22.
//  Copyright © 2018年 xtuck. All rights reserved.
//

#import <Foundation/Foundation.h>

typedef NS_ENUM(NSInteger,TCCustomApiErrorCode) {
    APIErrorCode_AutoBarrier=-1968,           //自动处理接口失败
    APIErrorCode_IgnoreError=-1969,           //忽略掉的错误
    APIErrorCode_NoNetwork=-1970,             //没有网络
    APIErrorCode_HttpMethodError=-1971,       //请求方法设置错误
    APIErrorCode_DataFormatError=-1980,       //返回数据格式有误
    APIErrorCode_ParseParamError=-1981,       //解析参数设置错误
    APIErrorCode_HttpCancel=-999,             //http请求被取消
};

@interface NSError (TCHelp)

@property (nonatomic, copy) NSString *strCode;

+ (NSError *)noNetworkError;

+ (NSError *)httpMethodError;

+ (NSError *)responseDataFormatError:(NSObject *)response;

+ (NSError *)parseParamError:(NSString *)paramDes;

+ (NSError *)responseResultError:(NSString *)code msg:(NSString *)msg;

//自定义构造error
+ (NSError *)errorCode:(NSString *)code msg:(NSString *)msg;

+ (NSError *)barrierFailedError;

@end
