//
//  TCTargetConfig+Mall.h
//  Client
//
//  Created by fengunion on 2020/7/7.
//  Copyright © 2020 fleeming. All rights reserved.
//

//MARK:使用继承方式，便于在特殊情况下，可以在模块中重设BaseUrl

#import "TCTargetConfig.h"

@interface TCTargetConfigMall : TCTargetConfig

+ (NSString *)kMallHomeDataUrl;

+ (NSString *)kMallProductDetailUrl;

+ (NSString *)kMallStoreProductUrl;

+ (NSString *)kMallSearchProductUrl;

+ (NSString *)kMallOrderGenerateConfirmUrl;

@end
