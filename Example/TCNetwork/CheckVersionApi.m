//
//  CheckVersionApi.m
//  TCNetwork_Example
//
//  Created by fengunion on 2020/6/2.
//  Copyright © 2020 xtuck. All rights reserved.
//

#import "CheckVersionApi.h"

@implementation CheckVersionApi


+ (TCBaseApi *)checkVersion {
    //apiInitURLFull方式如下
    //return self.apiInitURLFull([NSString stringWithFormat:@"%@/%@",self.baseUrl,@"contract/appversion/ios"])

    //apiInitURLJoin方式如下，因为参数是可变参数，记得末尾要加nil，和以前使用UIAlertView时候，设置otherButtonTitles参数一样
    return self.apiInitURLJoin(self.baseUrl,@"contract/appversion/ios",nil)
    .l_httpMethod(TCHttp_GET) //不设置l_httpMethod时，默认的是TCHttp_POST
    .l_successCodeArray(@[@0]);//l_successCodeArray的设置优先级大于父类中successCodes方法，如果不设置，则使用父类中的successCodes配置
}


//为了测试自动取消请求，所以设置下面返回nil
- (NSArray *)ignoreErrToastCodes {
    return nil;
}

@end
