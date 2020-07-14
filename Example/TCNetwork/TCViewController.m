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

- (void)exeBlock:(dispatch_block_t)block {
    if (block) {
        block();
    }
}

- (void)viewDidLoad {
    [super viewDidLoad];
    //线程测试
    dispatch_semaphore_t lock = dispatch_semaphore_create(0);
    dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(2 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
        dispatch_semaphore_signal(lock);
    });
    
    dispatch_queue_t queue = dispatch_queue_create("cancelhttptask11111", DISPATCH_QUEUE_SERIAL);

    dispatch_queue_t queue2 = dispatch_queue_create("cancelhttptask22222", DISPATCH_QUEUE_SERIAL);

    dispatch_async(queue, ^{
       
        dispatch_block_t tBlock = ^{
            NSThread *t2 = [NSThread currentThread];
            NSLog(@"线程测试11111:%@",t2.description);
        };
        
        NSThread *t1 = [NSThread currentThread];
        NSLog(@"线程测试000000:%@",t1.description);
        
        if ([NSThread isMainThread]) {
            dispatch_async(queue2, ^{
                NSThread *t3 = [NSThread currentThread];
                NSLog(@"线程测试33333:%@",t3.description);
                dispatch_semaphore_wait(lock, DISPATCH_TIME_FOREVER);
                [self performSelector:@selector(exeBlock:) onThread:t1  withObject:tBlock waitUntilDone:YES modes:@[NSRunLoopCommonModes]];
            });

        } else{
            dispatch_sync(queue2, ^{
                NSThread *t3 = [NSThread currentThread];
                NSLog(@"线程测试33333:%@",t3.description);
                dispatch_semaphore_wait(lock, DISPATCH_TIME_FOREVER);
                [self performSelector:@selector(exeBlock:) onThread:t1  withObject:tBlock waitUntilDone:YES modes:@[NSRunLoopCommonModes]];
            });

        }

    });
    
    return;
    
    
    
    
    
    
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
        [CoinLoginApi loginWithUsername:@"18811111111" pwd:@"123456"].l_delegate(self).l_loadOnView(self.view).apiCallSuccess(^(id res) {
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
