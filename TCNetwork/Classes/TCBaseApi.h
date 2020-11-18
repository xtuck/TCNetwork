//
//  TCBaseApi.h
//
//  Created by xtuck on 2017/12/14.
//  Copyright © 2017年 xtuck. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <AFNetworking/AFNetworking.h>
#import "NSMutableDictionary+paramsSet.h"
#import "UIView+TCToast.h"
#import "NSError+TCHelp.h"
#import "NSString+TCHelp.h"
#import "TCParseResult.h"
#import "TCNetworkHelp.h"

static CGFloat const kHttpRequestTimeoutInterval = 15.0;

typedef NS_ENUM(NSUInteger, TCHttpMethod) {
    TCHttp_POST = 0,
    TCHttp_GET,
    TCHttp_PUT,
    TCHttp_DELETE,
    TCHttp_HEAD,
    TCHttp_PATCH,
};

typedef NS_ENUM(NSUInteger, TCHttpCancelType) {
    TCCancelByNone = 0,
    TCCancelByURL,              //相同的url，重复请求时，未完成的请求将被取消
    TCCancelByURLAndParams,     //相同的url，并且参数相同，重复请求时，未完成的请求将被取消
};

typedef NS_ENUM(NSUInteger, TCApiCallType) {
    TCApiCall_Default,//apiCall
    TCApiCall_Original,//apiCallOriginal
    TCApiCall_Success//apiCallSuccess
};

typedef void (^FinishBlock) (id api);
typedef NSError * (^InterceptorBlock) (id api);  //接口返回成功数据处理拦截器

typedef void (^MultipartBlock) (id<AFMultipartFormData> formData);      //上传文件使用
typedef void (^ProgressBlock) (NSProgress *progress);                   //请求处理进度

typedef void (^ConfigHttpManagerBlock) (AFHTTPSessionManager *manager);
typedef void (^ConfigHttpHeaderBlock) (NSMutableDictionary *headers);

typedef NSDictionary * (^DeformResponseBlock) (id oResponse);//对返回的原始数据进行特殊处理

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
@property (nonatomic,readonly) id originalResponse;

/// http返回的数据:解析中用到的数据，如果中间未经过全局处理，则等于originalResponse
@property (nonatomic,readonly) id response;

/// 执行请求前或结束后产生的错误信息,通过判断该属性是否为空，来识别请求结果是否成功
@property (nonatomic,readonly) NSError *error;

/// http返回数据字典中解析出的data对象 = response[dataObjectKey]
@property (nonatomic,readonly) id dataObject;

/// http返回数据字典中解析出的其他对象 = response[otherObjectKey]
@property (nonatomic,readonly) id otherObject;

///response中解析出的code
@property (nonatomic,readonly) NSString *code;
///response中解析出的msg
@property (nonatomic,readonly) NSString *msg;
///response中解析出的服务器当前时间
@property (nonatomic,readonly) NSString *time;

///最终解析出的结果：单个对象或者数组，如果没有设置parseModelClass_parseKey，默认情况下 = dataObject
@property (nonatomic,readonly) id resultParseObject;


//MARK:- 链式方式设置参数

//MARK:- 初始化
/// 初始化，传入拼接好的url，使用NSString分类方法 l_joinURL 进行拼接。（推荐）
+(TCBaseApi * (^)(NSString *))apiInitURLFull;

/// 传入url各个组成部分，最后的参数需要传nil。避免使用者忘记传nil。
+(TCBaseApi * (^)(NSString *,...))apiInitURLJoin;

//MARK:- toastView相关设置
///承载loading的view，同时也是承载错误信息tosat的view
-(TCBaseApi * (^)(UIView *))l_loadOnView;

/// 参数1：承载loading的view， 参数2:发生错误时，显示错误提示信息的toast所在的view
/// 注意：当在子线程中调用api请求时，如果需要传递ViewController的self.view时，该self.view需要在主线程中调用，
///      拿到对应的view后再传递参数，具体原因，请看ViewController的view属性相关的官方介绍
-(TCBaseApi * (^)(UIView *, UIView *))l_loadOnView_errOnView;

/// toast提示框的颜色样式，默认随暗黑模式切换
-(TCBaseApi * (^)(TCToastStyle))l_toastStyle;


//MARK:- 参数设置

/// 绑定delegate，目的在于delegate销毁时，未完成的请求自动取消
-(TCBaseApi * (^)(id delegate))l_delegate;

/// 设置http请求参数
-(TCBaseApi * (^)(NSObject *))l_params;

/// 上传文件等使用，通过调用<AFMultipartFormData>formData的appendPartWith...方法来上传data
-(TCBaseApi * (^)(MultipartBlock))l_multipartBlock;

