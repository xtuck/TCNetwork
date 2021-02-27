# TCNetwork

[![CI Status](https://img.shields.io/travis/xtuck/TCNetwork.svg?style=flat)](https://travis-ci.org/xtuck/TCNetwork)
[![Version](https://img.shields.io/cocoapods/v/TCNetwork.svg?style=flat)](https://cocoapods.org/pods/TCNetwork)
[![License](https://img.shields.io/cocoapods/l/TCNetwork.svg?style=flat)](https://cocoapods.org/pods/TCNetwork)
[![Platform](https://img.shields.io/cocoapods/p/TCNetwork.svg?style=flat)](https://cocoapods.org/pods/TCNetwork)

## Example

To run the example project, clone the repo, and run `pod install` from the Example directory first.

## Requirements
ios9.0及以上


## Installation

TCNetwork is available through [CocoaPods](https://cocoapods.org). To install
it, simply add the following line to your Podfile:

```ruby
pod 'TCNetwork'
```

字典转model需要额外添加：
```ruby
pod 'TCJSONModel'
```

## Author

xtuck, 104166631@qq.com

## License

TCNetwork is available under the MIT license. See the LICENSE file for more info.


## 用法
部分用法在Api注释中和Demo注释中，demo中的数据我都是测试完毕后修改了，请自行使用真实的服务器配置信息进行调试。  
Https请求调试不通的时候，需要在info.plist中配置    
```
<key>NSAppTransportSecurity</key>
<dict>
    <key>NSAllowsArbitraryLoads</key>
    <true/>
</dict>
```
1·通过继承TCBaseApi，创建自己的api基类，在自己的api基类中编写通用配置和通用的处理逻辑。
  需要调用http请求时，创建api接口类，继承自己的api基类。或者直接使用基类进行请求。
  自定义基类参考demo中的“MyBaseApi”类或者“TCCoinBaseApi”类，接口请求类参考demo中的“CheckVersionApi”类。  
  不需要重写的父类方法可以不写，调用接口请求时，不需要的参数可以不传。
###

```
//基类的主要设置，继承TCBaseApi，与TCBaseApi中相同的配置，可以省略。参考"MyBaseApi.m"
//可以重写 -(void)apiCustomConfig 方法统一设置


@implementation MyBaseApi

- (NSString *)codeKey {
    return @"code";
}

- (NSString *)msgKey {
    return @"msg";
}

- (NSString *)dataObjectKey {
    return @"data";
}

//数组中的元素：number和string都可以
- (NSArray *)successCodes {
    return @[@"0"];
}
@end

//接口创建，继承MyBaseApi
//不设置l_httpMethod时，默认的是TCHttp_POST
+ (TCBaseApi *)checkVersion {
    NSMutableDictionary *params = NSMutableDictionary.maker.addKV(@"p1",@(1)).addKV(@"p2",@"2");
    return self.apiInitURLJoin(self.baseUrl,@"appversion/ios",nil).l_params(params).l_httpMethod(TCHttp_GET);
}
//接口调用
[CheckVersionApi checkVersion].apiCall(^(CheckVersionApi *api){
	NSLog(@"版本更新数据为：\n%@",[api.response description]);
});


//tableView列表请求示例
- (void)fetchListData:(RequestListDataFinishBlock)finishBlock {
    NSMutableDictionary *params = NSMutableDictionary.maker;
    params.addKV(@"pageNum",@(self.tableView.pageNumber));
    params.addKV(@"pageSize",@(self.tableView.pageSize));
    TCMyBaseApi.apiInitURLJoin(TCApiConfig.kApiBaseUrl,@"ums/api/ttp/imei/list".urlJoinDic(params),nil)
    .l_parseModelClass_parseKey(TCCouponCodeModel.class,@"#.list()")
    .apiCall(^(TCMyBaseApi *api) {
        finishBlock(api.resultParseObject,api.error,0);
    });
}

//直接创建接口并调用
NSMutableDictionary *params = NSMutableDictionary.maker;
params.addKV(@"organId",self.params[@"id"]);
TCMyBaseApi.apiInitURLJoin(TCApiConfig.kApiBaseUrl,@"navigation",nil)
.l_httpMethod(TCHttp_GET).l_params(params)
.l_parseModelClass(TCMapPositionModel.class)
.l_loadOnView(self.view)
.apiCallSuccess(^(TCMyBaseApi *api) {
    self.mapPModel = api.resultParseObject;
    //
});

```

2·通过非继承的方式调用TCBaseApi
```
TCBaseApi.apiInitURLFull(@"https://httpbin.org/ip").l_httpMethod(TCHttp_GET).l_parseModelClass_parseKey(nil,@"origin").apiCallOriginal(^(TCBaseApi *api) {
    NSString *ipStr = api.resultParseObject;
    NSLog(@"获取到了ip地址：%@",ipStr);
});

```
## 常用主要参数调用
```
TCBaseApi.apiInitURLFull(<FullUrlStr>).l_params(<paramsDic>).apiCall(^(TCBaseApi *api){
	//处理请求结果，通过对返回的api对象的属性error进行判空，来判断是否成功
});
```

### 注意
TCBaseApi中的HTTPManager是单例，如果不重写HTTPManager方法，在不同接口需要对manager进行差异化配置时，注意正确设置manager在不同接口下对应的配置  
若是未设置SessionManager的completionQueue和api的finishBackQueue，请求的返回数据会被切换到主线程返回，即：无论是主线程调用请求还是子线程调用请求，请求结果都会在主线程返回  
TCBaseApi解析的返回数据，默认格式为NSDictionary，如果返回数据为其他格式，请调用.apiCallOriginal()自行解析返回数据  

# 本框架的优势
1，通过链式编程的方式传递参数和调用方法，使得代码简洁又灵活，而且保持了接口调用的一致性，使得因编码造成的出错率非常小。  
2，统一了请求中的toast相关的调用和显示，不必关心如何显示以及显示和隐藏的配对，大大的简化了代码。  
3，自定义DSL解析返回数据，也是大大的简化了代码。(解析参数：l_parseModelClass_parseKey(,))。  
4，实现了接口调用失败后需调用指定接口后，再重新调用该失败接口的相关逻辑。
5，更多的优点，请在使用中去感受吧。
