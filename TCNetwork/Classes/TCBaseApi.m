//
//  TCBaseApi.m
//
//  Created by xtuck on 2017/12/14.
//  Copyright © 2017年 xtuck. All rights reserved.
//

#import "TCBaseApi.h"
#import <Aspects/Aspects.h>
#import <objc/runtime.h>

typedef void (^ResponseSuccessBlock) (NSURLSessionDataTask *task, id response);
typedef void (^ResponseFailureBlock) (NSURLSessionDataTask *task, NSError *error);
typedef void (^HEADPATCHSuccessBlock) (NSURLSessionDataTask *task);


@interface TCBaseApi()

@property (nonatomic,copy) FinishBlock originalFinishBlock;
@property (nonatomic,copy) FinishBlock finishBlock;
@property (nonatomic,copy) FinishBlock successBlock;

@property (nonatomic,copy) MultipartBlock multipartBlock;
@property (nonatomic,copy) UploadProgressBlock uploadProgressBlock;
@property (nonatomic,copy) DownloadProgressBlock downloadProgressBlock;

@property (nonatomic,copy) InterceptorBlock interceptorBlock;

@property (nonatomic,strong) NSObject *params;//执行http请求时传的参数
@property (nonatomic,strong) NSArray *successCodeArray;//作用：用来判断返回结果是否是成功的结果，优先级高于successCodes方法
@property (nonatomic,weak) UIView *loadOnView;
@property (nonatomic,assign) BOOL isShowErr;//发生错误时，是否显示toast提示
@property (nonatomic,assign) TCHttpMethod httpMethod;//HTTP请求的method，默认post,因为post最常用

@property (nonatomic,weak) TCBaseApi *weakApi;//通过finishBlock回传给http请求的调用者

@end

@implementation TCBaseApi


