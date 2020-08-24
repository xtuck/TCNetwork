//
//  TCBaseApi.m
//
//  Created by xtuck on 2017/12/14.
//  Copyright © 2017年 xtuck. All rights reserved.
//

#import "TCBaseApi.h"
#import <Aspects/Aspects.h>
#import <objc/runtime.h>

static const char * kTCCancelHttpTaskKey;

@interface TCBaseApi()

@property (nonatomic,copy) FinishBlock originalFinishBlock;
@property (nonatomic,copy) FinishBlock finishBlock;
@property (nonatomic,copy) FinishBlock successBlock;

@property (nonatomic,copy) MultipartBlock multipartBlock;
@property (nonatomic,copy) ProgressBlock progressBlock;

@property (nonatomic,copy) InterceptorBlock successResultInterceptorBlock;

@property (nonatomic,copy) ConfigHttpManagerBlock configHttpManagerBlock;
@property (nonatomic,copy) InterceptorBlock requestFinishBlock;

@property (nonatomic,strong) NSObject *params;//执行http请求时传的参数

@property (nonatomic,strong) NSArray *successCodeArray;//作用：用来判断返回结果是否是成功的结果，优先级高于successCodes方法
@property (nonatomic,strong) NSArray *ignoreErrToastCodeArray;
@property (nonatomic,strong) NSDictionary *parseKeyMap;
@property (nonatomic,strong) AFHTTPSessionManager *customHttpManager;

@property (nonatomic,weak) UIView *loadOnView; //显示loading提示的容器
@property (nonatomic,weak) UIView *errOnView;//显示错误信息的toast容器

@property (nonatomic,assign) TCHttpMethod httpMethod;//HTTP请求的method，默认post,因为post最常用
@property (nonatomic,assign) NSTimeInterval limitRequestInterval;//限制相同请求的间隔时间
@property (nonatomic,assign) TCHttpCancelType cancelRequestType;//自动取消http请求的条件类型，默认不自动取消

@property (nonatomic,assign) TCToastStyle toastStyle;//提示框颜色，默认是随UIUserInterfaceStyle变换。

@property (nonatomic,weak) TCBaseApi *weakApi;//通过finishBlock回传给http请求的调用者

@property (nonatomic,strong) NSMutableArray *parseResultArray;//存储解析结果的数组，resultParseObject为数组中的第一个对象的属性值

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

