//
//  ThreadOperationController.m
//  iPhoneXLayout
//
//  Created by golong on 2017/12/11.
//  Copyright © 2017年 XLsn0w. All rights reserved.
//

#import "ThreadOperationController.h"

@interface ThreadOperationController ()

@end

@implementation ThreadOperationController


/**
 NSOperation是Objective-C中一种高级的并发处理方法，现在对GCD的封装;功能比GCD更强大！
 
 
 两个概念
 操作；
 操作队列；
 
 NSOperation多线程实现步骤
 实现多线程的步骤就是，把操作添加到操作队列中。
 
 
 两个操作：NSInvocationOperation，NSBlockOperation
 两个操作队列：主队列、非主队列；
 
 队列：
 队列的创建方法：
 主队列：
 NSOperationQueue *queue = [NSOperationQueue mainQueue];
 
 非主队列：
 NSOperationQueue *queue = [[NSOperationQueue alloc] init];
 
 队列添加任务的方法三个
 添加单个操作：
 - (void)addOperation:(NSOperation *)op;
 添加多个操作：
 - (void)addOperations:(NSArray<NSOperation *> *)ops waitUntilFinished:(BOOL)wait NS_AVAILABLE(10_6, 4_0);
 
 添加block操作：
 - (void)addOperationWithBlock:(void (^)(void))block NS_AVAILABLE(10_6, 4_0);
 
 
 操作：
 NSOperation是一个抽象类，也就是说NSOperation本身不具备封装操作的能力，需要使用它的两个子类：
 NSInvocationOperation
 NSBlockOperation
 
 操作：NSInvocationOperation
 
 方式一、NSInvocationOperation ＋strat方法
 1、创建NSInvocationOperation对象
 - (id)initWithTarget:(id)target selector:(SEL)selobject:(id)arg;
 2、调用start方法开始执行操作
 - (void)start;
 一旦执行操作，就会调用target的sel方法
 注意：默认调用了start方法后并不会开一条新线程去执行操作，而是在当前线程同步情况下，执行操作；
 
 方式二、NSInvocationOperation ＋主队列；
 1、创建NSInvocationOperation对象
 - (id)initWithTarget:(id)target selector:(SEL)selobject:(id)arg;
 2、创建主队列
 NSOperationQueue *queue = [NSOperationQueuemainQueue];
 3、添加操作到主队列
 - (void)addOperation:(NSOperation *)op;
 
 方式三、NSInvocationOperation ＋非队列；
 1、创建NSInvocationOperation对象
 - (id)initWithTarget:(id)target selector:(SEL)selobject:(id)arg;
 2、创建非主队列
 NSOperationQueue *queue = [[NSOperationQueuealloc]init];
 3、添加操作到主队列
 - (void)addOperation:(NSOperation *)op;
 
 操作：NSBlockOperation
 方式一、NSBlockOperation ＋主队列
 1、创建NSBlockOperation对象
 NSBlockOperation *blockOp = [NSBlockOperation blockOperationWithBlock:^{
 //任务代码
 }];
 2、创建非主队列
 NSOperationQueue *queue = [NSOperationQueue mainQueue];
 3、添加操作到主队列
 [queue addOperation:blockOp];
 方式二、NSBlockOperation ＋ 非主队列
 1、创建NSBlockOperation对象
 NSBlockOperation *blockOp = [NSBlockOperation blockOperationWithBlock:^{
 //任务代码
 }];
 2、创建非主队列
 NSOperationQueue *queue = [[NSOperationQueue alloc] init];
 3、添加操作到非主队列
 [queue addOperation:blockOp];
 
 追加操作：
 - (void)addExecutionBlock:(void (^)(void))block;
 
 
 NSOperationQueue管理
 1、最大并发数（同时执行的任务数）
 方法：
 最大并发数的相关方法
 - (NSInteger)maxConcurrentOperationCount;
 - (void)setMaxConcurrentOperationCount:(NSInteger)cnt;
 
 2、队列的取消、暂停、恢复
 取消队列的所有操作
 - (void)cancelAllOperations;
 提示：也可以调用NSOperation的- (void)cancel方法取消单个操作
 暂停和恢复队列
 - (void)setSuspended:(BOOL)b; // YES代表暂停队列，NO代表恢复队列
 - (BOOL)isSuspended;
 3、操作依赖
 [operationB addDependency:operationA]; // 操作B依赖于操作A
 
 操做依赖：——线程同步技术
 ［op2 addDependency op1］;
 不在同一个操作队列中的操作可以添加依赖！
 
 注意：必须放在  添加操作队列之前；
 忌：循环依赖；
 
 自定义NSOperation
 将操作添加到队列中的时候，会调用main方法；
 - (void)main方法，在里面实现想执行的任务；
 自定义NSOperation的时，只需要重写main方法即可；
 
 */
