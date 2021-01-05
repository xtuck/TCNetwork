//
//  TCViewController.m
//  TCNetwork
//
//  Created by xtuck on 05/31/2020.
//  Copyright (c) 2020 xtuck. All rights reserved.
//

#import "TCViewController.h"
#import "LoginApi.h"
#import "TCViewControllerDemo.h"
#import "CoinLoginApi.h"

@interface TCViewController ()

@end

@implementation TCViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    self.view.backgroundColor = [UIColor lightGrayColor];
    [self.view toastWithText:@"即将自动登录" hideAfterDelay:2];
        
    dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(2.5 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
        //block里面使用weakSelf，避免对象延迟释放
        //作用：比如，在弱网环境下，请求结果还未返回，就返回了上级页面，那么当前页面应该立即销毁，不应该被延迟释放
        //.l_delegate(self)参数设置，目的就是为了hook它的dealloc方法，对象销毁时自动取消请求
        __weak typeof(self) weakSelf = self;
        [LoginApi loginWithUsername:@"13888888888" pwd:@"123456"].l_delegate(self).l_loadOnView(self.view).apiCallSuccess(^(id res){
            [weakSelf.view toastWithText:@"登录成功" hideAfterDelay:1.5];
            [weakSelf performSelector:@selector(aotoLoginTest2) withObject:nil afterDelay:2];
        });;
    });
}

- (void)aotoLoginTest2 {
    [self.view toastWithText:@"即将进行第二次自动登录"];
    dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(2.5 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
        __weak typeof(self) weakSelf = self;
        [CoinLoginApi loginWithUsername:@"13888888888" pwd:@"123456"].l_delegate(self).l_loadOnView(self.view).apiCallSuccess(^(id res) {
            [weakSelf.view toastWithText:@"再次---登录成功" hideAfterDelay:3];
        });;
    });
}


- (IBAction)nextVC:(UIButton *)sender {
    TCViewControllerDemo *vc = [[TCViewControllerDemo alloc] init];
    [self presentViewController:vc animated:YES completion:nil];
}

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

@end