+(TCBaseApi * (^)(NSString *))apiInitURLFull {
    return ^(NSString * apiInitURLFull){
        TCBaseApi *api = [[self.class alloc] init];
        api->_URLFull = apiInitURLFull;
        api.httpMethod = TCHttp_POST;
        __weak typeof(api) weakApi = api;
        api.weakApi = weakApi;
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
        self.isShowErr = l_loadOnView != nil;
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
        self->_delegate = l_delegate;
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


-(TCBaseApi * (^)(NSObject *))l_params {
    return ^(NSObject *l_params){
        self.params = l_params;
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
    return ^(FinishBlock l_originalFinishBlock){
        self.originalFinishBlock = l_originalFinishBlock;
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

-(TCBaseApi * (^)(FinishBlock))apiCallSuccess {
    return ^(FinishBlock l_successBlock){
        self.successBlock = l_successBlock;
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
    _response = nil;
    _dataObject = nil;
    _otherObject = nil;
    _error = nil;
    
    _code = nil;
    _msg = nil;
    _time = nil;
}

/**
 处理http返回结果
 @param response http返回结果
 */
- (void)handleResponse:(id)response {
    [self stopLoading];
    _response = response;
    if (self.printLog) {
        NSLog(@"http responseObject:  %@", response);
    }
    
    if (self.originalFinishBlock) {
        self.originalFinishBlock(self.weakApi);
        return;
    }
    
    //解析数据
    if (![response isKindOfClass:NSDictionary.class]) {
        [self handleError:[NSError responseDataFormatError:response]];
        return;
    }
    
    NSString *codeKey = [self codeKey];
    if (codeKey.isNonEmpty) {
        _code = response[codeKey];
    }
    if ([_code isKindOfClass:NSNumber.class]) {
        //为了统一格式
        _code = [(NSNumber *)_code stringValue];
    }
    NSString *msgKey = [self msgKey];
    if (msgKey.isNonEmpty) {
        _msg = response[msgKey];
    }
    NSString *timeKey = [self timeKey];
    if (timeKey.isNonEmpty) {
        _time = response[timeKey];
    }
    NSString *dataObjectKey = [self dataObjectKey];
    if (dataObjectKey.isNonEmpty) {
        _dataObject = response[dataObjectKey];
    }
    NSString *otherObjectKey = [self otherObjectKey];
    if (otherObjectKey.isNonEmpty) {
        _otherObject = response[otherObjectKey];
    }

    NSError *err = [self requestFinish:self.weakApi];
    if (err) {
        [self handleError:err];
        return;
    }

    //判断结果是否成功
    if(_code.isNonEmpty) {
        NSArray *codes = self.successCodeArray.count ? self.successCodeArray : [self successCodes];
        if ([self isContainsCode:_code arr:codes]) {
            //成功
            [self handleSuccess];
            return;
        }
    } else {
        //code为空
        if (self.finishBlock) {
            self.finishBlock(self.weakApi);
        }
        return;
    }
    //失败
    NSError *error = [NSError responseResultError:_code msg:_msg];
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
    if (self.interceptorBlock) {
        NSError *error = self.interceptorBlock(self.weakApi);
        if (error) {
            [self handleError:error];
            return;
        }
    }
    if(self.successBlock) {
        self.successBlock(self.weakApi);
    } else if (self.finishBlock) {
        self.finishBlock(self.weakApi);
    }
}

- (void)handleError:(NSError *)error {
    [self stopLoading];
    _error = error;
    _isRequesting = NO;
    if (self.printLog) {
        NSLog(@"http error:  %@", error);
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
            if (![self showCustomTost:(self.loadOnView ? : UIView.appWindow) text:errMsg]) {
                [UIView.appWindow toastWithText:errMsg];
            }
        }
    }
    
    if (self.originalFinishBlock) {
        self.originalFinishBlock(self.weakApi);
    } else if (self.finishBlock) {
        self.finishBlock(self.weakApi);
    }
}

- (void)stopLoading {
    if (self.loadOnView) {
        if (![self hideCustomTost:self.loadOnView]) {
            [self.loadOnView toastHide];
        }
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
    NSObject *postParams = [self.params mutableCopy];
    [self configRequestParams:postParams];
    
    //下面的block中需要用self，延长实例生命周期
    ResponseSuccessBlock success = ^(NSURLSessionDataTask *task, id response) {
        [self handleResponse:response];
    };
    ResponseFailureBlock failure = ^(NSURLSessionDataTask *task, NSError *error) {
        NSError *err = [self requestFinish:self.weakApi];
        if (err) {
            [self handleError:err];
        } else {
            [self handleError:error];
        }
    };
    
    NSMutableDictionary *headers = [NSMutableDictionary dictionary];
    [self configRequestHeaders:headers];
    
    if (self.multipartBlock) {
        //只有post支持上传文件
        _httpTask = [[TCHttpManager sharedAFManager] POST:self.URLFull
                                               parameters:postParams
                                                  headers:headers
                                constructingBodyWithBlock:self.multipartBlock
                                                 progress:self.uploadProgressBlock
                                                  success:success
                                                  failure:failure];
    } else {
        switch (self.httpMethod) {
            case TCHttp_POST:
                _httpTask = [[TCHttpManager sharedAFManager] POST:self.URLFull
                                                       parameters:postParams
                                                          headers:headers
                                                         progress:self.uploadProgressBlock
                                                          success:success
                                                          failure:failure];
                break;
            case TCHttp_GET:
                _httpTask = [[TCHttpManager sharedAFManager] GET:self.URLFull
                                                      parameters:postParams
                                                         headers:headers
                                                        progress:self.downloadProgressBlock
                                                         success:success
                                                         failure:failure];
                break;
            case TCHttp_PUT:
                _httpTask = [[TCHttpManager sharedAFManager] PUT:self.URLFull
                                                      parameters:postParams
                                                         headers:headers
                                                         success:success
                                                         failure:failure];
                break;
            case TCHttp_DELETE:
                _httpTask = [[TCHttpManager sharedAFManager] DELETE:self.URLFull
                                                         parameters:postParams
                                                            headers:headers
                                                            success:success
                                                            failure:failure];
                break;
            case TCHttp_PATCH:
                _httpTask = [[TCHttpManager sharedAFManager] PATCH:self.URLFull
                                                        parameters:postParams
                                                           headers:headers
                                                           success:success
                                                           failure:failure];
                break;
            case TCHttp_HEAD: {
                HEADPATCHSuccessBlock hpSuccess = ^(NSURLSessionDataTask *task) {
                    success(task,@"success");
                };
                _httpTask = [[TCHttpManager sharedAFManager] HEAD:self.URLFull
                                                       parameters:postParams
                                                          headers:headers
                                                          success:hpSuccess
                                                          failure:failure];
            }
                break;
            default:
                //如果method设置错误
                [self handleError:NSError.httpMethodError];
                break;
        }
    }
    [self autoCancelTask];
    
    if (self.printLog) {
        NSLog(@"Request header: %@\n path: %@\n params: %@",_httpTask.originalRequest.allHTTPHeaderFields.description, self.URLFull, postParams);
    }
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

- (void)configHttpManager:(AFHTTPSessionManager *)manager {
}

- (void)configRequestParams:(NSObject *)params {
}

- (void)configRequestHeaders:(NSMutableDictionary *)headers {
}


//以下是默认配置，子类可重写
- (NSString *)codeKey {
    return @"code";
}

- (NSString *)msgKey {
    return @"msg";
}

- (NSString *)timeKey {
    return @"time";
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

- (NSError *)requestFinish:(TCBaseApi *)api {
    return nil;
}

@end
