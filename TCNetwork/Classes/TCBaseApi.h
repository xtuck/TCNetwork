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

typedef void (^FinishBlock) (id api);
typedef NSError * (^InterceptorBlock) (id api);  //接口返回成功数据处理拦截器

typedef void (^MultipartBlock) (id<AFMultipartFormData> formData);      //上传文件使用
typedef void (^UploadProgressBlock) (NSProgress *uploadProgress);       //对应post请求
typedef void (^DownloadProgressBlock) (NSProgress *downloadProgress);   //对应get请求


/// 执行http请求的基类，使用时，请继承该类
@interface TCBaseApi : NSObject

///http请求的url
@property (nonatomic,copy,readonly) NSString *URLFull;
///一般为http请求的调用者，作用：对象销毁后，其中的所有http请求都会自动取消
@property (nonatomic,weak,readonly) id delegate;


/// 执行http请求的task
@property (nonatomic,readonly) NSURLSessionDataTask *httpTask;
/// 是否正在请求中
@property (nonatomic,readonly) BOOL isRequesting;

/// http返回的原始数据
@property (nonatomic,readonly) id response;

/// 执行请求前或结束后产生的错误信息,通过判断该属性是否为空，来识别请求结果是否成功
@property (nonatomic,readonly) NSError *error;

/// http返回数据字典中解析出的data对象
@property (nonatomic,readonly) id dataObject;

/// http返回数据字典中解析出的其他对象，预留的拓展属性，一般不用
@property (nonatomic,readonly) id otherObject;

///response中解析出的code
@property (nonatomic,readonly) NSString *code;
///response中解析出的msg
@property (nonatomic,readonly) NSString *msg;
///response中解析出的服务器当前时间
@property (nonatomic,readonly) NSString *time;

///最终解析出的结果：单个对象或者数组
@property (nonatomic,readonly) id resultParseObject;


/// 初始化，传入拼接好的url，使用NSString分类方法 l_joinURL 进行拼接。（推荐）
+(TCBaseApi * (^)(NSString *))apiInitURLFull;

/// 传入url各个组成部分，最后的参数需要传nil。避免使用者忘记传nil。
+(TCBaseApi * (^)(NSString *,...))apiInitURLJoin;

///承载loading的view
-(TCBaseApi * (^)(UIView *))l_loadOnView;
/// 参数1：承载loading的view， 参数2:发生错误时，是否toast显示错误提示信息
-(TCBaseApi * (^)(UIView *, BOOL))l_loadOnView_isShowErr;

-(TCBaseApi * (^)(id delegate))l_delegate;
-(TCBaseApi * (^)(NSObject *))l_params;

/// 自定义判定成功结果的code数组，优先级高于successCodes方法
/// 作用：当你把多个接口写在同一个接口类里面的时候，各个接口可能有不同的判断成功的code
-(TCBaseApi * (^)(NSArray *))l_successCodeArray;

-(TCBaseApi * (^)(MultipartBlock))l_multipartBlock;
-(TCBaseApi * (^)(UploadProgressBlock))l_uploadProgressBlock;
-(TCBaseApi * (^)(DownloadProgressBlock))l_downloadProgressBlock;

-(TCBaseApi * (^)(InterceptorBlock))l_interceptorBlock;

/// 设置http请求的method,不设置的话，默认是post
-(TCBaseApi * (^)(TCHttpMethod method))l_httpMethod;

/// 限制请求的间隔时间，相同接口和相同参数，在间隔时间内重复调用时，后调用的将直接被忽略
-(TCBaseApi * (^)(NSTimeInterval))l_limitRequestInterval;

/// 解析返回数据
/// 参数1:解析结果中的model对应的class(如果是基本类型请传nil)，如果设置为nil，结果将返回response字典中的对应的原始值
/// 参数2:解析时取值的key，如果设置为nil，取的是dataObjectKey对应的key值（例：data）
///      可通过"."进行指定路径，如果开头是“.”,则表示“.”之前的路径为dataObjectKey(例：“.list” = "data.list")
/// 参数3:解析的值是否是数组，通常是列表数据使用较多
-(TCBaseApi * (^)(Class,NSString *,BOOL))l_parseModelClass_parseKey_isArray;
-(TCBaseApi * (^)(Class,NSString *))l_parseModelClass_parseKey;
-(TCBaseApi * (^)(Class,BOOL))l_parseModelClass_isArray;
-(TCBaseApi * (^)(Class))l_parseModelClass;


//执行请求，请放在链式语法的最末尾

/// 需要接受http返回的原始数据，调用此方法。
/// ************** 解析时，只会对 response 和 error 赋值 **************
-(TCBaseApi * (^)(FinishBlock))apiCallOriginal;

/// 回传的结果是当前执行请求的对象TCBaseApi，通过对该api对象的属性error进行判空，来判断是否成功
-(TCBaseApi * (^)(FinishBlock))apiCall;

/// 回传的结果是当前执行请求的对象TCBaseApi，TCBaseApi基类已经做了请求成功的判断
/// 针对某些只处理请求成功情况的请求，简化代码。
-(TCBaseApi * (^)(FinishBlock))apiCallSuccess;



/// 不重写的话，使用默认样式
- (BOOL)showCustomTost:(UIView *)onView text:(NSString *)text;
/// 自定义数据加载中的提示框样式
- (BOOL)showCustomTostLoading:(UIView *)onView;
/// 隐藏Loading提示框
- (BOOL)hideCustomTost:(UIView *)onView;


/// 默认情况只在debug模式下打印日志，可在子类中重写此方法，来控制日志的打印
- (BOOL)printLog;

/// 发起请求前，检查是否有请求权限，比如没有网络等情况下，可以不进行请求，可子类重写进行控制
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

- (NSString *)msgKey;

- (NSString *)timeKey;

- (NSString *)dataObjectKey;

- (NSString *)otherObjectKey;


///自定义判定成功结果的code数组,优先级低于l_successCodeArray(successCodeArray)
- (NSArray *)successCodes;

///忽略错误提示信息的code数组，某些请求失败后，不想toast显示提示信息
- (NSArray *)ignoreErrToastCodes;


/// 请求刚完毕时的结果检查，统一处理特殊业务，子类复写
/// @param api 当前请求的api接口对象,需要用的数据都在该api的属性中
- (NSError *)requestFinish:(TCBaseApi *)api;

@end
