//
//  TCBaseApi.m
//
//  Created by xtuck on 2017/12/14.
//  Copyright © 2017年 xtuck. All rights reserved.
//

#import "TCBaseApi.h"
#import "Aspects.h"
#import <objc/runtime.h>

typedef void (^ResponseSuccessBlock) (NSURLSessionDataTask *task, id response);
typedef void (^ResponseFailureBlock) (NSURLSessionDataTask *task, NSError *error);
typedef void (^HEADPATCHSuccessBlock) (NSURLSessionDataTask *task);


@interface TCBaseApi()

@end

@implementation TCBaseApi


+(TCBaseApi * (^)(NSString *))apiInitURLFull {
    return ^(NSString * apiInitURLFull){
        TCBaseApi *api = [[self.class alloc] init];
        api.URLFull = apiInitURLFull;
        api.isShowErr = YES;
        api.httpMethod = TCHttp_POST;
        return api;
    };
}

+(TCBaseApi * (^)(NSString *,...))apiInitURLJoin {
    return ^(NSString *str,...){
        va_list args;
        va_start(args, str);
        NSString *resultUrl = NSString.joinURL_VL(str,args);
        va_end(args);
        return self.apiInitURLFull(resultUrl);
    };
}

-(TCBaseApi * (^)(UIView *))l_loadOnView {
    return ^(UIView * l_loadOnView){
        self.loadOnView = l_loadOnView;
        return self;
    };
}

-(TCBaseApi * (^)(UIView *, BOOL))l_loadOnView_isShowErr {
    return ^(UIView * l_loadOnView,BOOL l_isShowErr){
        self.loadOnView = l_loadOnView;
        self.isShowErr = l_isShowErr;
        return self;
    };
}

-(TCBaseApi * (^)(id delegate))l_delegate {
    return ^(id l_delegate){
        self.delegate = l_delegate;
        return self;
    };
}

-(TCBaseApi * (^)(InterceptorBlock))l_interceptorBlock {
    return ^(InterceptorBlock l_interceptorBlock){
        self.interceptorBlock = l_interceptorBlock;
        return self;
    };
}


-(TCBaseApi * (^)(MultipartBlock))l_multipartBlock {
    return ^(MultipartBlock l_multipartBlock){
        self.multipartBlock = l_multipartBlock;
        return self;
    };
}

-(TCBaseApi * (^)(UploadProgressBlock))l_uploadProgressBlock {
    return ^(UploadProgressBlock l_uploadProgressBlock){
        self.uploadProgressBlock = l_uploadProgressBlock;
        return self;
    };
}

-(TCBaseApi * (^)(DownloadProgressBlock))l_downloadProgressBlock {
    return ^(DownloadProgressBlock l_downloadProgressBlock){
        self.downloadProgressBlock = l_downloadProgressBlock;
        return self;
    };
}


-(TCBaseApi * (^)(NSMutableDictionary *))l_params {
    return ^(NSMutableDictionary *l_params){
        self.params = l_params;
        return self;
    };
}

-(TCBaseApi * (^)(NSUInteger))l_filesCount {
    return ^(NSUInteger l_filesCount){
        self.filesCount = l_filesCount;
        return self;
    };
}

-(TCBaseApi * (^)(NSArray *))l_successCodeArray {
    return ^(NSArray *l_successCodeArray){
        self.successCodeArray = l_successCodeArray;
        return self;
    };
}

-(TCBaseApi * (^)(TCHttpMethod method))l_httpMethod {
    return ^(TCHttpMethod l_httpMethod){
        self.httpMethod = l_httpMethod;
        return self;
    };
}

-(TCBaseApi * (^)(FinishBlock))apiCallOriginal {
    return ^(FinishBlock l_finishBlock){
        self.originalFinishBlock = l_finishBlock;
        [self prepareRequest];
        return self;
    };
}

