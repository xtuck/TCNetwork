//
//  TCMallApi.h
//  Client
//
//  Created by fengunion on 2020/7/7.
//  Copyright © 2020 fleeming. All rights reserved.
//

#import "TCCoinBaseApi.h"
#import "TCTargetConfig+Mall.h"
#import "TCAdvertiseModel.h"
#import "TCProductModel.h"

@interface TCMallApi : TCCoinBaseApi

+ (TCBaseApi *)fetchMallHomeDataWithPageNum:(int)pageNum pageSize:(int)pageSize;

+ (TCBaseApi *)fetchProductDetailWitId:(NSString *)productId;

+ (TCBaseApi *)fetchStoreProductWithPageNum:(int)pageNum
                                   pageSize:(int)pageSize
                                       sort:(int)sort
                                    storeId:(NSString *)storeId;

+ (TCBaseApi *)searchProductWithPageNum:(int)pageNum
                               pageSize:(int)pageSize
                                   sort:(int)sort
                                keyword:(NSString *)keyword;

/// 生成订单确认信息，参数太多，接口调用处设置paramsDic
+ (TCBaseApi *)generateOrderConfirm;

@end



///MARK:调用示例1
- (void)fetchData:(BOOL)isLoadMore isDrag:(BOOL)isDarg {
    //筛选参数
    int sort = 0;//综合
        sort = 1;//最新
        sort = 2;//销量
        sort = 3;//价格升序
        sort = 4;//价格降序

    __weak typeof(self) weakSelf = self;
    [TCMallApi searchProductWithPageNum:self.pageNumber pageSize:self.pageSize sort:sort keyword:self.currentKeyword]
    .l_delegate(self)
    .l_loadOnView_errOnView(isDarg?nil:self.collectionBackView,self.view)
    .l_toastStyle(TCToastStyleDark)
    .l_cancelRequestType(TCCancelByURL)//支持取消未完成的请求
    .apiCall(^(TCMallApi *api) {
    //接口调用结束后的处理逻辑
    });
}

///MARK:调用示例2
- (void)searchStoreProduct {
    [TCMallApi fetchStoreProductWithPageNum:self.pageNumber pageSize:self.pageSize sort:sort storeId:storeId].apiCall(^(TCMallApi *api) {
        if (!api.error) {
            //获取返回的数据
            NSDictionary *storeInfo = [api getParsedResultWithFlagKey:@"store" err:nil];
            int total = [[api getParsedResultWithFlagKey:@"total" err:nil] intValue];
            NSArray *dataList = api.resultParseObject;
        }
    });
}

