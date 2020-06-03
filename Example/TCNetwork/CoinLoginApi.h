//
//  CoinLoginApi.h
//  TCNetwork_Example
//
//  Created by fengunion on 2020/6/3.
//  Copyright © 2020 xtuck. All rights reserved.
//

#import "MyBaseApi.h"

NS_ASSUME_NONNULL_BEGIN

@interface CoinLoginApi : MyBaseApi

+ (TCBaseApi *)loginWithUsername:(NSString *)username pwd:(NSString *)pwd;

@end

NS_ASSUME_NONNULL_END
