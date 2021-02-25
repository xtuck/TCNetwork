//
//  TCApiHelper.h
//  TCNetwork
//
//  Created by fengunion on 2021/2/24.
//

#import <Foundation/Foundation.h>

@class TCBaseApi;
@interface TCApiHelper : NSObject

+ (nullable TCBaseApi *)fetchBarrier:(nonnull NSString *)type;

+ (BOOL)addApi:(nonnull TCBaseApi *)api barrier:(nonnull NSString *)type;

+ (void)finishSuccessed:(BOOL)isSuccessed barrier:(nonnull NSString *)type;

@end
