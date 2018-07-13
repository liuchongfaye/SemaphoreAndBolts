//
//  CCBoltsViewController.m
//  Interview
//
//  Created by 刘冲 on 2018/7/12.
//  Copyright © 2018年 刘冲. All rights reserved.
//

#import "CCBoltsViewController.h"
@import Bolts;
@import Masonry;

@interface CCBoltsViewController ()

@end

@implementation CCBoltsViewController

- (void)viewDidLoad {
    [super viewDidLoad];

    self.view.backgroundColor = [UIColor whiteColor];
    
    UIButton *semaphoreButton = [UIButton buttonWithType:UIButtonTypeCustom];
    semaphoreButton.backgroundColor = [UIColor redColor];
    [semaphoreButton setTitle:@"semaphore" forState:UIControlStateNormal];
    [semaphoreButton addTarget:self action:@selector(semaphore) forControlEvents:UIControlEventTouchUpInside];
    [self.view addSubview:semaphoreButton];
    
    UIButton *boltsConcurrenceButton = [UIButton buttonWithType:UIButtonTypeCustom];
    boltsConcurrenceButton.backgroundColor = [UIColor greenColor];
    [boltsConcurrenceButton setTitle:@"boltsConcurrence" forState:UIControlStateNormal];
    [boltsConcurrenceButton addTarget:self action:@selector(boltsConcurrence) forControlEvents:UIControlEventTouchUpInside];
    [self.view addSubview:boltsConcurrenceButton];
    
    UIButton *boltsSerialButton = [UIButton buttonWithType:UIButtonTypeCustom];
    boltsSerialButton.backgroundColor = [UIColor blueColor];
    [boltsSerialButton setTitle:@"boltsSerial" forState:UIControlStateNormal];
    [boltsSerialButton addTarget:self action:@selector(boltsSerial) forControlEvents:UIControlEventTouchUpInside];
    [self.view addSubview:boltsSerialButton];
    
    [semaphoreButton mas_makeConstraints:^(MASConstraintMaker *make) {
        make.leading.trailing.equalTo(self.view);
        make.height.mas_equalTo(70.0);
        make.top.equalTo(self.view.mas_top).offset(50.0);
    }];
    
    [boltsConcurrenceButton mas_makeConstraints:^(MASConstraintMaker *make) {
        make.leading.trailing.height.equalTo(semaphoreButton);
        make.top.equalTo(semaphoreButton.mas_bottom).offset(50.0);
    }];
    
    [boltsSerialButton mas_makeConstraints:^(MASConstraintMaker *make) {
        make.leading.trailing.height.equalTo(semaphoreButton);
        make.top.equalTo(boltsConcurrenceButton.mas_bottom).offset(50.0);
    }];
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

#pragma mark - semaphore
// 信号量并行执行多个任务
- (void)semaphore {
    NSLog(@"主线程开始执行");
    dispatch_semaphore_t semaphore = dispatch_semaphore_create(0);  // 创建一个信号量
    dispatch_group_t group = dispatch_group_create();               // 创建一个线程group
    dispatch_queue_t quene = dispatch_get_global_queue(0, 0);       // 创建一个线程队列
    dispatch_group_async(group, quene, ^{
        dispatch_async(dispatch_get_global_queue(0, 0), ^{
            NSLog(@"线程1");
            sleep(1);
            NSLog(@"线程1.1");
            dispatch_semaphore_signal(semaphore);
        });
    });
    dispatch_group_async(group, quene, ^{
        dispatch_async(dispatch_get_global_queue(0, 0), ^{
            NSLog(@"线程2");
            sleep(2);
            NSLog(@"线程2.1");
            dispatch_semaphore_signal(semaphore);
        });
    });
    dispatch_group_notify(group, quene, ^{
        // 两次信号等待
        dispatch_semaphore_wait(semaphore, DISPATCH_TIME_FOREVER);
        dispatch_semaphore_wait(semaphore, DISPATCH_TIME_FOREVER);
        // 开始执行第三个线程
        dispatch_async(dispatch_get_global_queue(0, 0), ^{
            NSLog(@"线程3");
            sleep(3);
            dispatch_async(dispatch_get_main_queue(), ^{
                NSLog(@"回到主线程");
            });
        });
    });
    NSLog(@"主线程执行完毕");
}

#pragma mark - Bolts
// Bolts并行执行多个任务
- (void)boltsConcurrence {
    [[BFTask taskForCompletionOfAllTasks:@[[self task1], [self task2]] ] continueWithBlock:^id _Nullable(BFTask * _Nonnull t) {
        if (t.error) {
#warning t.error为task1或者task2其中的错误，如果都失败了，那么则以先后顺序为主
            NSLog(@"失败:%@", t.error);
        } else {
#warning 当两个请求都成功时，t.result为nil
            NSLog(@"成功:%@", t.result);
        }
        return nil;
    }];
}
// Bolts串行执行多个任务
- (void)boltsSerial {
    [[[self task1] continueWithBlock:^id _Nullable(BFTask * _Nonnull t) {
        if (t.error) {
            // 如果task1失败了，那么就不执行task2，直接返回task1的BFTask对象
            return t;
        }
        // task1成功，执行task2
        return [self task2];
    }] continueWithBlock:^id _Nullable(BFTask * _Nonnull t) {
        if (t.error) {
            // 如果task1失败则打印task1的错误信息，task2亦然
            NSLog(@"task1或者task2至少其中之一失败:%@", t.error);
        } else {
            NSLog(@"task1或者task2全部成功，执行后续操作");
        }
        return nil;
    }];
}

- (BFTask *)task1 {
    // 创建一个source
    BFTaskCompletionSource *source = [BFTaskCompletionSource taskCompletionSource];
    // 数据请求1
    dispatch_async(dispatch_get_global_queue(0, 0), ^{
        sleep(1);
        BOOL isSuccess = YES;
        if (isSuccess) {
            // 请求成功，执行 setResult 方法
            [source setResult:@{@"key": @"success"}];
        } else {
            // 请求成功，执行 setError 方法
            [source setError:[NSError errorWithDomain:@"ErrorDomain" code:-1 userInfo:@{@"key": @"无网络"}]];
        }
    });
    return source.task;
}

- (BFTask *)task2 {
    // 创建一个source
    BFTaskCompletionSource *source = [BFTaskCompletionSource taskCompletionSource];
    // 数据请求2
    dispatch_async(dispatch_get_global_queue(0, 0), ^{
        sleep(2);
        BOOL isSuccess = NO;
        if (isSuccess) {
            // 请求成功，执行 setResult 方法
            [source setResult:@{@"key": @"success"}];
        } else {
            // 请求成功，执行 setError 方法
            [source setError:[NSError errorWithDomain:@"ErrorDomain" code:-1 userInfo:@{@"key": @"未登录"}]];
        }
    });
    return source.task;
}

@end