-(TCBaseApi * (^)(FinishBlock))apiCall {
    return ^(FinishBlock l_finishBlock){
        self.finishBlock = l_finishBlock;
        [self prepareRequest];
        return self;
    };
}

-(TCBaseApi * (^)(SuccessBlock))apiCallSuccess {
    return ^(SuccessBlock l_successBlock){
        self.successBlock = l_successBlock;
        [self prepareRequest];
        return self;
    };
}

-(TCBaseApi * (^)(SuccessVoidBlock))apiCallSuccessVoid {
    return ^(SuccessVoidBlock l_successVoidBlock){
        self.successVoidBlock = l_successVoidBlock;
        [self prepareRequest];
        return self;
    };
}

- (void)prepareRequest {
    //参数重置
    [self propertyReset];
    //开始执行请求
    [self request];
}

- (void)propertyReset {
    _httpTask = nil;
    _isRequesting = NO;
    _httpResponseObject = nil;
    _httpResultDataObject = nil;
    _httpResultOtherObject = nil;
    _httpError = nil;
}

/**
 处理http返回结果
 @param response http返回结果
 */
- (void)handleResponse:(id)response {
    _httpResponseObject = response;
    if (self.printLog) {
        NSLog(@"http responseObject:  %@", response);
    }
    if (self.originalFinishBlock) {
        self.originalFinishBlock(response,nil);
        return;
    }
    
    //解析数据
    if (![response isKindOfClass:NSDictionary.class]) {
        [self handleError:[NSError responseDataFormatError:response]];
        return;
    }
    
    NSString *codeKey = [self codeKey];
    if (!codeKey.isNonEmpty) {
        [self handleError:[NSError parseParamError:@"codeKey"]];
        return;
    }
    _code = response[codeKey];
    if ([_code isKindOfClass:NSNumber.class]) {
        //为了统一格式
        _code = [(NSNumber *)_code stringValue];
    }
    NSString *msgKey = [self messageKey];
    if (msgKey.isNonEmpty) {
        _message = response[msgKey];
    }
    NSString *currenttimeKey = [self currenttimeKey];
    if (currenttimeKey.isNonEmpty) {
        _currenttime = response[currenttimeKey];
    }
    NSString *dataObjectKey = [self dataObjectKey];
    if (dataObjectKey.isNonEmpty) {
        _httpResultDataObject = response[dataObjectKey];
    }
    NSString *otherObjectKey = [self otherObjectKey];
    if (otherObjectKey.isNonEmpty) {
        _httpResultOtherObject = response[otherObjectKey];
    }

    Class clazz = self.propertyExtensionClass;
    
    if ((![clazz isMemberOfClass:TCBaseApi.class])
        && [clazz isSubclassOfClass:TCBaseApi.class]
        && [self isKindOfClass:clazz]) {
        //对扩展的属性进行赋值
        unsigned int count;
        objc_property_t *propertyList = class_copyPropertyList(clazz, &count);
        for (unsigned int i = 0; i < count; i++) {
            const char *propertyName = property_getName(propertyList[i]);
            NSString *pName = [NSString stringWithUTF8String:propertyName];
            NSObject *value = _httpResponseObject[pName];
            if (self.printLog) {
                NSLog(@"扩展的属性：(%d) : %@ \n赋值：%@", i, pName, value.description);
            }
            [self setValue:value forKey:pName];
        }
        free(propertyList);
    }

    //判断结果是否成功
    if(_code.isNonEmpty) {
        NSArray *codes = self.successCodeArray.count ? self.successCodeArray : [self successCodes];
        if ([self isContainsCode:_code arr:codes]) {
            //成功
            [self handleSuccess];
            return;
        }
    }
    //失败
    NSError *error = [NSError responseResultError:_code msg:_message];
    [self handleError:error];
}

