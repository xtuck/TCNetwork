//
//  UIView+TCToast.m
//
//  Created by xtuck on 2017/12/21.
//  Copyright © 2017年 xtuck. All rights reserved.
//

#import "UIView+TCToast.h"
#import <objc/runtime.h>

@interface UIView()

@property(nonatomic,assign) BOOL isToastLoading;

@end

@implementation UIView (TCToast)

- (BOOL)isEmptyStr:(NSString *)str {
    if (nil == str || ![str isKindOfClass:[NSString class]]) {
        return YES;
    }
    return ([[str stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceAndNewlineCharacterSet]] length] == 0);
}

- (BOOL)isToastLoading {
    NSNumber *loading = objc_getAssociatedObject(self, _cmd);
    return loading.boolValue;
}

- (void)setIsToastLoading:(BOOL)isToastLoading {
    objc_setAssociatedObject(self, @selector(isToastLoading), @(isToastLoading), OBJC_ASSOCIATION_RETAIN_NONATOMIC);
}

//toast是否会自动延迟隐藏，避免在调用toastHide的时候，被提前隐藏了
- (BOOL)isHudDelayHide {
    NSNumber *delayHide = objc_getAssociatedObject(self, _cmd);
    return delayHide.boolValue;
}

- (void)setIsHudDelayHide:(BOOL)isHudDelayHide {
    objc_setAssociatedObject(self, @selector(isHudDelayHide), @(isHudDelayHide), OBJC_ASSOCIATION_RETAIN_NONATOMIC);
}


- (void(^)(TCToastStype))toastWithText:(NSString *)text {
    return [self toastWithText:text hideAfterDelay:kToastDuration];
}

- (void(^)(TCToastStype))toastWithText:(NSString *)text hideAfterDelay:(NSTimeInterval)delay {
    MBProgressHUD *hud = nil;
    if (![self isEmptyStr:text]) {
        hud = [MBProgressHUD showHUDAddedTo:self animated:YES];
        hud.mode = MBProgressHUDModeText;
        hud.label.numberOfLines = 0;
        hud.label.text = text;
        hud.userInteractionEnabled = NO;
        [hud hideAnimated:YES afterDelay:delay];
        hud.isHudDelayHide = YES;
    }
    return ^(TCToastStype style){
        [self configHud:hud style:style];
    };
}

- (void(^)(TCToastStype))toastLoading {
    return [self toastLoadingWithText:nil];
}

- (void(^)(TCToastStype))toastLoadingWithText:(NSString *)text {
    MBProgressHUD *hud = nil;
    if (!self.isToastLoading) {
        self.isToastLoading = YES;
        hud = [MBProgressHUD showHUDAddedTo:self animated:YES];
        if (![self isEmptyStr:text]) {
            hud.label.text = text;
        }
    }
    return ^(TCToastStype style){
        [self configHud:hud style:style];
    };
}

- (void)configHud:(MBProgressHUD *)hud style:(TCToastStype)style {
    if (!hud) {
        return;
    }
    if (style == TCToastStypeDark) {
        hud.bezelView.blurEffectStyle = UIBlurEffectStyleDark;
        hud.contentColor = [[UIColor whiteColor] colorWithAlphaComponent:0.7];
    }
}

- (void)toastHide {
    if (!self.isToastLoading) {
        return;
    }
    self.isToastLoading = NO;
    //[MBProgressHUD hideHUDForView:self animated:YES];
    for (UIView *subview in self.subviews) {
        if ([subview isKindOfClass:MBProgressHUD.class]) {
            MBProgressHUD *hud = (MBProgressHUD *)subview;
            if (!hud.isHudDelayHide) {
                [hud hideAnimated:YES];
            }
        }
    }
}


+ (UIView *)appWindow {
    return [UIApplication sharedApplication].keyWindow;
}

+ (UIView *)currentView {
    UIViewController *controller = [[[UIApplication sharedApplication] keyWindow] rootViewController];
    UIViewController *currentVC = [self getCurrentVCFrom:controller];
    return currentVC.view;
}

+ (UIViewController *)getCurrentVCFrom:(UIViewController *)rootVC {
    UIViewController *currentVC;
    if([rootVC presentedViewController]) {
        // 视图是被presented出来的
        rootVC = [rootVC presentedViewController];
    }
    if([rootVC isKindOfClass:[UITabBarController class]]) {
        // 根视图为UITabBarController
        currentVC = [self getCurrentVCFrom:[(UITabBarController *)rootVC selectedViewController]];
    }else if([rootVC isKindOfClass:[UINavigationController class]]){
        // 根视图为UINavigationController
        currentVC = [self getCurrentVCFrom:[(UINavigationController *)rootVC visibleViewController]];
    }else{
        // 根视图为非导航类
        currentVC = rootVC;
    }
    return currentVC;
}

@end
