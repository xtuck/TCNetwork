//
//  LoginApi.h
//  TCNetwork_Example
//
//  Created by fengunion on 2020/6/2.
//  Copyright © 2020 xtuck. All rights reserved.
//

#import "MyBaseApi.h"

NS_ASSUME_NONNULL_BEGIN

@interface LoginApi : MyBaseApi

+ (LoginApi *)loginWithUsername:(NSString *)username pwd:(NSString *)pwd;

@end

NS_ASSUME_NONNULL_END
