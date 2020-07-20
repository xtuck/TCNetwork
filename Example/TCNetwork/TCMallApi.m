//
//  TCMallApi.m
//  Client
//
//  Created by fengunion on 2020/7/7.
//  Copyright © 2020 fleeming. All rights reserved.
//

#import "TCMallApi.h"

@implementation TCMallApi

+ (TCBaseApi *)fetchMallHomeDataWithPageNum:(int)pageNum pageSize:(int)pageSize {
    NSMutableDictionary *params = NSMutableDictionary.maker;
    params.addKV(@"pageNum",@(pageNum));
    params.addKV(@"pageSize",@(pageSize));
    return self.apiInitURLFull(TCTargetConfig.kMallHomeDataUrl).l_params(params)
    .l_parseModelClass_parseKey(TCProductModel.class,TCPArrayInData(@"indexProduct.list"));
}

+ (TCBaseApi *)fetchProductDetailWitId:(NSString *)productId {
    NSString *fullUrl = [NSString stringWithFormat:@"%@?productId=%@",TCTargetConfig.kMallProductDetailUrl,productId];
    return self.apiInitURLFull(fullUrl);
}

+ (TCBaseApi *)fetchStoreProductWithPageNum:(int)pageNum
                                   pageSize:(int)pageSize
                                       sort:(int)sort
                                    storeId:(NSString *)storeId {
    NSMutableDictionary *params = NSMutableDictionary.maker;
    params.addKV(@"pageNum",@(pageNum));
    params.addKV(@"pageSize",@(pageSize));
    params.addKV(@"sort",@(sort));
    params.addKV(@"storeId",storeId);
    return self.apiInitURLFull(TCTargetConfig.kMallStoreProductUrl).l_params(params)
    .l_parseModelClass_parseKey(TCProductModel.class,@"#.productList.list()")
    .l_parseModelClass_parseKey(NSNumber.class,@"#.productList.total?total")
    .l_parseModelClass_parseKey(NSDictionary.class,TCPAddFlag(TCPInData(@"shopStoreEntity"), @"store"));
}

+ (TCBaseApi *)searchProductWithPageNum:(int)pageNum
                               pageSize:(int)pageSize
                                   sort:(int)sort
                                keyword:(NSString *)keyword {
    NSMutableDictionary *params = NSMutableDictionary.maker;
    params.addKV(@"pageNum",@(pageNum));
    params.addKV(@"pageSize",@(pageSize));
    params.addKV(@"sort",@(sort));
    params.addKV(@"keyword",keyword);
    return self.apiInitURLFull(TCTargetConfig.kMallSearchProductUrl.urlJoinDic(params).toUrlCharacters)
    //.l_params(params)//参数都在url中
    .l_parseModelClass_parseKey(TCProductModel.class,@"#.list()"); //@"#.list()" = TCPArrayInData(@"list")
}


+ (TCBaseApi *)generateOrderConfirm {
    return self.apiInitURLFull(TCTargetConfig.kMallOrderGenerateConfirmUrl).l_loadOnView(UIView.appWindow);
}

@end
