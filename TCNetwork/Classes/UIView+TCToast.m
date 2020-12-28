//
//  UIView+TCToast.m
//
//  Created by xtuck on 2017/12/21.
//  Copyright © 2017年 xtuck. All rights reserved.
//

#import "UIView+TCToast.h"
#import <objc/runtime.h>
#import "TCNetworkHelp.h"

@interface UIView()

@end

@implementation UIView (TCToast)

static TCToastStyle dfStyle;
+ (void)setupDefaultStyle:(TCToastStyle)style {
    dfStyle = style;
}

+ (TCToastStyle)getDefaultStyle {
    return dfStyle;
}

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

- (int)toastLoadingCount {
    NSNumber *loadingCount = objc_getAssociatedObject(self, _cmd);
    return loadingCount.intValue;
}

- (void)setToastLoadingCount:(int)toastLoadingCount {
    objc_setAssociatedObject(self, @selector(toastLoadingCount), @(toastLoadingCount), OBJC_ASSOCIATION_RETAIN_NONATOMIC);
}


//toast是否会自动延迟隐藏，避免在调用toastHide的时候，被提前隐藏了
- (BOOL)isHudDelayHide {
    NSNumber *delayHide = objc_getAssociatedObject(self, _cmd);
    return delayHide.boolValue;
}

- (void)setIsHudDelayHide:(BOOL)isHudDelayHide {
    objc_setAssociatedObject(self, @selector(isHudDelayHide), @(isHudDelayHide), OBJC_ASSOCIATION_RETAIN_NONATOMIC);
}

- (UIView *)catcherView {
    TCNWeakContainer *container = objc_getAssociatedObject(self, _cmd);
    return container.weakObj;
}

- (void)setCatcherView:(UIView *)catcherView {
    TCNWeakContainer *container = nil;
    if (catcherView != nil) {
        container = [[TCNWeakContainer alloc] initWithWeakObj:catcherView];
    }
    objc_setAssociatedObject(self, @selector(catcherView), container, OBJC_ASSOCIATION_RETAIN_NONATOMIC);
}
- (UIView *)throwerView {
    TCNWeakContainer *container = objc_getAssociatedObject(self, _cmd);
    return container.weakObj;
}

- (void)setThrowerView:(UIView *)throwerView {
    TCNWeakContainer *container = nil;
    if (throwerView != nil) {
        container = [[TCNWeakContainer alloc] initWithWeakObj:throwerView];
    }
    objc_setAssociatedObject(self, @selector(throwerView), container, OBJC_ASSOCIATION_RETAIN_NONATOMIC);
}

- (UIView *)loadingThrower:(UIView *)previousView {
    self.throwerView = previousView;
    previousView.catcherView = self;
    return self;
}

- (TCToastStyle)currentLoadingStyle {
    NSNumber *loadingStyle = objc_getAssociatedObject(self, _cmd);
    return loadingStyle.integerValue;
}

- (void)setCurrentLoadingStyle:(NSInteger)currentLoadingStyle {
    objc_setAssociatedObject(self, @selector(currentLoadingStyle), @(currentLoadingStyle), OBJC_ASSOCIATION_RETAIN_NONATOMIC);
}

- (NSString *)currentLoadingText {
    return objc_getAssociatedObject(self, _cmd);
}

- (void)setCurrentLoadingText:(NSString *)currentLoadingText {
    objc_setAssociatedObject(self, @selector(currentLoadingText), currentLoadingText, OBJC_ASSOCIATION_RETAIN_NONATOMIC);
}


- (MBProgressHUD *)toastWithText:(NSString *)text {
    return [self toastWithText:text style:dfStyle];
}

- (MBProgressHUD *)toastWithText:(NSString *)text style:(TCToastStyle)style {
    return [self toastWithText:text hideAfterDelay:kToastDuration style:style];
}

- (MBProgressHUD *)toastWithText:(NSString *)text hideAfterDelay:(NSTimeInterval)delay {
    return [self toastWithText:text hideAfterDelay:delay style:dfStyle];
}

- (MBProgressHUD *)toastWithText:(NSString *)text hideAfterDelay:(NSTimeInterval)delay style:(TCToastStyle)style {
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
    [self configHud:hud style:style];
    return hud;
}

