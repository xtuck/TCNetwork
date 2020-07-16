//
//  TCNetworkTests.m
//  TCNetworkTests
//
//  Created by xtuck on 05/31/2020.
//  Copyright (c) 2020 xtuck. All rights reserved.
//

@import XCTest;
#import "TCBaseApi.h"

@interface Tests : XCTestCase

@end

@implementation Tests

- (void)setUp
{
    [super setUp];
    // Put setup code here. This method is called before the invocation of each test method in the class.
}

- (void)tearDown
{
    // Put teardown code here. This method is called after the invocation of each test method in the class.
    [super tearDown];
}

- (void)testExample
{
    XCTFail(@"No implementation for \"%s\"", __PRETTY_FUNCTION__);
}

- (void)testTCBaseApi {
    __block BOOL done = NO;
    dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(9 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
        done = YES;
    });

    TCBaseApi.apiInitURLFull(@"https://httpbin.org/ip").l_httpMethod(TCHttp_GET).l_parseModelClass_parseKey(nil,@"origin").apiCall(^(TCBaseApi *api) {
        NSString *ipStr = api.resultParseObject;
        NSLog(@"方式1:获取到了ip地址：%@",ipStr);
    });

    TCBaseApi.apiInitURLFull(@"https://httpbin.org/ip").l_httpMethod(TCHttp_GET).apiCall(^(TCBaseApi *api) {
        NSString *ipStr = TCParseResult.lazyParse(api.response,@"origin");
        NSLog(@"方式2:获取到了ip地址：%@",ipStr);
    });
    XCTAssertTrue([self waitFor:&done timeout:10],@"Timedout");
}

- (BOOL)waitFor:(BOOL *)flag timeout:(NSTimeInterval)timeoutSecs {
    NSDate *timeoutDate = [NSDate dateWithTimeIntervalSinceNow:timeoutSecs];
    do {
        [[NSRunLoop currentRunLoop] runMode:NSDefaultRunLoopMode beforeDate:timeoutDate];
        if ([timeoutDate timeIntervalSinceNow] < 0.0) {
            break;
        }
    }
    while (!*flag);
    return *flag;
}

@end

