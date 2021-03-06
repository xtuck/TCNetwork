//
//  TCBaseApi.m
//
//  Created by xtuck on 2017/12/14.
//  Copyright © 2017年 xtuck. All rights reserved.
//

#import "TCBaseApi.h"
#import <Aspects/Aspects.h>
#import <objc/runtime.h>
#import "TCApiHelper.h"

static const char * kTCCancelHttpTaskKey;

@interface TCBaseApi()

@property (nonatomic,copy) FinishBlock originalFinishBlock;
@property (nonatomic,copy) FinishBlock finishBlock;
@property (nonatomic,copy) FinishBlock successBlock;

@property (nonatomic,copy) MultipartBlock multipartBlock;
@property (nonatomic,copy) ProgressBlock progressBlock;

@property (nonatomic,copy) InterceptorBlock successResultInterceptorBlock;

@property (nonatomic,copy) ConfigHttpManagerBlock configHttpManagerBlock;
@property (nonatomic,copy) ConfigHttpHeaderBlock configHttpHeaderBlock;

@property (nonatomic,copy) InterceptorBlock requestFinishBlock;
@property (nonatomic,copy) DeformResponseBlock deformResponseBlock;

@property (nonatomic,weak) TCBaseApi *weakApi;//通过finishBlock回传给http请求的调用者

@property (nonatomic,strong) NSMutableArray *parseResultArray;//存储解析结果的数组，resultParseObject为数组中的第一个对象的属性值

@property (nonatomic,strong) id<AspectToken> aspectToken;//用来取消钩子

@end

@implementation TCBaseApi


+(TCBaseApi * (^)(NSString *))apiInitURLFull {
    return ^(NSString * apiInitURLFull){
        TCBaseApi *api = [[self.class alloc] init];
        api->_URLFull = apiInitURLFull;
        [api apiDefaultConfig];
        return api;
    };
}

//以下是默认配置
- (void)apiDefaultConfig {
    __weak typeof(self) weakApi = self;
    self.weakApi = weakApi;
    self.toastStyle = UIView.getDefaultStyle;
    self.finishBackQueue = dispatch_get_main_queue();
    self.parseCodeKey = [self codeKey];
    self.parseMsgKey = [self msgKey];
    self.parseTimeKey = [self timeKey];;
    self.parseDataObjectKey = [self dataObjectKey];;
    self.parseOtherObjectKey = [self otherObjectKey];
    self.successCodeArray = [self successCodes];
    self.ignoreErrToastCodeArray = [self ignoreErrToastCodes];
    self.requstTimeoutInterval = kHttpRequestTimeoutInterval;
    
#if DEBUG
    self.printLog = YES;
#endif
    [self apiCustomConfig];
}

