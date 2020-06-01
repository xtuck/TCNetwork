//
//  HttpManager.h
//
//  Created by xtuck on 2018/3/5.
//  Copyright © 2018年 xtuck. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <AFNetworking/AFNetworking.h>

static CGFloat const kHttpRequestTimeoutInterval = 15.0;

@interface TCHttpManager : NSObject

//目前调用的是noneVerManager
+ (AFHTTPSessionManager *)sharedAFManager;

+ (AFHTTPSessionManager *)noneVerManager;//免https验证


//以下方法未实践，故暂不公开使用
/*
+ (AFHTTPSessionManager *)oneWayVerManager:(NSString *)baseUrl;//https单向验证

+ (AFHTTPSessionManager *)bothWayVerManager:(NSString *)baseUrl;//https双向验证
*/

@end
