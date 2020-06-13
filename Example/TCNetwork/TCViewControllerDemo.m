//
//  TCViewControllerDemo.m
//  TCNetwork_Example
//
//  Created by fengunion on 2020/6/2.
//  Copyright © 2020 xtuck. All rights reserved.
//

#import "TCViewControllerDemo.h"
#import "CheckVersionApi.h"

@interface TCViewControllerDemo ()

@end

@implementation TCViewControllerDemo

- (void)viewDidLoad {
    [super viewDidLoad];
    // Do any additional setup after loading the view.
    self.view.backgroundColor = [UIColor lightGrayColor];

    dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(1 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
        [CheckVersionApi checkVersion].l_delegate(self).l_loadOnView(self.view).apiCall(^(CheckVersionApi *api){
            [UIView.appWindow toastWithText:[api.response description] hideAfterDelay:5];
            NSLog(@"原始数据为：\n%@",[api.response description]);
        });
    });
    

    //下滑该界面，可返回上级页面
}

- (void)viewDidDisappear:(BOOL)animated {
    [super viewDidDisappear:animated];
    NSLog(@"测试自动取消http请求");
    //请查看控制台日志
    [CheckVersionApi checkVersion].l_delegate(self).l_loadOnView(UIView.appWindow).apiCall(nil);
}

- (void)dealloc {
    NSLog(@"该对象已销毁");
}
/*
#pragma mark - Navigation

// In a storyboard-based application, you will often want to do a little preparation before navigation
- (void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender {
    // Get the new view controller using [segue destinationViewController].
    // Pass the selected object to the new view controller.
}
*/

@end
