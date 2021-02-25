//
//  TCParseResult.m
//  TCNetwork
//
//  Created by fengunion on 2020/7/7.
//

#import "TCParseResult.h"
#import "NSString+TCHelp.h"
#import "NSError+TCHelp.h"
#import "TCNetworkHelp.h"
#import "TCBaseApi.h"

@implementation TCParseResult

+ (void)printDebugLog:(NSString *)log {
#if DEBUG
    NSLog(@"TCParse tell you \n%@",log);
#endif
}

+ (NSString *)generateFullParseKey:(NSString *)rootDataKey parseKey:(NSString *)parseKey {
    if (!parseKey.isNonEmpty || [parseKey isEqualToString:kParseData]) {
        return rootDataKey;
    }
    
    if ([parseKey isEqualToString:kParseRoot]) {
        return nil;
    }
    
    if ([parseKey isEqualToString:kParseArray]) {
        return [NSString stringWithFormat:@"%@%@",rootDataKey?:@"",kParseArray];
    }
    
    NSString *tempParseKey = [parseKey copy];
    if ([tempParseKey hasPrefix:kParseRoot]) {
        tempParseKey = [tempParseKey substringFromIndex:kParseRoot.length];
    }
    if ([tempParseKey hasPrefix:@"."]) {
        tempParseKey = [tempParseKey substringFromIndex:1];
    }
    
    if (!tempParseKey.isNonEmpty) {
        return nil;
    }

    if ([tempParseKey hasPrefix:kParseData]) {
        tempParseKey = [tempParseKey substringFromIndex:kParseData.length];
        if (rootDataKey.isNonEmpty) {
            if (![tempParseKey hasPrefix:@"."]) {
                tempParseKey = [@"." stringByAppendingString:tempParseKey];;
            }
            tempParseKey = [rootDataKey stringByAppendingString:tempParseKey];
        } else {
            if ([tempParseKey hasPrefix:@"."]) {
                tempParseKey = [tempParseKey substringFromIndex:1];
            }
        }
    }
    return tempParseKey;
}

+ (TCParseResult *)parseObject:(NSObject *)parseSource
                  fullParseKey:(NSString *)fullParseKey
                         clazz:(Class)parseModelClass {
    TCParseResult *model = [[TCParseResult alloc] init];
    model->_parseSource = parseSource;
    model->_parseModelClass = parseModelClass;
    model->_fullParseKey = fullParseKey;
    
    [model parse];
    
    return model;
}

//兼容处理
+ (NSDictionary *)compatibleResultDic:(NSDictionary *)dic class:(Class)clazz {
    if (!clazz || !dic || ![dic isKindOfClass:NSString.class]) {
        return dic;
    }
    //特殊处理：如果返回结果是字符串，解析的modelClass是字典或数组或者自定义model，就将字符串转为JSONObject-->NSDictionary或NSArray
    if (([clazz isSubclassOfClass:NSArray.class]
         || [clazz isSubclassOfClass:NSDictionary.class]
         || [TCParseResult checkCustomClass:clazz] == 1)) {
        NSDictionary *resDic =  [NSJSONSerialization JSONObjectWithData:[(NSString *)dic dataUsingEncoding:NSUTF8StringEncoding]
                                                                options:kNilOptions error:nil];
        if (resDic) {
            [TCParseResult printDebugLog:@"指定结果为NSDictionary或者NSArray或自定义model，解析出的数据为String，已转换成JSONObject"];
            return resDic;
        }
    }
    return dic;
}