- (void)viewDidLoad {
    [super viewDidLoad];
    // Do any additional setup after loading the view.

}

-(void)dispatchSignal{
    //crate的value表示，最多几个资源可访问
    dispatch_semaphore_t semaphore = dispatch_semaphore_create(2);
    dispatch_queue_t quene = dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0);
    
    //任务1
    dispatch_async(quene, ^{
        dispatch_semaphore_wait(semaphore, DISPATCH_TIME_FOREVER);
        NSLog(@"run task 1");
        sleep(1);
        NSLog(@"complete task 1");
        dispatch_semaphore_signal(semaphore);
    });
    
    //任务2
    dispatch_async(quene, ^{
        dispatch_semaphore_wait(semaphore, DISPATCH_TIME_FOREVER);
        NSLog(@"run task 2");
        sleep(1);
        NSLog(@"complete task 2");
        dispatch_semaphore_signal(semaphore);
    });
    
    //任务3
    dispatch_async(quene, ^{
        dispatch_semaphore_wait(semaphore, DISPATCH_TIME_FOREVER);
        NSLog(@"run task 3");
        sleep(1);
        NSLog(@"complete task 3");
        dispatch_semaphore_signal(semaphore);
    });
    
    
//    首先创建并行队列，创建队列组，将队列和需要处理的网络请求分别添加到组中，当组中所有队列处理完事件后调用dispatch_group_notify，我们需要在里边处理事件E。由于队列在处理网络请求时将”发送完一个请求”作为事件完成的标记（此时还未获得网络请求返回数据），所以在这里需要用信号量进行控制，在执行dispatch_group_notify前发起信号等待（4次信号等待，分别对应每个队列的信号通知），在每个队列获取到网络请求返回数据时发出信号通知。这样就能完成需求中的要求。
//
//    如果需求中改为：同时存在A,B,C,D四个任务，要求ABCD依次进行处理，当上一个完成时再进行下一个任务，当四个任务都完成时再处理事件E。这时只需要将队列改为串行队列即可（不在需要信号量控制）。
    //创建信号量/
//    dispatch_semaphore_t semaphore = dispatch_semaphore_create(0);
    //创建全局并行/
    dispatch_queue_t queue = dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0);
    dispatch_group_t group = dispatch_group_create();
    dispatch_group_async(group, queue, ^{

        for (int i = 0; i<10000; i++) {
            NSLog(@"打印i %d",i);
        }
        dispatch_semaphore_signal(semaphore);
    });
    dispatch_group_async(group, queue, ^{
        NSLog(@"处理事件B");
        for (int i = 0; i<10000; i++) {
            NSLog(@"打印j %d",i);
        }
        dispatch_semaphore_signal(semaphore);
    });
    dispatch_group_async(group, queue, ^{
        NSLog(@"处理事件C");
        for (int i = 0; i<10000; i++) {
            NSLog(@"打印k %d",i);
        }
        dispatch_semaphore_signal(semaphore);
    });
    dispatch_group_async(group, queue, ^{
        NSLog(@"处理事件D");
        for (int i = 0; i<10000; i++) {
            NSLog(@"打印l %d",i);
        }
        dispatch_semaphore_signal(semaphore);
    });
    
    dispatch_group_notify(group, queue, ^{
        /四个请求对应四次信号等待/
        dispatch_semaphore_wait(semaphore, DISPATCH_TIME_FOREVER);
        dispatch_semaphore_wait(semaphore, DISPATCH_TIME_FOREVER);
        dispatch_semaphore_wait(semaphore, DISPATCH_TIME_FOREVER);
        dispatch_semaphore_wait(semaphore, DISPATCH_TIME_FOREVER);
        NSLog(@"处理事件E");
    });
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
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
