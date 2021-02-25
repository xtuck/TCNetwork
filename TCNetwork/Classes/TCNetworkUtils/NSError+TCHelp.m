//
//  NSError+TCHelp.m
//
//  Created by xtuck on 2018/1/22.
//  Copyright © 2018年 xtuck. All rights reserved.
//

#import "NSError+TCHelp.h"
#import <objc/runtime.h>

@implementation NSError (TCHelp)

- (NSString *)strCode {
    return objc_getAssociatedObject(self, _cmd);
}

- (void)setStrCode:(NSString *)strCode {
    objc_setAssociatedObject(self, @selector(strCode), strCode, OBJC_ASSOCIATION_COPY_NONATOMIC);
}


+ (NSError *)noNetworkError {
    NSError *error = [NSError errorWithDomain:@"TCFailureNoNetwork"
                                         code:APIErrorCode_NoNetwork
                                     userInfo:@{NSLocalizedDescriptionKey:@"No network"}];
    return error;
}

+ (NSError *)httpMethodError {
    NSError *error = [NSError errorWithDomain:@"TCFailureHttpMethodError"
                                         code:APIErrorCode_HttpMethodError
                                     userInfo:@{NSLocalizedDescriptionKey:@"HTTP method error"}];
    return error;
}

+ (NSError *)responseDataFormatError:(NSObject *)response {
    NSError *error = [NSError errorWithDomain:@"TCFailureResultDataFormatError"
                                         code:APIErrorCode_DataFormatError
                                     userInfo:@{NSLocalizedDescriptionKey:response.description?:@"Data format error"}];
    return error;
}

+ (NSError *)parseParamError:(NSString *)paramDes {
    NSString *msg = [NSString stringWithFormat:@"HTTP parse param error : %@",paramDes];
    NSError *error = [NSError errorWithDomain:@"TCFailureHttpParseParamError"
                                         code:APIErrorCode_ParseParamError
                                     userInfo:@{NSLocalizedDescriptionKey : msg}];
    return error;
}

+ (NSError *)responseResultError:(NSString *)code msg:(NSString *)msg {
    NSError *error = [NSError errorWithDomain:@"TCFailureResultUndesirability" code:code.integerValue userInfo:@{NSLocalizedDescriptionKey:msg?:@"Undesirability result"}];
    error.strCode = code;
    return error;
}

+ (NSError *)errorCode:(NSString *)code msg:(NSString *)msg {
    NSError *error = [NSError errorWithDomain:@"TCFailureCustomError"
                                         code:code.integerValue
                                     userInfo:@{NSLocalizedDescriptionKey:msg?:@"Unknown Error"}];
    error.strCode = code;
    return error;
}

+ (NSError *)barrierFailedError {
    NSError *error = [NSError errorWithDomain:@"TCBarrierFailed"
                                         code:APIErrorCode_AutoBarrier
                                     userInfo:@{NSLocalizedDescriptionKey:@"Auto request failed"}];
    return error;
}

@end