/// 通用的请求进度的block
-(TCBaseApi * (^)(ProgressBlock))l_progressBlock;

/// 在解析返回结果之前，对response进行特殊处理，优先级高于deformResponse:,如果return nil，则表示不处理
-(TCBaseApi * (^)(DeformResponseBlock))l_deformResponseBlock;
/// 调用l_deformResponseBlock时，传入TCBaseApi.disableDRB, 简化代码，表示不处理返回结果
+(DeformResponseBlock)disableDRB;

/// 接口返回成功数据处理拦截器,会在apiCall的block执行之前调用，通常用来处理一些通用逻辑。
/// 例如：登录成功后需要存储用户数据，或者进行角色判断，是否允许用户登录。
///      获取用户信息后，需要存储用户数据。这类接口通常是很多个地方调用。
///      同个接口，多个地方调用，可以在interceptorBlock中广播通知，执行通用逻辑。
/// 该block只会在handleSuccess中执行，即解析数据为成功状态，才会执行。
/// 通过返回的error来控制最终的返回结果是成功还是失败
-(TCBaseApi * (^)(InterceptorBlock))l_successResultInterceptorBlock;

/// 设置http请求的method,不设置的话，默认是post
-(TCBaseApi * (^)(TCHttpMethod method))l_httpMethod;

/// 限制请求的间隔时间，相同接口和相同参数，在间隔时间内重复调用时，后调用的将直接被忽略
-(TCBaseApi * (^)(NSTimeInterval))l_limitRequestInterval;

/// 在调用类似于筛选条件的接口时，当筛选条件发生变化时，应该只需要获取最后的筛选条件所请求的结果
/// 所以此时可以将当前请求之前未完成的其他筛选条件的请求取消掉，达到优化网络的效果
-(TCBaseApi * (^)(TCHttpCancelType))l_cancelRequestType;


//MARK:- 解析返回数据的相关参数设置
/// 参数1:解析结果中的model对应的class，如果设置为nil，结果将返回response字典中的对应的原始值
/// 参数2:解析时取值的key，如果设置为nil，取的是dataObjectKey对应的key值（例：data）
///      特殊情况：apiCallOriginal调用请求时，如果key设置为nil，则解析时取的值是response的值
///      通过"."语法进行指定路径(例："data.shop.product")，通过末尾拼接"()"，来指定最终结果是数组
///      如果开头是“#”,则表示起始路径为dataObjectKey(例："#.list" = "data.list"，兼容:"#list" = "#.list")
///      如果开头是“～”或者“.”,则表示起始路径为response的根路径，默认的起始路径即为根路径
///      支持多维数组取值：例：“list[0](1,8)[3](3,4)”, [x]表示数组下标取值，(x,y)表示NSRange取值，兼容:y=0时，表示获取数组x之后的所有值
///      如果key最末尾是通过(x,y)来取值，或者最末尾是"()"，则表示解析的最终结果为数组
-(TCBaseApi * (^)(Class,NSString *))l_parseModelClass_parseKey;
-(TCBaseApi * (^)(Class))l_parseModelClass;


//MARK:- 执行请求，请放在链式语法的最末尾

/// 需要接受http返回的原始数据，调用此方法。
/// ************** 解析时，只会对 response 和 error 赋值 **************
-(TCBaseApi * (^)(FinishBlock))apiCallOriginal;

/// 回传的结果是当前执行请求的对象TCBaseApi，通过对该api对象的属性error进行判空，来判断是否成功
-(TCBaseApi * (^)(FinishBlock))apiCall;

/// 回传的结果是当前执行请求的对象TCBaseApi，TCBaseApi基类已经做了请求成功的判断
/// 针对某些只处理请求成功情况的请求，简化代码。
-(TCBaseApi * (^)(FinishBlock))apiCallSuccess;


//MARK:- 多请求同步执行，同步返回

//执行api请求的方式，不设置时，默认：TCApiCall_Default，即最终调用apiCall
-(TCBaseApi * (^)(TCApiCallType))l_apiCallType;

//多请求同步执行，结果同步返回。目前apiCall方式设置只支持TCApiCall_Default,TCApiCall_Original
+ (void)multiCallApis:(NSArray<TCBaseApi*> *)apis finish:(void(^)(void))finish;


//MARK:- Extensions  以下方法，是为了支持以非继承的方式来使用TCBaseApi

/// 用来解析code，msg，time，dataObject，otherObject
/// 优先级高于codeKey，msgKey，timeKey，dataObjectKey，otherObjectKey方法
/// 注意：parseKeyMap中的key应该是：kDCodeKey，kDMsgKey，kDTimeKey，kDDataKey，kDOtherKey,其他的无效
/// 不想通过子类来重写codeKey，msgKey，dataObjectKey等方法时，可以用该方法来设置对应的key
-(TCBaseApi * (^)(NSDictionary *))l_parseKeyMap;

