//
//  NSString+TCHelp.m
//  TCNetwork
//
//  Created by fengunion on 2020/6/2.
//

#import "NSString+TCHelp.h"
#import "CocoaSecurity.h"

@implementation NSString (TCHelp)

- (BOOL)isNonEmpty {
    return [[self stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceAndNewlineCharacterSet]] length] != 0;
}

- (NSString *)md5HexLower {
    return [CocoaSecurity md5:self].hexLower;
}

- (NSString *)md5HexUpper {
    return [CocoaSecurity md5:self].hex;
}

- (NSString *)md5del0 {
    NSMutableString *md5 = [self mutableCopy];
    //首位有0则去掉首位的0
    while ([md5 hasPrefix:@"0"]) {
        [md5 deleteCharactersInRange:NSMakeRange(0, 1)];
    }
    return md5;
}

- (NSString *)toUrlCharacters {
    return [self stringByAddingPercentEncodingWithAllowedCharacters:[NSCharacterSet URLQueryAllowedCharacterSet]];
}

- (NSString *)undoUrlCharacters {
    return [self stringByRemovingPercentEncoding];
}

- (NSString *)tc_URLEncode {
#pragma clang diagnostic push
#pragma clang diagnostic ignored"-Wdeprecated-declarations"
    return (NSString *)CFBridgingRelease(CFURLCreateStringByAddingPercentEscapes(kCFAllocatorDefault,
                                                                                 (CFStringRef)self,
                                                                                 (CFStringRef)@"!$&'()*+,-./:;=?@_~%#[]",
                                                                                 NULL,
                                                                                 kCFStringEncodingUTF8));
#pragma clang diagnostic pop
}

- (NSString *)tc_URLDecode {
    if ([self respondsToSelector:@selector(stringByRemovingPercentEncoding)]) {
        return [self stringByRemovingPercentEncoding];
    } else {
#pragma clang diagnostic push
#pragma clang diagnostic ignored "-Wdeprecated-declarations"
        CFStringEncoding en = CFStringConvertNSStringEncodingToEncoding(NSUTF8StringEncoding);
        NSString *decoded = [self stringByReplacingOccurrencesOfString:@"+"
                                                            withString:@" "];
        decoded = (__bridge_transfer NSString *)
        CFURLCreateStringByReplacingPercentEscapesUsingEncoding(
                                                                NULL,
                                                                (__bridge CFStringRef)decoded,
                                                                CFSTR(""),
                                                                en);
        return decoded;
#pragma clang diagnostic pop
    }
}



- (NSString * (^)(NSDictionary *))urlJoinDic {
    return ^(NSDictionary *params){
        if (!params.count) {
            return self;
        }
        NSMutableArray *mutablePairs = [NSMutableArray array];
        for (NSString *key in params.allKeys) {
            NSString *pairs = [NSString stringWithFormat:@"%@=%@",key,params[key]];
            [mutablePairs addObject:pairs];
        }
        NSString *paramsStr = [mutablePairs componentsJoinedByString:@"&"];
        NSString *joinStr = @"?";
        if ([self containsString:joinStr]) {
            joinStr = @"&";
        }
        return [NSString stringWithFormat:@"%@%@%@",self,joinStr,paramsStr];
    };
}

+ (NSString * (^)(NSDictionary *))urlJoinDic {
    return ^(NSDictionary *dic){
        return @"".urlJoinDic(dic);
    };
}

- (NSString * (^)(NSObject *))urlJoinObj {
    return ^(NSObject *obj){
        if ([obj isKindOfClass:NSNumber.class]) {
            obj = [(NSNumber *)obj stringValue];
        }
        if ([obj isKindOfClass:NSString.class]) {
            return self.l_joinURL((NSString *)obj).toUrlCharacters;
        } else if ([obj isKindOfClass:NSDictionary.class]) {
            return self.urlJoinDic((NSDictionary *)obj).toUrlCharacters;
        } else if ([obj isKindOfClass:NSArray.class]) {
            NSMutableArray *strArr = [[NSMutableArray alloc] init];
            NSMutableArray *dicArr = [[NSMutableArray alloc] init];
            for (NSObject *comp in (NSArray *)obj) {
                if ([comp isKindOfClass:NSNumber.class]) {
                    [strArr addObject:[(NSNumber *)comp stringValue]];
                } else if ([comp isKindOfClass:NSString.class]) {
                    [strArr addObject:comp];
                } else if ([comp isKindOfClass:NSDictionary.class]) {
                    [dicArr addObject:comp];
                }
            }
            NSString *urlJoin = [self copy];
            if (strArr.count) {
                [strArr insertObject:urlJoin atIndex:0];
                urlJoin = [NSString pathWithComponents:strArr];
            }
            for (NSDictionary *dic in dicArr) {
                urlJoin = urlJoin.urlJoinDic(dic);
            }
            return urlJoin.toUrlCharacters;
        }
        return self;
    };
}

- (NSString * (^)(NSString *))l_joinURL {
    return ^(NSString *suffix){
        return [self jointUrlSuffix:suffix];
    };
}

- (NSString *)jointUrlSuffix:(NSString *)suffixStr {
    if (suffixStr.isNonEmpty) {
        return [self stringByAppendingPathComponent:suffixStr]; //这个方法会把双斜杠变成单斜杠
    }
    return self;
    /*
    if ([self hasSuffix:@"/"]) {
        if ([suffixStr hasPrefix:@"/"]) {
            suffixStr = [suffixStr substringFromIndex:1];
        }
    } else {
        if (![suffixStr hasPrefix:@"/"]) {
            suffixStr = [@"/" stringByAppendingString:suffixStr?:@""];
        }
    }
    return [NSString stringWithFormat:@"%@%@",self,suffixStr];
    */
}


+ (NSString * (^)(NSString *,...))joinURL {
    return ^(NSString *obj,...){
        va_list args;
        va_start(args, obj);
        NSString *result = self.joinURL_VL(obj,args);
        va_end(args);
        return result;
    };
}

+ (NSString * (^)(NSString *,va_list))joinURL_VL {
    return ^(NSString *obj,va_list args){
        NSMutableArray *objs = [[NSMutableArray alloc] init];
        if (obj) {
            [objs addObject:obj];
            NSObject *argument;
            while ((argument = va_arg(args, NSObject *))) {
                [objs addObject:argument];
            }
        }
        return [NSString pathWithComponents:objs];//这个方法会把双斜杠变成单斜杠
    };
}


////举个栗子，test1 调用 test2，怎么把参数传递下去
//+ (void)test1:(NSString *)str1,... {
//    va_list args;
//    va_start(args, str1);
//    [self test2:str1 args:args];
//    va_end(args);
//}
//
//+ (void)test2:(NSString *)str2 args:(va_list)args {
//    NSString *str = NSString.joinURL_VL(str2,args);
//    NSLog(@"输出日志：%@",str);
//}

@end