- (MBProgressHUD *)toastLoading {
    return [self toastLoadingWithStyle:dfStyle];
}

- (MBProgressHUD *)toastLoadingWithStyle:(TCToastStyle)style {
    return [self toastLoadingWithText:nil style:style];
}

- (MBProgressHUD *)toastLoadingWithText:(NSString *)text {
    return [self toastLoadingWithText:text style:dfStyle];
}

- (MBProgressHUD *)toastLoadingWithText:(NSString *)text style:(TCToastStyle)style {
    self.currentLoadingText = text;
    self.currentLoadingStyle = style;
    self.toastLoadingCount = self.toastLoadingCount+1;
    MBProgressHUD *hud = nil;
    if (!self.isToastLoading && self.throwerView.toastLoadingCount<=0) {
        self.isToastLoading = YES;
        hud = [MBProgressHUD showHUDAddedTo:self animated:YES];
        //这里可以考虑扩展容错机制，因外部调用toastLoading和toastHide没有正确配对，可能会造成屏幕锁住无法交互
        //[self performSelector:@selector(toastHide) withObject:nil afterDelay:30];
        if (![self isEmptyStr:text]) {
            hud.label.text = text;
        }
    }
    [self configHud:hud style:style];
    return hud;
}

- (void)configHud:(MBProgressHUD *)hud style:(TCToastStyle)style {
    if (!hud) {
        return;
    }
    if (style == TCToastStyleDark) {
        hud.bezelView.blurEffectStyle = UIBlurEffectStyleDark;
        hud.contentColor = [[UIColor whiteColor] colorWithAlphaComponent:0.9];
    }
}

- (void)toastHide {
    self.toastLoadingCount = self.toastLoadingCount-1;
    if (!self.isToastLoading || self.toastLoadingCount>0) {
        if (self.toastLoadingCount <= 0) {
            //未显示过loading，但是已经完成了任务，更换接球手
            self.throwerView.catcherView = self.catcherView;
            self.catcherView.throwerView = self.throwerView;
            //退隐江湖
            self.throwerView = nil;
            self.catcherView = nil;
        }
        return;
    }

    self.isToastLoading = NO;
    self.toastLoadingCount = 0;
    //[MBProgressHUD hideHUDForView:self animated:YES];
    for (UIView *subview in self.subviews) {
        if ([subview isKindOfClass:MBProgressHUD.class]) {
            MBProgressHUD *hud = (MBProgressHUD *)subview;
            if (!hud.isHudDelayHide) {
                [hud hideAnimated:YES];
            }
        }
    }

    self.catcherView.throwerView = nil;//这个需要在前
    if (self.catcherView.toastLoadingCount > 0 && !self.catcherView.isToastLoading) {
        self.catcherView.toastLoadingCount = self.catcherView.toastLoadingCount - 1;
        [self.catcherView toastLoadingWithText:self.catcherView.currentLoadingText
                                         style:self.catcherView.currentLoadingStyle];//抛球
    }
    self.catcherView = nil;//功成身退
}


+ (UIView *)appWindow {
    return [UIApplication sharedApplication].keyWindow;
}

+ (UIView *)currentView {
    return self.currentVC.view;
}

+ (UIViewController *)currentVC {
    return [self getCurrentVCFrom:nil];
}

+ (UIViewController *)getCurrentVCFrom:(UIViewController *)rootVC {
    if (!rootVC) {
        rootVC = [[[UIApplication sharedApplication] keyWindow] rootViewController];
    }
    UIViewController *currentVC;
    if ([rootVC presentedViewController]) {
        rootVC = [rootVC presentedViewController];
    }
    if ([rootVC isKindOfClass:[UITabBarController class]]) {
        currentVC = [self getCurrentVCFrom:[(UITabBarController *)rootVC selectedViewController]];
    } else if ([rootVC isKindOfClass:[UINavigationController class]]){
        currentVC = [self getCurrentVCFrom:[(UINavigationController *)rootVC visibleViewController]];
    } else {
        currentVC = rootVC;
    }
    return currentVC;
}

@end
