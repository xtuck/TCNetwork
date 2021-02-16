//
//  NSString+TCHelp.h
//  TCNetwork
//
//  Created by fengunion on 2020/6/2.
//

#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

@interface NSString (TCHelp)

- (BOOL)isNonEmpty;

//md5加密
- (NSString *)md5HexLower;
- (NSString *)md5HexUpper;
//头部去0，仅是去0
- (NSString *)md5del0;

//需要确保调用者str不为nil
- (NSString * (^)(NSString *))l_joinURL;

- (NSString *)jointUrlSuffix:(NSString *)suffixStr;

//中文转换成url
- (NSString *)toUrlCharacters;
//url取消转换
- (NSString *)undoUrlCharacters;

//url拼接字典参数，需要确保调用者str不为nil
- (NSString * (^)(NSDictionary *))urlJoinDic;
+ (NSString * (^)(NSDictionary *))urlJoinDic;

- (NSString * (^)(NSObject *))urlJoinObj;

//******* pathWithComponents 方法拼接的url，会把url中的双斜杠变成单斜杠，但是不影响请求数据 *******//

//拼接URL,最后一个参数必须传nil
+ (NSString * (^)(NSString *,...))joinURL;
+ (NSString * (^)(NSString *,va_list))joinURL_VL;

@end

NS_ASSUME_NONNULL_END
