//
//  NSString+TCHelp.m
//  TCNetwork
//
//  Created by fengunion on 2020/6/2.
//

#import "NSString+TCHelp.h"

@implementation NSString (TCHelp)

- (BOOL)isNonEmpty {
    return [[self stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceAndNewlineCharacterSet]] length] != 0;
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
        return [NSString pathWithComponents:objs];
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
