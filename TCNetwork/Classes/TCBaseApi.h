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
typedef void (^SuccessVoidBlock) (void);//success 回调不带参数，减少代码量
typedef void (^FinishBlock) (id response,NSError * error);
typedef void (^NetWorkBlock) (BOOL netConnetState);  //暂时未使用
typedef NSError * (^InterceptorBlock) (id response);  //接口返回成功数据处理拦截器

typedef void (^MultipartBlock) (id<AFMultipartFormData> formData);      //上传文件使用
typedef void (^UploadProgressBlock) (NSProgress *uploadProgress);       //对应post请求
typedef void (^DownloadProgressBlock) (NSProgress *downloadProgress);   //对应get请求



@interface TCBaseApi : NSObject

@property (nonatomic,copy) NSString *URLFull;
@property (nonatomic,copy) SuccessBlock successBlock;
@property (nonatomic,copy) SuccessVoidBlock successVoidBlock;
@property (nonatomic,copy) FinishBlock finishBlock;
@property (nonatomic,copy) FinishBlock originalFinishBlock;//直接返回http请求返回的原始的response和error，优先级高于以上3个block

@property (nonatomic,copy) MultipartBlock multipartBlock;
@property (nonatomic,copy) UploadProgressBlock uploadProgressBlock;
@property (nonatomic,copy) DownloadProgressBlock downloadProgressBlock;

@property (nonatomic,copy) InterceptorBlock interceptorBlock;

@property (nonatomic,strong) NSMutableDictionary *params;
@property (nonatomic,assign) NSUInteger filesCount;//作用：当同时上传多张图片时，可能需要设置更长的超时时间
@property (nonatomic,strong) NSArray *successCodeArray;//作用：用来判断返回结果是否是成功的结果，优先级高于successCodes方法
@property (nonatomic,weak) id delegate;
@property (nonatomic,weak) UIView *loadOnView;
@property (nonatomic,assign) BOOL isShowErr;//发生错误时，是否显示toast提示,默认YES,即显示错误提示
@property (nonatomic,assign) TCHttpMethod httpMethod;//HTTP请求的method，默认post,因为post最常用


@property (nonatomic,readonly) NSURLSessionDataTask *httpTask;
@property (nonatomic,readonly) BOOL isRequesting;//是否正在请求中
@property (nonatomic,readonly) id httpResponseObject;//http返回的原始数据
@property (nonatomic,readonly) id httpResultDataObject;//http返回数据中的data对象
@property (nonatomic,readonly) id httpResultOtherObject;//http返回数据中的其他对象
@property (nonatomic,readonly) NSError *httpError;
@property (nonatomic,readonly) NSString *code;
@property (nonatomic,readonly) NSString *message;
@property (nonatomic,readonly) NSString *currenttime;


//类方法，拼接URL
+ (NSString * (^)(NSString *,...))joinURL;

//初始化
+(TCBaseApi * (^)(NSString *))apiInitURLFull;

//参数设置
-(TCBaseApi * (^)(UIView *))l_loadOnView;
-(TCBaseApi * (^)(UIView *, BOOL))l_loadOnView_isShowErr;
-(TCBaseApi * (^)(id delegate))l_delegate;
-(TCBaseApi * (^)(NSMutableDictionary *))l_params;

//作用：当同时上传多张图片时，可能需要设置更长的超时时间
-(TCBaseApi * (^)(NSUInteger))l_filesCount;

//自定义判定成功结果的code数组，优先级高于successCodes方法
-(TCBaseApi * (^)(NSArray *))l_successCodeArray;

-(TCBaseApi * (^)(MultipartBlock))l_multipartBlock;
-(TCBaseApi * (^)(UploadProgressBlock))l_uploadProgressBlock;
-(TCBaseApi * (^)(DownloadProgressBlock))l_downloadProgressBlock;

-(TCBaseApi * (^)(InterceptorBlock))l_interceptorBlock;

//设置http请求的method,不设置的话，默认是post
-(TCBaseApi * (^)(TCHttpMethod method))l_httpMethod;


//执行请求

//需要接受http返回的原始数据，调用此方法
-(TCBaseApi * (^)(FinishBlock))apiCallOriginal;

//返回的response结果是httpResultDataObject
-(TCBaseApi * (^)(FinishBlock))apiCall;

//返回的response结果是httpResultDataObject
-(TCBaseApi * (^)(SuccessBlock))apiCallSuccess;

-(TCBaseApi * (^)(SuccessVoidBlock))apiCallSuccessVoid;






//不重写的话，使用我的默认样式
- (BOOL)customTost:(UIView *)onView text:(NSString *)text;
//自定义数据加载中的提示框样式
- (BOOL)customTostLoading:(UIView *)onView;
//隐藏Loading提示框
- (BOOL)customTostHide:(UIView *)onView;


//默认情况只在debug模式下打印日志，可在子类中重写此方法，来控制日志的打印
- (BOOL)printLog;

//发起请求前，检查是否有请求权限，比如没有网络等情况下，可以不进行请求
- (NSError *)checkHttpCanRequest;

//通常情况下需要重写，设置header的统一设置
- (void)configHttpManager:(AFHTTPSessionManager *)manager;

//可重写该方法，然后对params进行签名加密等配置
- (void)configRequestParams:(NSMutableDictionary *)params;


//以下方法，子类重写，以便适应自己的后台数据
- (NSString *)codeKey;

- (NSString *)messageKey;

- (NSString *)currenttimeKey;

- (NSString *)dataObjectKey;

- (NSString *)otherObjectKey;

//自定义判定成功结果的code数组,优先级低于successCodeArray和l_successCodeArray
- (NSArray *)successCodes;

//忽略错误提示信息的code数组，某些请求失败后，不想显示提示信息
- (NSArray *)ignoreErrToastCodes;

@end
