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

@end
