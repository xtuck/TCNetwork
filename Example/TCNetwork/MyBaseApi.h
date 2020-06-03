//
//  MyBaseApi.h
//  TCNetwork_Example
//
//  Created by fengunion on 2020/6/2.
//  Copyright © 2020 xtuck. All rights reserved.
//

#import "TCBaseApi.h"

NS_ASSUME_NONNULL_BEGIN

@interface MyBaseApi : TCBaseApi

//扩展的属性，对应http请求返回的字典里面的key
//请根据自己的业务场景进行修改
@property (nonatomic,copy) NSString *errorMsg;
@property (nonatomic,copy) NSString *msg;//此属性与父类的message同意义，没有必要，此处只是为了演示
@property (nonatomic,copy) NSArray *list;

+ (NSString *)baseUrl;

@end

NS_ASSUME_NONNULL_END
