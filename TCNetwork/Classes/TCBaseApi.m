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
@property (nonatomic,weak) UIView *loadOnView;
@property (nonatomic,assign) BOOL isShowErr;//发生错误时，是否显示toast提示
@property (nonatomic,assign) TCHttpMethod httpMethod;//HTTP请求的method，默认post,因为post最常用
@property (nonatomic,assign) Class parseModelClass;//解析的返回数据中的model对应的class，当解析的返回数据为数组时，对应数组内的对象类型
@property (nonatomic,assign) BOOL isParseArray;//解析的返回数据是否为数组
@property (nonatomic,copy) NSString *parseKey;//解析的返回数据取值的key
@property (nonatomic,assign) NSTimeInterval limitRequestInterval;//限制相同请求的间隔时间
@property (nonatomic,assign) TCToastStype toastStype;//提示框颜色，默认是白色，支持暗黑模式变换。

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

-(TCBaseApi * (^)(TCToastStype))l_toastStype {
    return ^(TCToastStype l_toastStype){
        self.toastStype = l_toastStype;
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

- (void)printDebugLog:(NSString *)log {
#if DEBUG
    NSLog(@"%@",log);
#endif
}

//model解析
//MARK:可以修改为通用的方法parseResult:cls key:key isArr:isArr 待后期完善
- (void)parseResult {
    _resultParseObject = nil;
    NSObject *parseObj = nil;
    if (!self.parseKey.isNonEmpty) {
        parseObj = [_dataObject copy];
    } else {
        if (!self.isParseArray && [self.parseKey hasSuffix:@")"]) {
            //如果parseKey最末尾是通过(x,y)来取值，则会强制将isParseArray变为YES
            self.isParseArray = YES;
            [self printDebugLog:[NSString stringWithFormat:@"parseKey:%@ 最末尾是通过(x,y)来取值,所以强制将isParseArray变为YES",self.parseKey]];
        }

        NSDictionary *resultDic = nil;
        NSMutableArray *keys = [NSMutableArray array];
        NSString *tempParseKey = self.parseKey;
        if ([tempParseKey hasPrefix:@"."]) {
            if ([self dataObjectKey].isNonEmpty) {
                resultDic = [_dataObject copy];
            }
            tempParseKey = [tempParseKey substringFromIndex:1];
        } else {
            resultDic = [_response copy];
        }
        [keys addObjectsFromArray:[tempParseKey componentsSeparatedByString:@"."]];
        
        for (NSString *pKey in keys) {
            //判断是否是数组取值:下标取值[0]和区间取值range(0,1),支持多维取值
            NSUInteger start = [pKey rangeOfString:@"["].location;
            NSUInteger start2 = [pKey rangeOfString:@"("].location;
            NSString *indexsKey = nil;
            if (start == NSNotFound && start2 == NSNotFound) {
                if ([resultDic isKindOfClass:NSDictionary.class]) {
                    resultDic = resultDic[pKey];
                }
                continue;
            } else {
                NSUInteger mStart = start < start2 ? start : start2;
                indexsKey = [pKey substringFromIndex:mStart];
                NSString *pKeyNew = [pKey substringToIndex:mStart];
                if (pKeyNew.isNonEmpty) {
                    resultDic = resultDic[pKeyNew];
                }
            }
            //例："[0](1,2)(1,2)[3][4](3,4)" -> "0","(1,2)(1,2)3","4","(3,4)" -> "0","1,2","1,2","3","4","3,4"
            if (indexsKey.isNonEmpty) {
                NSMutableArray *indexsArray = [NSMutableArray array];
                NSArray *cmps = [[indexsKey stringByReplacingOccurrencesOfString:@"[" withString:@""] componentsSeparatedByString:@"]"];
                for (NSString *subcmps in cmps) {
                    if (subcmps.isNonEmpty) {
                        NSArray *cmps2 = [[subcmps stringByReplacingOccurrencesOfString:@"(" withString:@""] componentsSeparatedByString:@")"];
                        for (NSString *subcmps2 in cmps2) {
                            if (subcmps2.isNonEmpty) {
                                [indexsArray addObject:subcmps2];
                            }
                        }
                    }
                }
                for (NSString *indexStr in indexsArray) {
                    if (![resultDic isKindOfClass:NSArray.class]) {
                        [self printDebugLog:[NSString stringWithFormat:@"数组类型不匹配%@: %@",self.parseKey,indexsKey]];
                        return;
                    }
                    NSRange rang = NSMakeRange(0, 1);
                    NSUInteger comma = [indexStr rangeOfString:@","].location;
                    if (comma != NSNotFound) {
                        NSString *loc = [indexStr substringToIndex:comma];
                        rang.location = loc.integerValue > 0 ? loc.integerValue : 0;
                        NSString *len = [indexStr substringFromIndex:comma+1];
                        rang.length = len.integerValue > 0 ? len.integerValue : 0;
                    } else {
                        rang.location = indexStr.integerValue > 0 ? indexStr.integerValue : 0;
                    }
                    NSArray *resArray = (NSArray *)resultDic;
                    if (rang.location >= resArray.count) {
                        [self printDebugLog:[NSString stringWithFormat:@"数组取值越界%@: %@",self.parseKey,indexsKey]];
                        return;
                    }
                    if (comma != NSNotFound) {
                        if (rang.length == 0 || rang.location + rang.length > resArray.count) {
                            rang.length = resArray.count - rang.location;
                        }
                        resultDic = (id)[resArray subarrayWithRange:rang];
                    } else {
                        resultDic = [resArray objectAtIndex:rang.location];
                    }
                }
            }
        }
        parseObj = resultDic;
    }
    
    if (!parseObj) {
        return;
    }
    if (self.parseModelClass) {
        SEL isCustomClassSel = NSSelectorFromString(@"__isCustomClass:");;
        if ([self respondsToSelector:isCustomClassSel]) {
            IMP imp = [self methodForSelector:isCustomClassSel];
            BOOL (*func)(id, SEL, id) = (void *)imp;
            BOOL isCustomClass = func(self, isCustomClassSel,self.parseModelClass);
            if (!isCustomClass) {
                _resultParseObject = parseObj;
                [self printDebugLog:@"传入的parseModelClass不是自定义的model，resultParseObject将赋值为原始数据"];
                return;
            }
        }
        SEL modelSel = nil;
        if (self.isParseArray) {
            modelSel = NSSelectorFromString(@"tc_arrayOfModelsFromKeyValues:error:");
        } else {
            modelSel = NSSelectorFromString(@"tc_modelFromKeyValues:error:");
        }
        NSError *err = nil;
        if ([self.parseModelClass respondsToSelector:modelSel]) {
            IMP imp = [self.parseModelClass methodForSelector:modelSel];
            NSObject *(*func)(id, SEL, id, NSError**) = (void *)imp;
            _resultParseObject = func(self.parseModelClass, modelSel, parseObj, &err);
        } else {
            err = [NSError errorCode:@"-14562" msg:@"请添加：pod 'TCJSONModel' 进行model转换"];
        }
        if (err) {
            [self printDebugLog:err.localizedDescription];
        }
    } else {
        _resultParseObject = parseObj;
    }
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
    //容错处理，避免外部调用array的方法时崩溃
    if (self.isParseArray && ![_resultParseObject isKindOfClass:NSArray.class]) {
        _resultParseObject = nil;
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
            UIView *toastView = self.loadOnView ? : UIView.appWindow;
            if (![self showCustomTost:toastView text:errMsg]) {
                [toastView toastWithText:errMsg](self.toastStype);
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
            [self.loadOnView toastLoading](self.toastStype);
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
