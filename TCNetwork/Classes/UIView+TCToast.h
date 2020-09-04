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

 3，经验证toastLoading添加时，会阻塞主线程，耗时10毫秒左右

 */


#import <UIKit/UIKit.h>
#import <MBProgressHUD/MBProgressHUD.h>

#define kToastDuration 2

typedef NS_ENUM(NSUInteger, TCToastStyle) {
    TCToastStyleSystem, //白色样式。若是app支持暗黑模式，则跟随自动变换
    TCToastStyleDark,   //黑色样式
};

@interface UIView (TCToast)

- (void)toastWithText:(NSString *)text;
- (void)toastWithText:(NSString *)text style:(TCToastStyle)style;

- (void)toastWithText:(NSString *)text hideAfterDelay:(NSTimeInterval)delay;
- (void)toastWithText:(NSString *)text hideAfterDelay:(NSTimeInterval)delay style:(TCToastStyle)style;


- (void)toastLoading;
- (void)toastLoadingWithStyle:(TCToastStyle)style;

- (void)toastLoadingWithText:(NSString *)text;
- (void)toastLoadingWithText:(NSString *)text style:(TCToastStyle)style;

- (void)toastHide;


+ (UIView *)appWindow;

+ (UIView *)currentView;

@end