- (BOOL)isContainsCode:(NSString *)code arr:(NSArray *)codes {
    for (int i=0; i<codes.count; i++) {
        NSString *codeStr = codes[i];
        if ([codeStr isKindOfClass:NSNumber.class]) {
            codeStr = [(NSNumber *)codeStr stringValue];
        }
        if ([code isEqualToString:codeStr]) {
            return YES;
        }
    }
    return NO;
}

- (void)handleSuccess {
    _isRequesting = NO;
    id result = _httpResultDataObject ? : _httpResponseObject;
    
    if (self.interceptorBlock) {
        NSError *error = self.interceptorBlock(result);
        if (error) {
            [self handleError:error];
            return;
        }
    }
    
    if (self.loadOnView) {
        if (![self hideCustomTost:self.loadOnView]) {
            [self.loadOnView toastHide];
        }
    }

    if (self.successVoidBlock) {
        self.successVoidBlock();
    }
    if (self.successBlock) {
        self.successBlock(result);
    }
    if (self.finishBlock) {
        self.finishBlock(result,nil);
    }
}

- (void)handleError:(NSError *)error {
    _httpError = error;
    _isRequesting = NO;
    if (self.printLog) {
        NSLog(@"http error:  %@", error);
    }
    if (self.loadOnView) {
        if (![self hideCustomTost:self.loadOnView]) {
            [self.loadOnView toastHide];
        }
        if (self.isShowErr) {
            if (_code.isNonEmpty &&  [self isContainsCode:_code arr:self.ignoreErrToastCodes]) {
                if (self.printLog) {
                    NSLog(@"忽略了一个错误提示:  %@", _code);
                }
            } else {
                NSString *errMsg = nil;
                if ([error isKindOfClass:NSString.class]) {
                    errMsg = (id)error;
                } else if ([error isKindOfClass:NSError.class]){
                    errMsg = error.errorMessage;
                }
                if (![self showCustomTost:self.loadOnView text:errMsg]) {
                    [UIView.appWindow toastWithText:errMsg];
                }
            }
        }
    }
    
    if (self.originalFinishBlock) {
        self.originalFinishBlock(nil,error);
        return;
    }

    if (self.finishBlock) {
        self.finishBlock(nil,error);
    }
}


- (void)request {
    if (self.printLog) {
        NSLog(@"HTTP调用接口 %@",self.URLFull);
    }
    NSError *err = [self checkHttpCanRequest];
    if (err) {
        [self handleError:err];
        return;
    }
    
    if (self.loadOnView) {
        if (![self showCustomTostLoading:self.loadOnView]) {
            [self.loadOnView toastLoading];
        }
    }
    
    _isRequesting = YES;
    
    [self configHttpManager:[TCHttpManager sharedAFManager]];
    
    if (!self.params) {
        self.params = [NSMutableDictionary dictionary];
    }
    NSMutableDictionary *postParams = [self.params mutableCopy];
    [self configRequestParams:postParams];
    
    if (self.printLog) {
        NSLog(@"Request header: %@\n path: %@\n params: %@",[TCHttpManager sharedAFManager].requestSerializer.HTTPRequestHeaders , self.URLFull, postParams);
    }

    //下面的block中需要用self，延长实例生命周期
    ResponseSuccessBlock success = ^(NSURLSessionDataTask *task, id response) {
        [self handleResponse:response];
    };
    ResponseFailureBlock failure = ^(NSURLSessionDataTask *task, NSError *error) {
        [self handleError:error];
    };
    if (self.multipartBlock) {
        //只有post支持上传文件
        _httpTask = [[TCHttpManager sharedAFManager] POST:self.URLFull
                                               parameters:postParams
                                constructingBodyWithBlock:self.multipartBlock
                                                 progress:self.uploadProgressBlock
                                                  success:success
                                                  failure:failure];
    } else {
        switch (self.httpMethod) {
            case TCHttp_POST:
                _httpTask = [[TCHttpManager sharedAFManager] POST:self.URLFull parameters:postParams progress:self.uploadProgressBlock success:success failure:failure];
                break;
            case TCHttp_GET:
                _httpTask = [[TCHttpManager sharedAFManager] GET:self.URLFull parameters:postParams progress:self.downloadProgressBlock success:success failure:failure];
                break;
            case TCHttp_PUT:
                _httpTask = [[TCHttpManager sharedAFManager] PUT:self.URLFull parameters:postParams success:success failure:failure];
                break;
            case TCHttp_DELETE:
                _httpTask = [[TCHttpManager sharedAFManager] DELETE:self.URLFull parameters:postParams success:success failure:failure];
                break;
            case TCHttp_PATCH:
                _httpTask = [[TCHttpManager sharedAFManager] PATCH:self.URLFull parameters:postParams success:success failure:failure];
                break;
            case TCHttp_HEAD: {
                HEADPATCHSuccessBlock hpSuccess = ^(NSURLSessionDataTask *task) {
                    success(task,@"success");
                };
                _httpTask = [[TCHttpManager sharedAFManager] HEAD:self.URLFull parameters:postParams success:hpSuccess failure:failure];
            }
                break;
            default:
                //如果method设置错误
                [self handleError:NSError.httpMethodError];
                break;
        }
    }
    [self autoCancelTask];
}

