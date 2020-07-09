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
#import <MBProgressHUD/MBProgressHUD.h>

#define kToastDuration 2

typedef NS_ENUM(NSUInteger, TCToastStyle) {
    TCToastStyleSystem, //白色样式。若是app支持暗黑模式，则跟随自动变换
    TCToastStyleDark,   //黑色样式
};

@interface UIView (TCToast)


- (void(^)(TCToastStyle))toastWithText:(NSString *)text;

- (void(^)(TCToastStyle))toastWithText:(NSString *)text hideAfterDelay:(NSTimeInterval)delay;


- (void(^)(TCToastStyle))toastLoading;

- (void(^)(TCToastStyle))toastLoadingWithText:(NSString *)text;


- (void)toastHide;


+ (UIView *)appWindow;

+ (UIView *)currentView;

@end
