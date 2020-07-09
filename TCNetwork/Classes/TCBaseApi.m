//
//  TCBaseApi.m
//
//  Created by xtuck on 2017/12/14.
//  Copyright © 2017年 xtuck. All rights reserved.
//

#import "TCBaseApi.h"
#import <Aspects/Aspects.h>
#import <objc/runtime.h>

@interface TCBaseApi()

@property (nonatomic,copy) FinishBlock originalFinishBlock;
@property (nonatomic,copy) FinishBlock finishBlock;
@property (nonatomic,copy) FinishBlock successBlock;

@property (nonatomic,copy) MultipartBlock multipartBlock;
@property (nonatomic,copy) ProgressBlock progressBlock;

@property (nonatomic,copy) InterceptorBlock interceptorBlock;

@property (nonatomic,strong) NSObject *params;//执行http请求时传的参数
@property (nonatomic,strong) NSArray *successCodeArray;//作用：用来判断返回结果是否是成功的结果，优先级高于successCodes方法
@property (nonatomic,weak) UIView *loadOnView; //显示loading提示的容器
@property (nonatomic,weak) UIView *errOnView;//显示错误信息的toast容器

@property (nonatomic,assign) TCHttpMethod httpMethod;//HTTP请求的method，默认post,因为post最常用
@property (nonatomic,assign) Class parseModelClass;//解析的返回数据中的model对应的class，当解析的返回数据为数组时，对应数组内的对象类型
@property (nonatomic,assign) BOOL isParseArray;//解析的返回数据是否为数组
@property (nonatomic,copy) NSString *parseKey;//解析的返回数据取值的key
@property (nonatomic,assign) NSTimeInterval limitRequestInterval;//限制相同请求的间隔时间
@property (nonatomic,assign) TCHttpCancelType cancelRequestType;//自动取消http请求的条件类型，默认不自动取消

@property (nonatomic,assign) TCToastStyle toastStyle;//提示框颜色，默认是随UIUserInterfaceStyle变换。

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

-(TCBaseApi * (^)(UIView *l_loadOnView))l_loadOnView {
    return ^(UIView * l_loadOnView){
        return self.l_loadOnView_errOnView(l_loadOnView,l_loadOnView);
    };
}

-(TCBaseApi * (^)(UIView *, UIView *))l_loadOnView_errOnView {
    return ^(UIView * l_loadOnView,UIView * l_errOnView){
        self.loadOnView = l_loadOnView;
        self.errOnView = l_errOnView;
        return self;
    };
}