- (void)parse {
    if (!self.parseSource) {
        _error = [NSError errorCode:@"-16810" msg:@"解析数据源为空!!!"];
        return;
    }

    NSDictionary *resultDic = (id)self.parseSource;
    if (!self.fullParseKey.isNonEmpty && !self.parseModelClass) {
        _parseResult = resultDic;
        return;
    }

    NSError *err = nil;
    resultDic = [TCParseResult parseWithSource:resultDic key:self.fullParseKey clazz:self.parseModelClass err:&err];
    if (err) {
        _error = err;
        return;
    }
    if (!resultDic || [resultDic isKindOfClass:NSNull.class]) {
        return;
    }

    //如果parseKey最末尾是通过(x,y)来取值或者末尾是"()"，则指定最终解析结果为数组
    BOOL isParseArray = [self.fullParseKey hasSuffix:@")"];
    //容错处理，避免外部调用array的方法时崩溃
    if ((isParseArray || [self.parseModelClass isSubclassOfClass:NSArray.class]) && ![resultDic isKindOfClass:NSArray.class]) {
        NSString *errMsg = [NSString stringWithFormat:@"parseKey:%@ 指定结果为数组 \n 解析出的数据为非数组:%@",self.fullParseKey,resultDic];
        _error = [NSError errorCode:@"-16811" msg:errMsg];
        return;
    }

    if (!self.parseModelClass) {
        _parseResult = resultDic;
        return;
    }
    
    //基本类型赋值，isParseArray为YES时，直接赋值为原始值，未对数组中的类型进行校验
    if ([self.parseModelClass isSubclassOfClass:NSDictionary.class]) {
        if (isParseArray) {
            _parseResult = resultDic;
            return;
        }
        if ([resultDic isKindOfClass:NSDictionary.class]) {
            _parseResult = resultDic;
        } else {
            NSString *errMsg = [NSString stringWithFormat:@"parseKey:%@ 指定结果为字典 \n 解析出的数据为非字典:%@",self.fullParseKey,resultDic];
            _error = [NSError errorCode:@"-16812" msg:errMsg];
        }
        return;
    }
    if ([self.parseModelClass isSubclassOfClass:NSNumber.class]) {
        if (isParseArray) {
            _parseResult = resultDic;
            return;
        }
        if ([resultDic isKindOfClass:NSString.class]) {
            NSDecimalNumber *num = [NSDecimalNumber decimalNumberWithString:(id)resultDic];
            _parseResult = num;
        } else if ([resultDic isKindOfClass:NSNumber.class]) {
            _parseResult = resultDic;
        } else {
            NSString *errMsg = [NSString stringWithFormat:@"parseKey:%@ 指定结果为number \n 解析出的数据为非number:%@",self.fullParseKey,resultDic];
            _error = [NSError errorCode:@"-16813" msg:errMsg];
        }
        return;
    }

    if ([self.parseModelClass isSubclassOfClass:NSString.class]) {
        if (isParseArray) {
            _parseResult = resultDic;
            return;
        }
        if ([resultDic isKindOfClass:NSString.class]) {
            _parseResult = resultDic;
        } else if ([resultDic isKindOfClass:NSNumber.class]) {
            _parseResult = [(NSNumber *)resultDic stringValue];
        } else {
            _parseResult = [NSString stringWithFormat:@"%@",resultDic];
            [TCParseResult printDebugLog:@"指定结果为String，解析出的数据为非String，已转换成String"];
        }
        return;
    }

    if (self.apiDelegate && [self.apiDelegate respondsToSelector:@selector(customParse:clazz:isArray:err:)]) {
        _parseResult = [self.apiDelegate customParse:resultDic clazz:self.parseModelClass isArray:isParseArray err:&err];
        _error = err;
        return;
    }
    
    if ([TCParseResult checkCustomClass:self.parseModelClass] == 0) {
        _parseResult = resultDic;
        [TCParseResult printDebugLog:@"传入的parseModelClass不是自定义的model，resultParseObject将赋值为原始数据"];
        return;
    }

    SEL modelSel = nil;
    if (isParseArray) {
        modelSel = NSSelectorFromString(@"tc_arrayOfModelsFromKeyValues:error:");
    } else {
        modelSel = NSSelectorFromString(@"tc_modelFromKeyValues:error:");
    }
    if ([self.parseModelClass respondsToSelector:modelSel]) {
        IMP imp = [self.parseModelClass methodForSelector:modelSel];
        NSObject *(*func)(id, SEL, id, NSError**) = (void *)imp;
        _parseResult = func(self.parseModelClass, modelSel, resultDic, &err);
        _error = err;
    } else {
        _error = [NSError errorCode:@"-16814" msg:@"请添加：pod 'TCJSONModel' 进行model转换"];
        [TCParseResult printDebugLog:_error.localizedDescription];
    }
}

