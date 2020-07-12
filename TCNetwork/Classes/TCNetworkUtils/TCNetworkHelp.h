//
//  TCNetworkHelp.h
//  TCNetwork
//
//  Created by fengunion on 2020/7/10.
//

#import <Foundation/Foundation.h>

extern NSString * const kParseArray;//指定解析结果为数组
extern NSString * const kParseRoot;//解析原始的httpResponse
extern NSString * const kParseData;//解析dataObjectKey对应的数据
extern NSString * const kParseFlag;//解析的key加上标记，便于后面根据标记查询结果

/// 将parseKey转换成指定解析结果为数组的格式，即：末尾没有")",则在末尾加上"()"
extern NSString * TCPArray(NSString *key);

/// 解析过程中，将parseKey追加在dataObjectKey对应的key之后
extern NSString * TCPInData(NSString *key);

/// 解析过程中，将parseKey追加在dataObjectKey对应的key之后，并指定最终解析结果为数组
extern NSString * TCPArrayInData(NSString *key);

/// 在要解析的key后面加上标记，便于请求成功完毕后，根据该标记查询结果
extern NSString * TCPAddFlag(NSString *key, NSString *flag);

@interface TCNetworkHelp : NSObject

@end

@interface NSString (TCParseHelp)

/// 方法作用同：TCPAddFlag  因为是实例方法，所以需要保证调用者不为nil
- (NSString * (^)(NSString *flagKey))addParseFlag;

@end