- (void)autoCancelTask {
    //调用http请求的发起者对象销毁后，取消未完成的http请求
    if ([self.delegate isKindOfClass:[NSObject class]]) {
        __weak typeof(self) weakSelf = self;
        [self.delegate aspect_hookSelector:NSSelectorFromString(@"dealloc") withOptions:AspectPositionBefore usingBlock:^(id<AspectInfo> aspectInfo) {
            if (weakSelf.httpTask && weakSelf.httpTask.state != NSURLSessionTaskStateCompleted) {
                [weakSelf.httpTask cancel];
                if (self.printLog) {
                    NSLog(@"取消了一个请求:%@",weakSelf.httpTask.currentRequest.URL.absoluteString);
                }
            }
        } error:nil];
    }
}




#pragma mark -----子类可重写，进行自定义设置

#pragma mark --是否使用自定义toast
- (BOOL)showCustomTost:(UIView *)onView text:(NSString *)text {
    return NO;
}
//自定义数据加载中的提示框样式
- (BOOL)showCustomTostLoading:(UIView *)onView {
    return NO;
}
- (BOOL)hideCustomTost:(UIView *)onView {
    return NO;
}



- (BOOL)printLog {
#if DEBUG
    return YES;
#endif
    return NO;
}

- (NSError *)checkHttpCanRequest {
    return nil;
}

//普通请求都是单个请求，图片上传是多个图片一起上传，需要设置更长的超时时间
- (void)configHttpManager:(AFHTTPSessionManager *)manager {
    manager.requestSerializer.timeoutInterval = kHttpRequestTimeoutInterval*(self.filesCount>1?self.filesCount:1);
    //设置header等信息，例如
    //[manager.requestSerializer setValue:@"xxxxx" forHTTPHeaderField:@"xxxxxxxx"];
    //[manager.requestSerializer setValue:@"xxxxx" forHTTPHeaderField:@"token"];
}

- (void)configRequestParams:(NSMutableDictionary *)params {
}


//以下是默认配置，子类可重写
- (NSString *)codeKey {
    return @"code";
}

- (NSString *)messageKey {
    return @"message";
}

- (NSString *)currenttimeKey {
    return @"currenttime";
}

- (NSString *)dataObjectKey {
    return @"data";
}

- (NSString *)otherObjectKey {
    return @"other";
}


- (NSArray *)successCodes {
    return @[@"1",@"ok",@"yes",@"OK",@"YES"];
}

- (NSArray *)ignoreErrToastCodes {
    //取消请求的错误码是-999
    return @[@"-999"];
}

- (Class)propertyExtensionClass {
    return nil;
}

@end
