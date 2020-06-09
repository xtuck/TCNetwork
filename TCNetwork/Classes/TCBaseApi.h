//
//  TCBaseApi.h
//
//  Created by xtuck on 2017/12/14.
//  Copyright © 2017年 xtuck. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "TCHttpManager.h"
#import "NSMutableDictionary+paramsSet.h"
#import "UIView+TCToast.h"
#import "NSError+TCHelp.h"
#import "NSString+TCHelp.h"


typedef NS_ENUM(NSUInteger, TCHttpMethod) {
    TCHttp_POST = 0,
    TCHttp_GET,
    TCHttp_PUT,
    TCHttp_DELETE,
    TCHttp_HEAD,
    TCHttp_PATCH,
};

typedef void (^SuccessBlock) (id response);
typedef void (^FinishBlock) (id response,NSError *error);
typedef NSError * (^InterceptorBlock) (id response);  //接口返回成功数据处理拦截器

typedef void (^MultipartBlock) (id<AFMultipartFormData> formData);      //上传文件使用
typedef void (^UploadProgressBlock) (NSProgress *uploadProgress);       //对应post请求
typedef void (^DownloadProgressBlock) (NSProgress *downloadProgress);   //对应get请求


@interface TCBaseApi : NSObject


@property (nonatomic,readonly) NSURLSessionDataTask *httpTask;//执行请求的task
@property (nonatomic,readonly) BOOL isRequesting;//是否正在请求中

@property (nonatomic,readonly) id httpResponseObject;//http返回的原始数据
@property (nonatomic,readonly) NSError *httpError;

@property (nonatomic,readonly) id httpResultDataObject;//http返回数据中的data对象
@property (nonatomic,readonly) id httpResultOtherObject;//http返回数据中的其他对象，预留的拓展属性，一般不用

@property (nonatomic,readonly) NSString *code;
@property (nonatomic,readonly) NSString *message;
@property (nonatomic,readonly) NSString *currenttime;


/// 初始化，传入拼接好的url。（推荐）
+(TCBaseApi * (^)(NSString *))apiInitURLFull;

/// 传入url各个组成部分，最后的参数需要传nil。避免使用者忘记传nil。
+(TCBaseApi * (^)(NSString *,...))apiInitURLJoin;

///承载loading的view
-(TCBaseApi * (^)(UIView *))l_loadOnView;

/// 参数1：承载loading的view， 参数2:发生错误时，是否toast显示错误提示信息
-(TCBaseApi * (^)(UIView *, BOOL))l_loadOnView_isShowErr;
-(TCBaseApi * (^)(id delegate))l_delegate;
-(TCBaseApi * (^)(NSObject *))l_params;

///自定义判定成功结果的code数组，优先级高于successCodes方法
///作用：当你把多个接口写在同一个接口类里面的时候，各个接口可能有不同的判断成功的code
-(TCBaseApi * (^)(NSArray *))l_successCodeArray;

-(TCBaseApi * (^)(MultipartBlock))l_multipartBlock;
-(TCBaseApi * (^)(UploadProgressBlock))l_uploadProgressBlock;
-(TCBaseApi * (^)(DownloadProgressBlock))l_downloadProgressBlock;

-(TCBaseApi * (^)(InterceptorBlock))l_interceptorBlock;

///设置http请求的method,不设置的话，默认是post
-(TCBaseApi * (^)(TCHttpMethod method))l_httpMethod;


//执行请求，请放在链式语法的最末尾

/// 需要接受http返回的原始数据，调用此方法。
/// ************** 解析时，只会对 httpResponseObject 和 httpError 赋值 **************
-(TCBaseApi * (^)(FinishBlock))apiCallOriginal;

///返回的response结果是httpResultDataObject
-(TCBaseApi * (^)(FinishBlock))apiCall;

///返回的response结果是httpResultDataObject
-(TCBaseApi * (^)(SuccessBlock))apiCallSuccess;




///不重写的话，使用默认样式
- (BOOL)showCustomTost:(UIView *)onView text:(NSString *)text;
///自定义数据加载中的提示框样式
- (BOOL)showCustomTostLoading:(UIView *)onView;
///隐藏Loading提示框
- (BOOL)hideCustomTost:(UIView *)onView;


///默认情况只在debug模式下打印日志，可在子类中重写此方法，来控制日志的打印
- (BOOL)printLog;

///发起请求前，检查是否有请求权限，比如没有网络等情况下，可以不进行请求，可子类重写进行控制
- (NSError *)checkHttpCanRequest;

/// 通常情况下需要重写，设置header的统一设置
/// 提示：当同时上传多张图片或其他文件时，可能需要设置更长的超时时间
/// @param manager manager单例
- (void)configHttpManager:(AFHTTPSessionManager *)manager;

/// 可重写该方法，然后对params进行签名加密等配置，或者其他公用设置
/// params类型与设置参数时传入的类型是一致的
/// 通过mutableCopy传入子类的为可变类型对象:NSMutableDictionary，NSMutableString，NSMutableData
/// 所以不可以改变params对象的内存地址，即不要新建对象
/// @param params 发起请求时的参数，即对应的http的body数据
- (void)configRequestParams:(NSObject *)params;

/// 自AFNetworking 4.0后，请求参数中可以传入headers了，
/// 也可以继续沿用旧版本对manager进行设置headers，复写configHttpManager:方法进行设置
/// @param headers request请求的headers设置
- (void)configRequestHeaders:(NSMutableDictionary *)headers;


/// 以下方法，子类重写，以便适配自己的后台返回的数据
- (NSString *)codeKey;

- (NSString *)messageKey;

- (NSString *)currenttimeKey;

- (NSString *)dataObjectKey;

- (NSString *)otherObjectKey;

///自定义判定成功结果的code数组,优先级低于successCodeArray和l_successCodeArray
- (NSArray *)successCodes;

///忽略错误提示信息的code数组，某些请求失败后，不想toast显示提示信息
- (NSArray *)ignoreErrToastCodes;

@end
