//
//  TCApiHelper.m
//  TCNetwork
//
//  Created by fengunion on 2021/2/24.
//

#import "TCApiHelper.h"
#import "TCBaseApi.h"

static NSMutableDictionary *sApisCache = nil;

static const NSString *kAllBarrierApiKey = @"kAllBarrierApiKey";

@implementation TCApiHelper

+ (void)clearCache {
    sApisCache = nil;
}

+ (NSMutableDictionary *)apiCache {
    if (!sApisCache) {
        sApisCache = [[NSMutableDictionary alloc] init];
    }
    return sApisCache;
}

+ (nullable TCBaseApi *)fetchBarrier:(nonnull NSString *)type {
    NSMutableArray *array = [sApisCache objectForKey:kAllBarrierApiKey];
    for (TCBaseApi *a in array) {
        if ([type isEqualToString:a.barrierType]) {
            return a;
        }
    }
    return nil;
}

+ (BOOL)addApi:(TCBaseApi *)api barrier:(NSString *)type {
    NSAssert(type.isNonEmpty, @"type不能为空");
    @synchronized (self) {
        BOOL isBarrier = api.barrierType.isNonEmpty;
        NSString *tempKey = isBarrier ? kAllBarrierApiKey : type;
        NSMutableArray *array = [self.apiCache objectForKey:tempKey];
        if (!array) {
            array = [[NSMutableArray alloc] init];
            [array addObject:api];
            [self.apiCache setObject:array forKey:tempKey];
            return YES;
        } else {
            if (isBarrier) {
                for (TCBaseApi *a in array) {
                    if ([a.barrierType isEqualToString:api.barrierType]) {
                        return NO;
                    }
                }
            }
            [array addObject:api];
            return YES;
        }
    }
}

+ (void)finishSuccessed:(BOOL)isSuccessed barrier:(nonnull NSString *)type {
    NSAssert(type.isNonEmpty, @"type不能为空");
    NSMutableArray *barrierArray = [sApisCache objectForKey:kAllBarrierApiKey];
    TCBaseApi *bApi = [self fetchBarrier:type];
    if (bApi) {
        [barrierArray removeObject:bApi];
        if (!barrierArray.count) {
            [sApisCache removeObjectForKey:kAllBarrierApiKey];
        }
    }
    NSMutableArray *apiArray = [sApisCache objectForKey:type];
    for (TCBaseApi *api in apiArray) {
        api.isBarrierExecuted = YES;
        if (isSuccessed) {
            [api prepareRequest];
        } else {
            [api finishBackThreadExe:^{
                [api handleError:[NSError barrierFailedError]];
            }];
        }
    }
    [sApisCache removeObjectForKey:type];
}

@end