/// 自定义判定成功结果的code数组，优先级高于successCodes方法
/// 作用：当你把多个接口写在同一个接口类里面的时候，各个接口可能有不同的判断成功的code
-(TCBaseApi * (^)(NSArray *))l_successCodeArray;

/// 忽略错误提示的code数组，优先级高于ignoreErrToastCodes方法
/// 不想通过子类来重写ignoreErrToastCodes方法时，可以用该方法来设置忽略错误提示的code
-(TCBaseApi * (^)(NSArray *))l_ignoreErrToastCodeArray;

/// 配置HTTPManager，优先级高于configHttpManager:
/// TCBaseApi中的HTTPManager是单例，如果不同接口需要对manager进行差异化配置时，注意正确设置manager在不同接口下对应的配置
-(TCBaseApi * (^)(ConfigHttpManagerBlock))l_configHttpManagerBlock;

/// 配置HTTP的header，优先级高于configRequestHeaders:
-(TCBaseApi * (^)(ConfigHttpHeaderBlock))l_configHttpHeaderBlock;

/// 请求结束后执行，在通过code判定成功和失败之前调用，用来处理一些通用逻辑，优先级高于requestFinish:方法
-(TCBaseApi * (^)(InterceptorBlock))l_requestFinishBlock;

/// 如果TCBaseApi中默认的HTTPManager不能满足需求，可以自定义httpManager，优先级高于[TCBaseApi HTTPManager]
-(TCBaseApi * (^)(AFHTTPSessionManager *))l_customHttpManager;


//MARK:-


//MARK:- 请求完毕后可调用的实例方法
/// l_parseModelClass_parseKey多次设置，可以解析多个数据，通过TCPAddFlag给parseKey添加的flag来查询结果
- (id)getParsedResultWithFlagKey:(NSString *)flag err:(NSError **)err;
/// 按照l_parseModelClass_parseKey多次调用的顺序，通过下标查询结果
- (id)getParsedResultWithIndex:(NSUInteger)index err:(NSError **)err;

/// 判断请求完毕后，发生的错误是否是忽略提示的错误
- (BOOL)isErrorIgnored;



//MARK:- 子类可重写

/// 不重写的话，使用默认样式
- (BOOL)showCustomTost:(UIView *)errOnView text:(NSString *)errMsg;
/// 自定义数据加载中的提示框样式
- (BOOL)showCustomTostLoading:(UIView *)loadOnView;
/// 隐藏Loading提示框
- (BOOL)hideCustomTost:(UIView *)loadOnView;


/// 默认情况只在debug模式下打印日志，可在子类中重写此方法，来控制日志的打印
- (BOOL)printLog;

/// 发起请求前，检查是否有请求权限，比如没有网络等情况下，可以不进行请求，可子类重写进行控制
- (NSError *)checkHttpCanRequest;



/// 通常情况下需要重写
/// TCBaseApi中的HTTPManager是单例，如果不同接口需要对manager进行差异化配置时，注意正确设置manager在不同接口下对应的配置
/// 提示：当同时上传多张图片或其他文件时，可能需要设置更长的超时时间
/// @param manager manager单例
- (void)configHttpManager:(AFHTTPSessionManager *)manager;

/// 可重写该方法，然后对params进行签名加密等配置，或者其他公用设置
/// params类型与设置参数时传入的类型是一致的
/// 通过mutableCopy传入子类的为可变类型对象:NSMutableDictionary，NSMutableString，NSMutableData
/// 所以不可以改变params对象的内存地址，即不要新建对象
/// @param params 发起请求时的参数
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

/// 在TCBaseApi的子类中扩展属性，当对response进行解析时，会对扩展的属性进行赋值。
/// 设置的class必须是当前self本身的class或其父类，且是TCBaseApi的子类，建议使用自己创建的继承于TCBaseApi的基类。不要扩展TCBaseApi已有的属性。
- (Class)propertyExtensionClass;


/// 将http请求返回的原始数据进行变形处理，然后再进行解析
- (id)deformResponse:(id)oResponse;

/// 请求刚完毕时的结果检查，统一处理特殊业务，会在通过code判定成功和失败之前执行，子类复写
/// @param api 当前请求的api接口对象,需要用的数据都在该api的属性中
- (NSError *)requestFinish:(TCBaseApi *)api;


/// 如果对基类的HTTPManager不满意，可以自己在子类中重写，其他地方需要使用，可以通过类方法来调用
+ (AFHTTPSessionManager *)HTTPManager;

@end