/// 子类重写
- (void)apiCustomConfig {
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

+ (void)multiCallApis:(NSArray<TCBaseApi*> *)apis finish:(void(^)(NSArray<TCBaseApi*> *))finish {
    __block NSInteger count = apis.count;
    NSMutableArray *backApis = [apis mutableCopy];//延长apis生命周期
    dispatch_block_t checkEnd = ^{
        @synchronized (backApis) {
            count--;
            if (count<=0) {
                if (finish) {
                    finish(backApis);
                }
                [backApis removeAllObjects];//释放apis
            }
        }
    };

    for (TCBaseApi *api in apis) {
        if (api.apiCallType == TCApiCall_Original) {
            api.apiCallOriginal(^(TCBaseApi *wApi) {
                wApi.originalFinishBlock = nil;
                checkEnd();
            });
        } else {
            api.apiCall(^(TCBaseApi *wApi) {
                wApi.finishBlock = nil;
                checkEnd();
            });
        }
    }
}


- (TCBaseApi * (^)(ConfigBlock))l_customConfigBlock {
    return ^(ConfigBlock l_customConfigBlock){
        if (l_customConfigBlock) {
            l_customConfigBlock(self.weakApi);
        }
        return self;
    };
}

-(TCBaseApi * (^)(UIView *l_loadOnView))l_loadOnView {
    return ^(UIView * l_loadOnView){
        return self.l_loadOnView_errOnView(l_loadOnView,l_loadOnView);
    };
}

-(TCBaseApi * (^)(UIView *, UIView *))l_loadOnView_errOnView {
    return ^(UIView * l_loadOnView,UIView * l_errOnView){
        return self.l_loadOnView_errOnView_loadingText(l_loadOnView,l_errOnView,nil);
    };
}

-(TCBaseApi * (^)(UIView *, UIView *, NSString *))l_loadOnView_errOnView_loadingText {
    return ^(UIView *l_loadOnView,UIView *l_errOnView,NSString *loadingText){
        self.loadOnView = l_loadOnView;
        self.errOnView = l_errOnView;
        self.loadingText = loadingText;
        return self;
    };
}

-(TCBaseApi * (^)(TCToastStyle))l_toastStyle {
    return ^(TCToastStyle l_toastStyle){
        self.toastStyle = l_toastStyle;
        return self;
    };
}

-(TCBaseApi * (^)(TCApiMultiCallType))l_apiCallType {
    return ^(TCApiMultiCallType l_apiCallType){
        self.apiCallType = l_apiCallType;
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
        self->_params = l_params;
        return self;
    };
}

-(TCBaseApi * (^)(NSObject *))l_URLParams {
    return ^(NSObject *l_URLParams){
        self->_URLParams = l_URLParams;
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

-(TCBaseApi * (^)(ConfigHttpManagerBlock))l_configHttpManagerBlock {
    return ^(ConfigHttpManagerBlock l_configHttpManagerBlock){
        self.configHttpManagerBlock = l_configHttpManagerBlock;
        return self;
    };
}

-(TCBaseApi * (^)(ConfigHttpHeaderBlock))l_configHttpHeaderBlock {
    return ^(ConfigHttpHeaderBlock l_configHttpHeaderBlock){
        self.configHttpHeaderBlock = l_configHttpHeaderBlock;
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

-(TCBaseApi * (^)(TCRequstSerializerType))l_requestSerializerType {
    return ^(TCRequstSerializerType l_requestSerializerType){
        self.requstSerializerType = l_requestSerializerType;
        return self;
    };
}

-(TCBaseApi * (^)(NSTimeInterval))l_requestTimeout {
    return ^(NSTimeInterval l_requestTimeout){
        self.requstTimeoutInterval = l_requestTimeout;
        return self;
    };
}

-(TCBaseApi * (^)(TCRequstSerializerType,NSTimeInterval))l_requestSerializerType_timeout {
    return ^(TCRequstSerializerType l_requestSerializerType,NSTimeInterval timeout){
        self.requstSerializerType = l_requestSerializerType;
        self.requstTimeoutInterval = timeout;
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

-(TCBaseApi * (^)(DeformResponseBlock))l_deformResponseBlock {
    return ^(DeformResponseBlock l_deformResponseBlock){
        self.deformResponseBlock = l_deformResponseBlock;
        return self;
    };
}
+(DeformResponseBlock)disableDRB {
    return ^id(id res) {
        return nil;
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
    _originalResponse = nil;
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
    model.apiDelegate = self;
    [self.parseResultArray addObject:model];
}

//model解析
- (void)parseResult:(BOOL)isApiCallOriginal {
    for (int i=0; i<_parseResultArray.count; i++) {
        TCParseResult *model = _parseResultArray[i];
        model.fullParseKey = [TCParseResult generateFullParseKey:isApiCallOriginal ? nil : self.dataObjectKey
                                                        parseKey:model.withoutFlagParseKey];
        model.parseSource = self.response;
        [model parse];
        if (model.error) {
            [TCParseResult printDebugLog:[NSString stringWithFormat:@"errCode:%ld\n%@",(long)model.error.code,model.error.localizedDescription]];
        }
        if (i==0) {
            _resultParseObject = model.parseResult;
        }
    }
}

/**
 处理http返回结果
 @param response http返回结果
 */
- (void)handleResponse:(id)response {
    [self stopLoading];
    if (self.printLog) {
        NSLog(@"Request end:\n Request header: %@\n method: %@\n path: %@\n urlParams: %@\n params: %@\n responseObject: %@",
              self.httpTask.originalRequest.allHTTPHeaderFields, self.httpTask.originalRequest.HTTPMethod,
              self.URLFull, self.URLParams?:@"", self.params ,response);
    }
    _originalResponse = response;
    
    id res = nil;
    if (self.deformResponseBlock) {
        res = self.deformResponseBlock(response);
    } else {
        res = [self deformResponse:response];
    }
    if (res != nil) {
        response = res;
    }
    _response = response;
    
    if (self.originalFinishBlock) {
        //model解析
        [self parseResult:YES];
        [self finishBackThreadExe:^{
            self.originalFinishBlock(self.weakApi);
        }];
        return;
    }
        
    //解析数据
    if (![response isKindOfClass:NSDictionary.class]) {
        [self finishBackThreadExe:^{
            [self handleError:[NSError responseDataFormatError:response]];
        }];
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

    if (self.parseCodeKey.isNonEmpty) {
        _code = response[self.parseCodeKey];
    }
    if ([_code isKindOfClass:NSNumber.class]) {
        //为了统一格式
        _code = [(NSNumber *)_code stringValue];
    }
    if (self.parseMsgKey.isNonEmpty) {
        _msg = response[self.parseMsgKey];
    }
    if (self.parseTimeKey.isNonEmpty) {
        _time = response[self.parseTimeKey];
    }
    if (self.parseDataObjectKey.isNonEmpty) {
        _dataObject = response[self.parseDataObjectKey];
    }
    if (self.parseOtherObjectKey.isNonEmpty) {
        _otherObject = response[self.parseOtherObjectKey];
    }

    //model解析
    [self parseResult:NO];
    
    [self finishBackThreadExe:^{
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
        if(self->_code.isNonEmpty) {
            if ([self isContainsCode:self->_code arr:self.successCodeArray]) {
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
        NSError *error = [NSError responseResultError:self->_code msg:self->_msg];
        [self handleError:error];
    }];
}

- (BOOL)isContainsCode:(NSString *)code arr:(NSArray *)codes {
    if (!code.isNonEmpty) {
        return NO;
    }
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
    _error = error;
    NSString *tempCode = [self fetchErrorCode:error];
    if (!self.barrierType && !self.isBarrierExecuted && [self isContainsCode:tempCode arr:self.barrierErrCodeArray]) {
        TCBaseApi *barrierApi = [self requestBarrier:self.weakApi];
        if (barrierApi) {
            if (self.printLog) {
                NSLog(@"执行接口自动调用逻辑:  %@", tempCode);
            }
            barrierApi->_barrierCode = tempCode;
            if (!barrierApi.barrierType) {
                barrierApi.barrierType = tempCode;
            }
            [TCApiHelper addApi:self barrier:barrierApi.barrierType];
            TCBaseApi *oldBarrierApi = [TCApiHelper fetchBarrier:barrierApi.barrierType];
            if (!oldBarrierApi) {
                [TCApiHelper addApi:barrierApi barrier:barrierApi.barrierType];
                if (barrierApi.apiCallType == TCApiCall_Default) {
                    barrierApi.apiCall(^(TCBaseApi *api){
                        [TCApiHelper finishSuccessed:!api.error barrier:api.barrierType];
                    });
                } else {
                    barrierApi.apiCallOriginal(^(TCBaseApi *api){
                        [TCApiHelper finishSuccessed:!api.error barrier:api.barrierType];
                    });
                }
            }
            return;
        }
    }

    [self stopLoading];
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
            [self toastOnView:self.errOnView text:errMsg action:TCToast_Error];
        }
    }
    if (self.originalFinishBlock) {
        self.originalFinishBlock(self.weakApi);
    } else if (self.finishBlock) {
        self.finishBlock(self.weakApi);
    }
}

- (NSString *)fetchErrorCode:(NSError *)error {
    NSString *tempCode = _code;
    if (!tempCode.isNonEmpty && [error isKindOfClass:NSError.class]) {
        if (error.strCode.isNonEmpty) {
            tempCode = error.strCode;
        } else {
            tempCode = [@(error.code) stringValue];
        }
    }
    return tempCode;
}

- (BOOL)isErrorIgnored {
    NSString *tempCode = [self fetchErrorCode:_error];
    if ([self isContainsCode:tempCode arr:self.ignoreErrToastCodeArray]) {
        if (self.printLog) {
            NSLog(@"忽略了一个错误提示:  %@", tempCode);
        }
        return YES;
    }
    return NO;
}

- (void)stopLoading {
    [self toastOnView:self.loadOnView text:self.loadingText action:TCToast_Hide];
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
        keyStr = [NSString stringWithFormat:@"%@:%@:%@",self.URLFull,self.URLParams?:@"",params];
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
            NSString *keyStr = [NSString stringWithFormat:@"%@:%@:%@",self.URLFull,self.URLParams?:@"",params];
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
        [self finishBackThreadExe:^{
            [self handleError:err];
        }];
        return;
    }
    
    //处理请求参数
    if (!self.params) {
        self->_params = [NSMutableDictionary dictionary];
    }
    NSObject *requestParams = [self.params mutableCopy];
    [self configRequestParams:requestParams];

    err = [self checkLimitRequestWithParams:(id)requestParams];
    if (err) {
        [self finishBackThreadExe:^{
            [self handleError:err];
        }];
        return;
    }
    NSURLSessionDataTask *cancelTask = nil;
    NSString *cancelKey = [self checkCancelRequestWithParams:(id)requestParams cancel:&cancelTask];
            
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
            [self finishBackThreadExe:^{
                self->_error = error;
                NSError *err = nil;
                if (self.requestFinishBlock) {
                    err = self.requestFinishBlock(self.weakApi);
                } else {
                    err = [self requestFinish:self.weakApi];
                }
                [self handleError:err ? : error];
                
                //为了保证接口请求的完成顺序，这里需要放后面
                NSNumber *isByTCCancel = objc_getAssociatedObject(task, &kTCCancelHttpTaskKey);
                if (isByTCCancel.boolValue) {
                    objc_setAssociatedObject(cancelTask, &kTCCancelHttpTaskKey, nil, OBJC_ASSOCIATION_RETAIN_NONATOMIC);
                    if (self.printLog) {
                        NSLog(@"一个请求已被自动取消:%p \n cancelKey:%@",self,cancelKey);
                    }
                    dispatch_semaphore_signal(self.cancelTaskLock);//解锁
                }
            }];
        };
                
        self->_isRequesting = YES;
        
        NSMutableDictionary *headers = [NSMutableDictionary dictionary];
        if (self.configHttpHeaderBlock) {
            self.configHttpHeaderBlock(headers);
        } else {
            [self configRequestHeaders:headers];
        }

        AFHTTPSessionManager *currentHttpManager = self.customHttpManager ? : [self.class HTTPManager];
        @synchronized (currentHttpManager) {
            if (self.configHttpManagerBlock) {
                self.configHttpManagerBlock(currentHttpManager);
            } else {
                [self configHttpManager:currentHttpManager];
            }
            if (self.requstSerializerType == TCRequest_HTTP) {
                if (![currentHttpManager.requestSerializer isMemberOfClass:AFHTTPRequestSerializer.class]) {
                    currentHttpManager.requestSerializer = [AFHTTPRequestSerializer serializer];
                }
            } else {
                if (![currentHttpManager.requestSerializer isMemberOfClass:AFJSONRequestSerializer.class]) {
                    currentHttpManager.requestSerializer = [AFJSONRequestSerializer serializer];
                }
            }
            if (currentHttpManager.requestSerializer.timeoutInterval != self.requstTimeoutInterval) {
                currentHttpManager.requestSerializer.timeoutInterval = self.requstTimeoutInterval;
            }
        }
        
        NSURLSessionDataTask *sTask = nil;
        NSString *requestUrl = (!self.URLParams||!self.URLFull) ? self.URLFull : self.URLFull.urlJoinObj(self.URLParams);
        if (self.multipartBlock) {
            //只有post支持上传文件
            sTask = [currentHttpManager POST:requestUrl
                                  parameters:requestParams
                                     headers:headers
                   constructingBodyWithBlock:self.multipartBlock
                                    progress:self.progressBlock
                                     success:success
                                     failure:failure];
        } else {
            switch (self.httpMethod) {
                case TCHttp_POST:
                    sTask = [currentHttpManager POST:requestUrl
                                          parameters:requestParams
                                             headers:headers
                                            progress:self.progressBlock
                                             success:success
                                             failure:failure];
                    break;
                case TCHttp_GET:
                    sTask = [currentHttpManager GET:requestUrl
                                         parameters:requestParams
                                            headers:headers
                                           progress:self.progressBlock
                                            success:success
                                            failure:failure];
                    break;
                case TCHttp_PUT:
                    sTask = [currentHttpManager PUT:requestUrl
                                         parameters:requestParams
                                            headers:headers
                                            success:success
                                            failure:failure];
                    break;
                case TCHttp_DELETE:
                    sTask = [currentHttpManager DELETE:requestUrl
                                            parameters:requestParams
                                               headers:headers
                                               success:success
                                               failure:failure];
                    break;
                case TCHttp_PATCH:
                    sTask = [currentHttpManager PATCH:requestUrl
                                           parameters:requestParams
                                              headers:headers
                                              success:success
                                              failure:failure];
                    break;
                case TCHttp_HEAD: {
                    void (^hpSuccess)(NSURLSessionDataTask *) = ^(NSURLSessionDataTask *task) {
                        success(task,@"success");
                    };
                    sTask = [currentHttpManager HEAD:requestUrl
                                          parameters:requestParams
                                             headers:headers
                                             success:hpSuccess
                                             failure:failure];
                }
                    break;
                default:
                    //如果method设置错误
                    [self finishBackThreadExe:^{
                        [self handleError:NSError.httpMethodError];
                    }];
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
            NSLog(@"Request begin:\n Request header: %@\n method: %@\n path: %@\n params: %@",
                  self.httpTask.originalRequest.allHTTPHeaderFields,self.httpTask.originalRequest.HTTPMethod,requestUrl,requestParams);
        }
        
        //MBProgressHUD show会耗时10毫秒左右，所以放在后面执行
        [self toastOnView:self.loadOnView text:self.loadingText action:TCToast_Loading];
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

- (void)dealloc {
    if (self.aspectToken) {
        [self.aspectToken remove];
    }
}

- (void)autoCancelTask {
    //调用http请求的发起者对象销毁后，取消未完成的http请求
    if ([self.delegate isKindOfClass:[NSObject class]]) {
        __weak typeof(self) weakSelf = self;
        self.aspectToken = [self.delegate aspect_hookSelector:NSSelectorFromString(@"dealloc")
                                                  withOptions:AspectPositionBefore
                                                   usingBlock:^(id<AspectInfo> aspectInfo) {
            if (weakSelf.httpTask && weakSelf.httpTask.state != NSURLSessionTaskStateCompleted) {
                [weakSelf.httpTask cancel];
                if (weakSelf.printLog) {
                    NSLog(@"取消了一个请求:%@",weakSelf.httpTask.currentRequest.URL.absoluteString);
                }
            }
        } error:nil];
    }
}

- (void)finishBackThreadExe:(dispatch_block_t)block {
    if (!block) {
        return;
    }
    if (self.finishBackQueue) {
        dispatch_async(self.finishBackQueue, ^{
            block();
        });
    } else {
        block();
    }
}

- (void)toastOnView:(UIView *)view text:(NSString *)text action:(TCToastActionType)action {
    if (!view) {
        return;
    }
    [self mainThreadExe:^{
        if ([self respondsToSelector:@selector(customTost:text:action:)]) {
            [self customTost:view text:text action:action];
        } else {
            if (action == TCToast_Loading) {
                [view toastLoadingWithText:text style:self.toastStyle];
            } else if (action == TCToast_Hide) {
                [view toastHide];
            } else {
                [view toastWithText:text style:self.toastStyle];
            }
        }
    }];
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


#pragma mark -----子类可重写

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

- (id)deformResponse:(id)oResponse {
    return nil;
}

- (NSError *)requestFinish:(TCBaseApi *)api {
    return nil;
}

- (TCBaseApi *)requestBarrier:(TCBaseApi *)api {
    return nil;
}

@end
