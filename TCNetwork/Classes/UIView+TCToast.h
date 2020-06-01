//
//  UIView+TCToast.h
//
//  Created by xtuck on 2017/12/21.
//  Copyright © 2017年 xtuck. All rights reserved.
//

/**
 Toast 说明
 
 1，普通的toast提示，不会锁住UI,用户可自由操作，不影响体验
 
 2，toastLoading，会锁住UI，
    重要数据提交时，不想用户返回界面，使用[UIView.appWindow toastLoading]
    非重要数据请求时，如果允许用户返回，使用[UIView.currentView toastLoading] 或直接使用想要显示loading的容器view

 */


#import <UIKit/UIKit.h>
#import "MBProgressHUD.h"

#define kToastDuration 1.5

@interface UIView (TCToast)


- (void)toastWithText:(NSString *)text;

- (void)toastWithText:(NSString *)text hideAfterDelay:(NSTimeInterval)delay;

//自定义时候记得要设置此方法:[customHud hideAnimated:YES afterDelay:delay];
- (void)toastWithText:(NSString *)text hud:(MBProgressHUD *)customHud;


- (void)toastLoading;

- (void)toastLoadingWithText:(NSString *)text;

- (void)toastLoadingWithHud:(MBProgressHUD *)customHud;

- (void)toastHide;


+ (UIView *)appWindow;

+ (UIView *)currentView;

@end