-(TCBaseApi * (^)(TCToastStyle))l_toastStyle {
    return ^(TCToastStyle l_toastStyle){
        self.toastStyle = l_toastStyle;
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

-(TCBaseApi * (^)(ProgressBlock))l_progressBlock {
    return ^(ProgressBlock l_progressBlock){
        self.progressBlock = l_progressBlock;
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

-(TCBaseApi * (^)(NSTimeInterval))l_limitRequestInterval {
    return ^(NSTimeInterval l_limitRequestInterval){
        self.limitRequestInterval = l_limitRequestInterval;
        return self;
    };
}

-(TCBaseApi * (^)(TCHttpCancelType))l_cancelRequestType {
    return ^(TCHttpCancelType l_cancelRequestType){
        self.cancelRequestType = l_cancelRequestType;
        return self;
    };
}

-(TCBaseApi * (^)(Class))l_parseModelClass {
    return ^(Class l_clazz){
        return self.l_parseModelClass_parseKey(l_clazz,nil);
    };
}

-(TCBaseApi * (^)(Class,NSString *))l_parseModelClass_parseKey {
    return ^(Class l_clazz,NSString *l_parseKey){
        return self.l_parseModelClass_parseKey_isArray(l_clazz,l_parseKey,NO);
    };
}

-(TCBaseApi * (^)(Class,BOOL))l_parseModelClass_isArray {
    return ^(Class l_clazz,BOOL l_isArray){
        return self.l_parseModelClass_parseKey_isArray(l_clazz,nil,l_isArray);
    };
}

-(TCBaseApi * (^)(Class,NSString *,BOOL))l_parseModelClass_parseKey_isArray {
    return ^(Class l_clazz,NSString * l_parseKey,BOOL l_isArray){
        self.parseModelClass = l_clazz;
        self.parseKey = l_parseKey;
        self.isParseArray = l_isArray;
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
    _resultParseObject = nil;
    
    _code = nil;
    _msg = nil;
    _time = nil;
}

//model解析
- (void)parseResult {
    NSString *fullKey = [TCParseResult generateFullParseKey:[self dataObjectKey] parseKey:self.parseKey];;
    TCParseResult *model = [TCParseResult parseObject:self.response
                                         fullParseKey:fullKey
                                                clazz:self.parseModelClass
                                        isResultArray:self.isParseArray
                                             parseEnd:nil];
    _resultParseObject = model.parseResult;
    if (model.error) {
        [TCParseResult printDebugLog:model.error.localizedDescription];
    }
    self.isParseArray = model.isFinalResultArray;
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
    
    Class clazz = self.propertyExtensionClass;
    if (clazz && [self isKindOfClass:clazz] && ![clazz isMemberOfClass:TCBaseApi.class]) {
        //对扩展的属性进行赋值
        unsigned int count;
        objc_property_t *propertyList = class_copyPropertyList(clazz, &count);
        for (unsigned int i = 0; i < count; i++) {
            const char *propertyName = property_getName(propertyList[i]);
            NSString *pName = [NSString stringWithUTF8String:propertyName];
            NSObject *value = response[pName];
            [self setValue:value forKey:pName];
            if (self.printLog) {
                NSLog(@"扩展的属性：(%d) : %@  赋值：%@", i, pName, value.description);
            }
        }
        free(propertyList);
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

    //model解析
    [self parseResult];
    
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
    
    if (self.errOnView) {
        if (!_code.isNonEmpty && [error isKindOfClass:NSError.class]) {
            _code = [@(error.code) stringValue];
        }
        if (_code.isNonEmpty &&  [self isContainsCode:_code arr:self.ignoreErrToastCodes]) {
            if (self.printLog) {
                NSLog(@"忽略了一个错误提示:  %@", _code);
            }
        } else {
            NSString *errMsg = nil;
            if ([error isKindOfClass:NSString.class]) {
                errMsg = (id)error;
            } else if ([error isKindOfClass:NSError.class]){
                errMsg = error.localizedDescription;
            }
            if (![self showCustomTost:self.errOnView text:errMsg]) {
                [self.errOnView toastWithText:errMsg](self.toastStyle);
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

//如果有特殊需求，也可以在子类中重写此方法，返回error，来限制http请求
- (NSError *)checkLimitRequestWithParams:(NSDictionary *)params {
    //判断请求时间间隔的限制
    if (self.limitRequestInterval > 0) {
        static NSMutableDictionary *limitDic = nil;
        if (!limitDic) {
            limitDic = [NSMutableDictionary dictionary];
        }
        NSTimeInterval currentTime = CACurrentMediaTime();
        NSString *paramStr = [NSString stringWithFormat:@"%@:%@",self.URLFull,params];
        NSString *keyStr = paramStr.md5HexLower;
        NSNumber *lastTime = limitDic[keyStr];
        if (lastTime && currentTime - lastTime.doubleValue < self.limitRequestInterval) {
            //限制
            if (self.printLog) {
                NSLog(@"%@秒内的重复请求已被忽略：%@\n%@",@(self.limitRequestInterval),keyStr,paramStr);
            }
            return [NSError errorCode:@"-999" msg:@"请求过于频繁，已取消"];
        } else {
            //不限制
            if (limitDic.allKeys.count>100) {
                [limitDic removeAllObjects];
            }
            [limitDic setValue:@(currentTime) forKey:keyStr];
        }
    }
    return nil;
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
    
    //处理请求参数
    if (!self.params) {
        self.params = [NSMutableDictionary dictionary];
    }
    NSObject *postParams = [self.params mutableCopy];
    [self configRequestParams:postParams];

    err = [self checkLimitRequestWithParams:(id)postParams];
    if (err) {
        [self handleError:err];
        return;
    }
    
    if (self.loadOnView) {
        if (![self showCustomTostLoading:self.loadOnView]) {
            [self.loadOnView toastLoading](self.toastStyle);
        }
    }
    
    _isRequesting = YES;
    
    [self configHttpManager:[TCHttpManager sharedAFManager]];
        
    //下面的block中需要用self，延长实例生命周期
    void (^success)(NSURLSessionDataTask *, id) = ^(NSURLSessionDataTask *task, id response) {
        [self handleResponse:response];
    };
    void (^failure)(NSURLSessionDataTask *, NSError *) = ^(NSURLSessionDataTask *task, NSError *error) {
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
                                                 progress:self.progressBlock
                                                  success:success
                                                  failure:failure];
    } else {
        switch (self.httpMethod) {
            case TCHttp_POST:
                _httpTask = [[TCHttpManager sharedAFManager] POST:self.URLFull
                                                       parameters:postParams
                                                          headers:headers
                                                         progress:self.progressBlock
                                                          success:success
                                                          failure:failure];
                break;
            case TCHttp_GET:
                _httpTask = [[TCHttpManager sharedAFManager] GET:self.URLFull
                                                      parameters:postParams
                                                         headers:headers
                                                        progress:self.progressBlock
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
                void (^hpSuccess)(NSURLSessionDataTask *) = ^(NSURLSessionDataTask *task) {
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
        NSLog(@"Request header: %@\n path: %@\n params: %@",_httpTask.originalRequest.allHTTPHeaderFields, self.URLFull, postParams);
    }
}

- (void)autoCancelTask {
    //调用http请求的发起者对象销毁后，取消未完成的http请求
    if ([self.delegate isKindOfClass:[NSObject class]]) {
        __weak typeof(self) weakSelf = self;
        [self.delegate aspect_hookSelector:NSSelectorFromString(@"dealloc") withOptions:AspectPositionBefore usingBlock:^(id<AspectInfo> aspectInfo) {
            if (weakSelf.httpTask && weakSelf.httpTask.state != NSURLSessionTaskStateCompleted) {
                [weakSelf.httpTask cancel];
                if (weakSelf.printLog) {
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

- (Class)propertyExtensionClass {
    return nil;
}

- (NSError *)requestFinish:(TCBaseApi *)api {
    return nil;
}

@end