//通过TCJSONModel中的NSObject+TCJSONModel分类的__isCustomClass方法，判断传入的parseModelClass是否是自定义model
+ (int)checkCustomClass:(Class)clazz {
    if (!clazz) {
        return -2;
    }
    SEL isCustomClassSel = NSSelectorFromString(@"tc_isCustomClass:");
    if ([NSObject respondsToSelector:isCustomClassSel]) {
        IMP imp = [self methodForSelector:isCustomClassSel];
        BOOL (*func)(id, SEL, id) = (void *)imp;
        BOOL isCustomClass = func(self, isCustomClassSel,clazz);
        if (isCustomClass) {
            return 1;//自定义对象
        } else {
            return 0;//基本数据对象
        }
    }
    return -1;//未导入pod 'TCJSONModel'
}

+ (id (^)(id source,NSString *fullKey))lazyParse {
    return ^(id source,NSString *fullKey){
        return self.parse(source,fullKey,nil);
    };
}

+ (id (^)(id, NSString *, NSError **))parse {
    return ^(id source,NSString *fullKey,NSError **err){
        return [self parseWithSource:source key:fullKey clazz:nil err:err];
    };
}

+ (id)parseWithSource:(id)source key:(NSString *)fullKey clazz:(Class)clazz err:(NSError **)err {
    if (!source) {
        if (err) {
            *err = [NSError errorCode:@"-16810" msg:@"解析数据源为空"];
        }
        return nil;
    }
    if (!fullKey.isNonEmpty || [fullKey isEqualToString:kParseRoot]) {
        return [self compatibleResultDic:source class:clazz];//MARK:新增
    }
    
    if ([fullKey isEqualToString:kParseArray]) {
        source = [self compatibleResultDic:source class:clazz];//MARK:新增
        if ([source isKindOfClass:NSArray.class]) {
            return source;
        }
        if (err) {
            NSString *errMsg = [NSString stringWithFormat:@"parseKey:%@ 指定结果为数组 \n 数据源为非数组:%@",fullKey,source];
            *err = [NSError errorCode:@"-16815" msg:errMsg];
        }
        return nil;
    }
    
    NSString *tempKey = [fullKey copy];
    if ([tempKey hasPrefix:kParseRoot]) {
        tempKey = [tempKey substringFromIndex:kParseRoot.length];
    }
    if ([tempKey hasSuffix:kParseArray]) {
        tempKey = [tempKey substringToIndex:tempKey.length - kParseArray.length];
    }
    //tempKey = [tempKey stringByReplacingOccurrencesOfString:kParseArray withString:@"(,)"];

    NSDictionary *resultDic = [self compatibleResultDic:source class:clazz];//MARK:新增
    NSMutableArray *keys = [NSMutableArray array];
    NSArray *keyArr = [tempKey componentsSeparatedByString:@"."];
    for (NSString *key in keyArr) {
        if (key.isNonEmpty) {
            [keys addObject:key];
        }
    }
    
    for (NSString *pKey in keys) {
        //判断是否是数组取值:下标取值[0]和区间取值range(0,1),支持多维取值
        NSUInteger start = [pKey rangeOfString:@"["].location;
        NSUInteger start2 = [pKey rangeOfString:@"("].location;
        NSString *indexsKey = nil;
        if (start == NSNotFound && start2 == NSNotFound) {
            if ([resultDic isKindOfClass:NSDictionary.class]) {
                resultDic = [self compatibleResultDic:resultDic[pKey] class:clazz];//MARK:新增
            } else if ([resultDic isKindOfClass:NSArray.class] || [resultDic isKindOfClass:NSNull.class]){
                //非字典数据
                if (err) {
                    NSString *errMsg = [NSString stringWithFormat:@"parseKey:%@ 获取非数组数据 \n 当前数据为:%@",pKey,resultDic];
                    *err = [NSError errorCode:@"-16816" msg:errMsg];
                }
                return nil;
            }
            continue;
        } else {
            NSUInteger mStart = start < start2 ? start : start2;
            indexsKey = [pKey substringFromIndex:mStart];
            NSString *pKeyNew = [pKey substringToIndex:mStart];
            if (pKeyNew.isNonEmpty) {
                if ([resultDic isKindOfClass:NSDictionary.class]) {
                    resultDic = [self compatibleResultDic:resultDic[pKeyNew] class:clazz];//MARK:新增
                } else if ([resultDic isKindOfClass:NSArray.class] || [resultDic isKindOfClass:NSNull.class]){
                    //非字典数据
                    if (err) {
                        NSString *errMsg = [NSString stringWithFormat:@"parseKey:%@ 获取非数组数据 \n 当前数据为:%@",pKeyNew,resultDic];
                        *err = [NSError errorCode:@"-16817" msg:errMsg];
                    }
                    return nil;
                }
            }
        }
        //例："[0](1,10)(1,8)[3][4](3,4)" -> "0","(1,10)(1,8)3","4","(3,4)" -> "0","1,10","1,8","3","4","3,4"
        if (indexsKey.isNonEmpty) {
            NSMutableArray *indexsArray = [NSMutableArray array];
            NSArray *cmps = [[indexsKey stringByReplacingOccurrencesOfString:@"[" withString:@""] componentsSeparatedByString:@"]"];
            for (NSString *subcmps in cmps) {
                if (subcmps.isNonEmpty) {
                    NSArray *cmps2 = [[subcmps stringByReplacingOccurrencesOfString:@"(" withString:@""] componentsSeparatedByString:@")"];
                    for (NSString *subcmps2 in cmps2) {
                        if (subcmps2.isNonEmpty) {
                            [indexsArray addObject:subcmps2];
                        }
                    }
                }
            }
            for (NSString *indexStr in indexsArray) {
                if (![resultDic isKindOfClass:NSArray.class] || [resultDic isKindOfClass:NSNull.class]) {
                    if (err) {
                        NSString *errMsg = [NSString stringWithFormat:@"parseKey:%@ 获取数组数据 \n 当前数据为非数组:%@",indexStr,resultDic];
                        *err = [NSError errorCode:@"-16818" msg:errMsg];
                    }
                    return nil;
                }
                NSRange rang = NSMakeRange(0, 1);
                NSUInteger comma = [indexStr rangeOfString:@","].location;
                NSInteger locationTemp = 0;
                if (comma != NSNotFound) {
                    NSString *loc = [indexStr substringToIndex:comma];
                    locationTemp = loc.integerValue;
                    NSString *len = [indexStr substringFromIndex:comma+1];
                    rang.length = len.integerValue > 0 ? len.integerValue : 0;
                } else {
                    locationTemp = indexStr.integerValue;
                }
                if (locationTemp >= 0) {
                    rang.location = locationTemp;
                }
                
                NSArray *resArray = (NSArray *)resultDic;
                if (rang.location >= resArray.count) {
                    if (err) {
                        NSString *errMsg = [NSString stringWithFormat:@"数组取值越界: %@ :%@ :%@",fullKey,indexsKey,indexStr];
                        *err = [NSError errorCode:@"-16819" msg:errMsg];
                    }
                    return nil;
                }
                if (locationTemp < 0) {
                    locationTemp = resArray.count + locationTemp;
                    if (locationTemp < 0) {
                        locationTemp = 0;
                    }
                    rang.location = locationTemp;
                }
                
                if (comma != NSNotFound) {
                    if (rang.length == 0 || rang.location + rang.length > resArray.count) {
                        rang.length = resArray.count - rang.location;
                    }
                    resultDic = (id)[resArray subarrayWithRange:rang];
                } else {
                    resultDic = [resArray objectAtIndex:rang.location];
                }
                resultDic = [self compatibleResultDic:resultDic class:clazz];//MARK:新增
            }
        }
    }
    return [self compatibleResultDic:resultDic class:clazz];//MARK:新增;
}



@end
