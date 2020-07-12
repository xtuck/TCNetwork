//
//  TCParseResult.h
//  TCNetwork
//
//  Created by fengunion on 2020/7/7.
//

#import <Foundation/Foundation.h>

@interface TCParseResult : NSObject

@property (nonatomic,copy,) NSString *originalParseKey;
@property (nonatomic,assign,) Class parseModelClass;

@property (nonatomic,copy,) NSString *parseFlag;
@property (nonatomic,copy,) NSString *withoutFlagParseKey;

@property (nonatomic,copy,) NSString *fullParseKey;
@property (nonatomic,strong,) NSObject *parseSource;

@property (nonatomic,strong) NSError *error;
@property (nonatomic,strong) NSObject *parseResult;
    

- (void)parse;


+ (NSString *)generateFullParseKey:(NSString *)rootDataKey parseKey:(NSString *)parseKey;

/// 为了通用化，所以fullParseKey需要在外部拼接好了再传过来
+ (TCParseResult *)parseObject:(NSObject *)parseSource
                  fullParseKey:(NSString *)fullParseKey
                         clazz:(Class)parseModelClass;


/// 通过key获取到最终的数据：字典，数组，基本数据(NSString/NSNumber)，nil
+ (id (^)(id source,NSString *fullKey,NSError **err))parse;
+ (id)parseWithSource:(id)source key:(NSString *)fullKey err:(NSError **)err;
+ (id (^)(id source,NSString *fullKey))lazyParse;

+ (void)printDebugLog:(NSString *)log;

@end
