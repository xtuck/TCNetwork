//
//  TCTargetConfig+Mall.m
//  Client
//
//  Created by fengunion on 2020/7/7.
//  Copyright © 2020 fleeming. All rights reserved.
//

#import "TCTargetConfigMall.h"

@implementation TCTargetConfigMall

+ (NSString *)kMallHomeDataUrl {
    return self.kApiBaseUrl.l_joinURL(@"/xxx/api/home");
}

+ (NSString *)kMallProductDetailUrl {
    return self.kApiBaseUrl.l_joinURL(@"/xxx/api/product/detail");
}

+ (NSString *)kMallStoreProductUrl {
    return self.kApiBaseUrl.l_joinURL(@"/xxx/api/store/product");
}

+ (NSString *)kMallSearchProductUrl {
    return self.kApiBaseUrl.l_joinURL(@"/xxx/api/esProduct/search");
}

+ (NSString *)kMallOrderGenerateConfirmUrl {
    return self.kApiBaseUrl.l_joinURL(@"/xxx/api/order/generate/confirm");
}


@end
