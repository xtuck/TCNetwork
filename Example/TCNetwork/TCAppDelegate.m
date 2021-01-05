//
//  TCAppDelegate.m
//  TCNetwork
//
//  Created by xtuck on 05/31/2020.
//  Copyright (c) 2020 xtuck. All rights reserved.
//

#import "TCAppDelegate.h"
#import "CheckVersionApi.h"

@implementation TCAppDelegate

- (BOOL)application:(UIApplication *)application didFinishLaunchingWithOptions:(NSDictionary *)launchOptions
{
    return YES;
}

- (void)applicationWillResignActive:(UIApplication *)application
{
    // Sent when the application is about to move from active to inactive state. This can occur for certain types of temporary interruptions (such as an incoming phone call or SMS message) or when the user quits the application and it begins the transition to the background state.
    // Use this method to pause ongoing tasks, disable timers, and throttle down OpenGL ES frame rates. Games should use this method to pause the game.
}

- (void)applicationDidEnterBackground:(UIApplication *)application
{
    // Use this method to release shared resources, save user data, invalidate timers, and store enough application state information to restore your application to its current state in case it is terminated later.
    // If your application supports background execution, this method is called instead of applicationWillTerminate: when the user quits.
}

- (void)applicationWillEnterForeground:(UIApplication *)application
{
    // Called as part of the transition from the background to the inactive state; here you can undo many of the changes made on entering the background.
}

- (void)applicationDidBecomeActive:(UIApplication *)application {
    dispatch_async(dispatch_get_global_queue(0, 0), ^{
        [CheckVersionApi checkVersion].l_successCodeArray(@[@200]).apiCallSuccess(^(CheckVersionApi *api) {
            NSLog(@"获取到版本检测的返回结果：\n%@",api.response);
            NSString *msg = api.msg;
            NSLog(@"赋值结果:%@",msg);
        });
    });
}

- (void)applicationWillTerminate:(UIApplication *)application
{
    // Called when the application is about to terminate. Save data if appropriate. See also applicationDidEnterBackground:.
}

@end