-(TCBaseApi * (^)(InterceptorBlock))l_successResultInterceptorBlock {
    return ^(InterceptorBlock l_interceptorBlock){
        self.successResultInterceptorBlock = l_interceptorBlock;
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

-(TCBaseApi * (^)(NSArray *))l_ignoreErrToastCodeArray {
    return ^(NSArray *l_ignoreErrToastCodeArray){
        self.ignoreErrToastCodeArray = l_ignoreErrToastCodeArray;
        return self;
    };
}

-(TCBaseApi * (^)(NSDictionary *))l_parseKeyMap {
    return ^(NSDictionary *l_parseKeyMap){
        self.parseKeyMap = l_parseKeyMap;
        return self;
    };
}

-(TCBaseApi * (^)(ConfigHttpManagerBlock))l_configHttpManagerBlock {
    return ^(ConfigHttpManagerBlock l_configHttpManagerBlock){
        self.configHttpManagerBlock = l_configHttpManagerBlock;
        return self;
    };
}

-(TCBaseApi * (^)(InterceptorBlock))l_requestFinishBlock {
    return ^(InterceptorBlock l_requestFinishBlock){
        self.requestFinishBlock = l_requestFinishBlock;
        return self;
    };
}

-(TCBaseApi * (^)(AFHTTPSessionManager *))l_customHttpManager {
    return ^(AFHTTPSessionManager *l_customHttpManager){
        self.customHttpManager = l_customHttpManager;
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
        [self addParseModelClass:l_clazz parseKey:l_parseKey];
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
    
    for (TCParseResult *model in _parseResultArray) {
        model.error = nil;
        model.parseResult = nil;
    }
}

- (id)getParsedResultWithIndex:(NSUInteger)index err:(NSError **)err {
    return [self getParsedResultWithFlagKey:(id)@(index) err:err];
}

- (id)getParsedResultWithFlagKey:(NSString *)flag err:(NSError **)err {
    if (!flag || !_parseResultArray.count) {
        return nil;
    }
    TCParseResult *model = nil;
    if ([flag isKindOfClass:NSNumber.class]) {
        NSUInteger index = flag.integerValue;
        if (index<_parseResultArray.count) {
            model = _parseResultArray[index];
        }
    } else if (flag.length){
        for (TCParseResult *m in _parseResultArray) {
            if ([m.parseFlag isEqualToString:flag]) {
                model = m;
                break;
            }
        }
    }
    if (err) {
        *err = model.error;
    }
    return model.parseResult;
}

- (NSMutableArray *)parseResultArray {
    if (!_parseResultArray) {
        _parseResultArray = [NSMutableArray array];
    }
    return _parseResultArray;
}

- (void)addParseModelClass:(Class)clazz parseKey:(NSString *)key {
    NSString *flag = nil;
    NSString *tempKey = key;
    if (key.length) {
        NSInteger loc = [key rangeOfString:kParseFlag options:NSBackwardsSearch].location;
        if (loc != NSNotFound) {
            flag = [key substringFromIndex:loc+kParseFlag.length];
            if (!flag.length) {
                flag = kParseFlag;//允许使用kParseFlag作为标记
            }
            for (TCParseResult *m in _parseResultArray) {
                if ([m.parseFlag isEqualToString:flag]) {
                    [TCParseResult printDebugLog:[NSString stringWithFormat:@"需要解析的对象存在相同的flag:%@ 已被忽略",flag]];
                    return;
                }
            }
            tempKey = [key substringToIndex:loc];
        }
    }
    TCParseResult *model = [[TCParseResult alloc] init];
    model.parseModelClass = clazz;
    model.originalParseKey = key;
    model.parseFlag = flag;
    model.withoutFlagParseKey = tempKey;
    [self.parseResultArray addObject:model];
}

//model解析
- (void)parseResult {
    for (int i=0; i<_parseResultArray.count; i++) {
        TCParseResult *model = _parseResultArray[i];
        model.fullParseKey = [TCParseResult generateFullParseKey:[self dataObjectKey] parseKey:model.withoutFlagParseKey];
        model.parseSource = self.response;
        [model parse];
        if (model.error) {
            [TCParseResult printDebugLog:[NSString stringWithFormat:@"errCode:%ld\n%@",model.error.code,model.error.localizedDescription]];
        }
        if (i==0) {
            _resultParseObject = model.parseResult;
        }
    }
}

- (NSString *)getParseKey:(NSString *)defaultKey {
    if (defaultKey.length && self.parseKeyMap.count) {
        return self.parseKeyMap[defaultKey];
    }
    return nil;
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

    NSString *codeKey = [self getParseKey:kDCodeKey]?:[self codeKey];
    if (codeKey.isNonEmpty) {
        _code = response[codeKey];
    }
    if ([_code isKindOfClass:NSNumber.class]) {
        //为了统一格式
        _code = [(NSNumber *)_code stringValue];
    }
    NSString *msgKey = [self getParseKey:kDMsgKey]?:[self msgKey];
    if (msgKey.isNonEmpty) {
        _msg = response[msgKey];
    }
    NSString *timeKey =  [self getParseKey:kDTimeKey]?:[self timeKey];
    if (timeKey.isNonEmpty) {
        _time = response[timeKey];
    }
    NSString *dataObjectKey = [self getParseKey:kDDataKey]?:[self dataObjectKey];
    if (dataObjectKey.isNonEmpty) {
        _dataObject = response[dataObjectKey];
    }
    NSString *otherObjectKey = [self getParseKey:kDOtherKey]?:[self otherObjectKey];
    if (otherObjectKey.isNonEmpty) {
        _otherObject = response[otherObjectKey];
    }

    //model解析
    [self parseResult];
    
    NSError *err = nil;
    if (self.requestFinishBlock) {
        err = self.requestFinishBlock(self.weakApi);
    } else {
        err = [self requestFinish:self.weakApi];
    }
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
        if ([code.lowercaseString isEqualToString:codeStr.lowercaseString]) {
            return YES;
        }
    }
    return NO;
}

- (void)handleSuccess {
    _isRequesting = NO;
    if (self.successResultInterceptorBlock) {
        NSError *error = self.successResultInterceptorBlock(self.weakApi);
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
        if (![self isErrorIgnored]) {
            NSString *errMsg = nil;
            if ([error isKindOfClass:NSString.class]) {
                errMsg = (id)error;
            } else if ([error isKindOfClass:NSError.class]){
                errMsg = error.localizedDescription;
            }
            [self mainThreadExe:^{
                if (![self showCustomTost:self.errOnView text:errMsg]) {
                    [self.errOnView toastWithText:errMsg](self.toastStyle);
                }
            }];
        }
    }
    
    if (self.originalFinishBlock) {
        self.originalFinishBlock(self.weakApi);
    } else if (self.finishBlock) {
        self.finishBlock(self.weakApi);
    }
}

- (BOOL)isErrorIgnored {
    NSString *tempCode = _code;
    if (!tempCode.isNonEmpty && [_error isKindOfClass:NSError.class]) {
        tempCode = [@(_error.code) stringValue];
    }
    NSArray *codes = self.ignoreErrToastCodeArray.count ? self.ignoreErrToastCodeArray : [self ignoreErrToastCodes];
    if (tempCode.isNonEmpty && [self isContainsCode:tempCode arr:codes]) {
        if (self.printLog) {
            NSLog(@"忽略了一个错误提示:  %@", tempCode);
        }
        return YES;
    }
    return NO;
}

- (void)stopLoading {
    if (self.loadOnView) {
        [self mainThreadExe:^{
            if (![self hideCustomTost:self.loadOnView]) {
                [self.loadOnView toastHide];
            }
        }];
    }
}


- (NSMutableDictionary *)storeTaskDictionary {
    static NSMutableDictionary *taskDictionary = nil;
    if (!taskDictionary) {
        taskDictionary = [NSMutableDictionary dictionary];
    }
    return taskDictionary;
}

- (dispatch_semaphore_t)cancelTaskLock {
    static dispatch_semaphore_t lock;
    if (!lock) {
        lock = dispatch_semaphore_create(0);
    }
    return lock;
}

- (dispatch_queue_t)cancelTaskQueue {
    static dispatch_queue_t queue;
    if (!queue) {
        queue = dispatch_queue_create("com.TCNetwork.cancelTaskQueue", DISPATCH_QUEUE_SERIAL);
    }
    return queue;
}


- (NSString *)cancelTaskKey:(NSDictionary *)params  {
    if (self.cancelRequestType == TCCancelByNone) {
        return nil;
    }
    NSString *keyStr = nil;
    if (self.cancelRequestType == TCCancelByURL) {
        if (!self.URLFull) {
            return nil;
        }
        NSInteger loc = [self.URLFull rangeOfString:@"?"].location;
        if (loc != NSNotFound) {
            keyStr = [self.URLFull substringToIndex:loc];
        } else {
            keyStr = self.URLFull;
        }
    } else if (self.cancelRequestType == TCCancelByURLAndParams){
        keyStr = [NSString stringWithFormat:@"%@:%@",self.URLFull,params];
    }
    return keyStr;
}

- (NSString *)checkCancelRequestWithParams:(NSDictionary *)params cancel:(NSURLSessionDataTask **)cancelTask {
    NSString *keyStr = [self cancelTaskKey:params];
    if (keyStr.length) {
        @synchronized (self.storeTaskDictionary) {
            NSURLSessionDataTask *task = [self.storeTaskDictionary objectForKey:keyStr];
            if (task) {
                [self.storeTaskDictionary removeObjectForKey:keyStr];
                if (task.state != NSURLSessionTaskStateCompleted) {
                    if (cancelTask) {
                        *cancelTask = task;
                    }
                }
            }
        }
    }
    return keyStr;
}

//如果有特殊需求，也可以在子类中重写此方法，返回error，来限制http请求
- (NSError *)checkLimitRequestWithParams:(NSDictionary *)params {
    //判断请求时间间隔的限制
    if (self.limitRequestInterval > 0) {
        static NSMutableDictionary *limitDic = nil;
        if (!limitDic) {
            limitDic = [NSMutableDictionary dictionary];
        }
        @synchronized (limitDic) {
            NSTimeInterval currentTime = CACurrentMediaTime();
            NSString *keyStr = [NSString stringWithFormat:@"%@:%@",self.URLFull,params];
            NSNumber *lastTime = limitDic[keyStr];
            if (lastTime && currentTime - lastTime.doubleValue < self.limitRequestInterval) {
                //限制
                if (self.printLog) {
                    NSLog(@"%@秒内的重复请求已被忽略：%@",@(self.limitRequestInterval),keyStr);
                }
                return [NSError errorCode:(id)@(APIErrorCode_HttpCancel) msg:@"请求过于频繁，已取消"];
            } else {
                //不限制
                if (limitDic.count>100) {
                    [limitDic removeAllObjects];
                }
                [limitDic setValue:@(currentTime) forKey:keyStr];
            }
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
    NSURLSessionDataTask *cancelTask = nil;
    NSString *cancelKey = [self checkCancelRequestWithParams:(id)postParams cancel:&cancelTask];
            
    dispatch_block_t requestBlock = ^{
        void (^removeCancelTask)(NSURLSessionDataTask *) = ^(NSURLSessionDataTask *task) {
            if (cancelKey.length) {
                @synchronized (self.storeTaskDictionary) {
                    NSURLSessionDataTask *lastTask = [self.storeTaskDictionary objectForKey:cancelKey];
                    if (lastTask == task) {
                        [self.storeTaskDictionary removeObjectForKey:cancelKey];
                    }
                }
            }
        };

        //下面的block中需要用self，延长实例生命周期
        void (^success)(NSURLSessionDataTask *, id) = ^(NSURLSessionDataTask *task, id response) {
            removeCancelTask(task);
            [self handleResponse:response];
        };
        void (^failure)(NSURLSessionDataTask *, NSError *) = ^(NSURLSessionDataTask *task, NSError *error) {
            removeCancelTask(task);
            self->_error = error;
            NSError *err = nil;
            if (self.requestFinishBlock) {
                err = self.requestFinishBlock(self.weakApi);
            } else {
                err = [self requestFinish:self.weakApi];
            }
            if (err) {
                [self handleError:err];
            } else {
                [self handleError:error];
            }
            NSNumber *isByTCCancel = objc_getAssociatedObject(task, &kTCCancelHttpTaskKey);
            if (isByTCCancel.boolValue) {
                objc_setAssociatedObject(cancelTask, &kTCCancelHttpTaskKey, nil, OBJC_ASSOCIATION_RETAIN_NONATOMIC);
                if (self.printLog) {
                    NSLog(@"一个请求已被自动取消:%p \n cancelKey:%@",self,cancelKey);
                }
                dispatch_semaphore_signal(self.cancelTaskLock);//解锁
            }
        };
                
        self->_isRequesting = YES;
        
        AFHTTPSessionManager *currentHttpManager = self.customHttpManager ? : [self.class HTTPManager];
        NSMutableDictionary *headers = [NSMutableDictionary dictionary];
        @synchronized (currentHttpManager) {
            if (self.configHttpManagerBlock) {
                self.configHttpManagerBlock(currentHttpManager,headers);
            } else {
                [self configHttpManager:currentHttpManager];
                [self configRequestHeaders:headers];
            }
        }
        
        NSURLSessionDataTask *sTask = nil;
        if (self.multipartBlock) {
            //只有post支持上传文件
            sTask = [currentHttpManager POST:self.URLFull
                                  parameters:postParams
                                     headers:headers
                   constructingBodyWithBlock:self.multipartBlock
                                    progress:self.progressBlock
                                     success:success
                                     failure:failure];
        } else {
            switch (self.httpMethod) {
                case TCHttp_POST:
                    sTask = [currentHttpManager POST:self.URLFull
                                          parameters:postParams
                                             headers:headers
                                            progress:self.progressBlock
                                             success:success
                                             failure:failure];
                    break;
                case TCHttp_GET:
                    sTask = [currentHttpManager GET:self.URLFull
                                         parameters:postParams
                                            headers:headers
                                           progress:self.progressBlock
                                            success:success
                                            failure:failure];
                    break;
                case TCHttp_PUT:
                    sTask = [currentHttpManager PUT:self.URLFull
                                         parameters:postParams
                                            headers:headers
                                            success:success
                                            failure:failure];
                    break;
                case TCHttp_DELETE:
                    sTask = [currentHttpManager DELETE:self.URLFull
                                            parameters:postParams
                                               headers:headers
                                               success:success
                                               failure:failure];
                    break;
                case TCHttp_PATCH:
                    sTask = [currentHttpManager PATCH:self.URLFull
                                           parameters:postParams
                                              headers:headers
                                              success:success
                                              failure:failure];
                    break;
                case TCHttp_HEAD: {
                    void (^hpSuccess)(NSURLSessionDataTask *) = ^(NSURLSessionDataTask *task) {
                        success(task,@"success");
                    };
                    sTask = [currentHttpManager HEAD:self.URLFull
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
        
        self->_httpTask = sTask;
        if (sTask && cancelKey.length) {
            @synchronized (self.storeTaskDictionary) {
                if (self.storeTaskDictionary.count>20) {
                    [self.storeTaskDictionary removeAllObjects];
                }
                [self.storeTaskDictionary setObject:sTask forKey:cancelKey];
            }
        }
        
        [self autoCancelTask];
        
        if (self.printLog) {
            NSLog(@"Request header: %@\n method: %@\n path: %@\n params: %@",
                  self.httpTask.originalRequest.allHTTPHeaderFields, self.httpTask.originalRequest.HTTPMethod, self.URLFull, postParams);
        }
        
        //MBProgressHUD show会耗时10毫秒左右，所以放在后面执行
        if (self.loadOnView) {
            [self mainThreadExe:^{
                if (![self showCustomTostLoading:self.loadOnView]) {
                    [self.loadOnView toastLoading](self.toastStyle);
                }
            }];
        }
    };
    
    if (cancelTask) {
        //存在被取消的请求
        if (self.printLog) {
            NSLog(@"存在被取消的请求:%p \n cancelKey:%@",self,cancelKey);
        }
        objc_setAssociatedObject(cancelTask, &kTCCancelHttpTaskKey, @(YES), OBJC_ASSOCIATION_RETAIN_NONATOMIC);
        [cancelTask cancel]; //取消操作会异步执行failureBlock
        if ([NSThread isMainThread]) {
            dispatch_async(self.cancelTaskQueue, ^{
                dispatch_semaphore_wait(self.cancelTaskLock, DISPATCH_TIME_FOREVER);//加锁
                dispatch_sync(dispatch_get_main_queue(), ^{
                    requestBlock();
                });
            });
        } else {
            dispatch_semaphore_wait(self.cancelTaskLock, DISPATCH_TIME_FOREVER);//加锁
            requestBlock();
        }
    } else {
        requestBlock();
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

- (void)mainThreadExe:(dispatch_block_t)block {
    if (!block) {
        return;
    }
    if ([NSThread isMainThread]) {
        block();
    } else {
        dispatch_async(dispatch_get_main_queue(), ^{
            block();
        });
    }
}


#pragma mark -----子类可重写，进行自定义设置

#pragma mark --是否使用自定义toast
- (BOOL)showCustomTost:(UIView *)errOnView text:(NSString *)errMsg {
    return NO;
}
//自定义数据加载中的提示框样式
- (BOOL)showCustomTostLoading:(UIView *)loadOnView {
    return NO;
}
- (BOOL)hideCustomTost:(UIView *)loadOnView {
    return NO;
}



- (BOOL)printLog {
#if DEBUG
    return YES;
#endif
    return NO;
}


/// 如果对基类的HTTPManager不满意，可以自己在子类中重写
+ (AFHTTPSessionManager *)HTTPManager {
    static AFHTTPSessionManager *manager = nil;
    if (!manager) {
        manager = [AFHTTPSessionManager manager];
        //允许非权威机构颁发的证书
        manager.securityPolicy.allowInvalidCertificates = YES;
        //也不验证域名一致性
        manager.securityPolicy.validatesDomainName = NO;
        manager.requestSerializer.timeoutInterval = kHttpRequestTimeoutInterval;
        manager.responseSerializer.acceptableContentTypes = [NSSet setWithObjects:@"text/plain", @"multipart/form-data", @"application/json",
                                                             @"text/html", @"image/jpeg", @"image/png",
                                                             @"application/octet-stream", @"text/json",@"text/javascript",nil];
    }
    return manager;
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
    return kDCodeKey;
}

- (NSString *)msgKey {
    return kDMsgKey;
}

- (NSString *)timeKey {
    return kDTimeKey;
}

- (NSString *)dataObjectKey {
    return kDDataKey;
}

- (NSString *)otherObjectKey {
    return kDOtherKey;
}

- (NSArray *)successCodes {
    return @[@"1",@"ok",@"yes",@"success"];
}

- (NSArray *)ignoreErrToastCodes {
    //取消请求的错误码是-999
    return @[@(APIErrorCode_HttpCancel)];
}

- (Class)propertyExtensionClass {
    return nil;
}

- (NSError *)requestFinish:(TCBaseApi *)api {
    return nil;
}

@end
