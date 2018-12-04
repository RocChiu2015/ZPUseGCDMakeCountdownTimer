//
//  ViewController.m
//  利用GCD制作倒计时器
//
//  Created by 赵鹏 on 2017/11/15.
//  Copyright © 2017年 赵鹏. All rights reserved.
//

#import "ViewController.h"

@interface ViewController ()

@property (weak, nonatomic) IBOutlet UIButton *beginCountDownButton;
@property (weak, nonatomic) IBOutlet UIButton *stopCountDownButton;
@property (weak, nonatomic) IBOutlet UITextField *textField;
@property (weak, nonatomic) IBOutlet UIScrollView *scrollView;
@property (nonatomic,strong) id timer;

@end

@implementation ViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    // Do any additional setup after loading the view, typically from a nib.
    
    [self.beginCountDownButton setTitle:@"获取验证码" forState:UIControlStateNormal];
    self.scrollView.contentSize = CGSizeMake(600, 200);
}

/**
 * 倒计时器的每次改变都是在主线程中对按钮的UI重新绘制，这时其他的耗时操作都需要在子线程中执行，否则在主线程中执行耗时操作的话会使倒计时器页面卡死，不能够更新按钮的UI；
 * 下面按钮的UI在主线程中每1秒更新一次，在第一次更新结束之后第二次开始更新之前，这个时候在主线程中插入执行一个耗时操作，因为在主线程中任务是串行执行的，所以就会阻止按钮的UI继续更新，在视觉上会造成倒计时器页面的卡死；
 * 拖动scrollView或在textField上输入文字虽然都是在主线程上执行任务，但是它们都是不耗时操作，所以不会造成倒计时器页面的卡死，按钮的UI照常在主线程上进行更新；
 * 当填写验证码时，一般会用到倒计时器，当收到验证码并且填写完毕的时候，点击其他按钮在主线程进行耗时操作的时候，必须杀死/停止定时器所在的那条子线程，否则倒计时器按钮无法更新UI，原因就是上述的第一条。
 */
- (IBAction)beginCountDown:(id)sender
{
    NSLog(@"%@", [NSThread currentThread]);
    
    __block NSInteger second = 60;
    
    //获取全局的并发队列
    dispatch_queue_t quene = dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0);
    //定时器模式，事件源
    dispatch_source_t timer = dispatch_source_create(DISPATCH_SOURCE_TYPE_TIMER, 0, 0, quene);
    /**
     * 下面的第二个参数，如果使用dispatch_time或者DISPATCH_TIME_NOW的话，系统会使用默认时钟来进行计时，但是当系统休眠的时候，默认时钟是不走的，也就会导致计时器停止。而使用dispatch_walltime可以让计时器按照真实时间间隔进行计时；
     * 下面的第三个参数，NSEC_PER_SEC * 1意味着每秒执行一次，对应的还有毫秒，分秒，纳秒可以选择；
     */
    dispatch_source_set_timer(timer, dispatch_walltime(NULL, 0), NSEC_PER_SEC * 1, 0);
    
    _timer = timer;
    
    /**
     * dispatch_source_set_event_handler函数中的任务是在子线程中执行的，若需要回到主线程，要调用主队列。
     * 这个函数在执行完之后，block会立马执行一遍，后面隔一定时间间隔再执行一次。而NSTimer第一次执行是倒计时器触发之后。这也是和NSTimer之间的一个显著区别。
     */
    dispatch_source_set_event_handler(timer, ^{
        NSLog(@"%@", [NSThread currentThread]);
        
        //回调主线程，在主线程中操作UI
        dispatch_async(dispatch_get_main_queue(), ^{
            NSLog(@"%@", [NSThread currentThread]);
            
            if (second >= 0)
            {
                [self.beginCountDownButton setTitle:[NSString stringWithFormat:@"(%ld)重发验证码",second] forState:UIControlStateNormal];
                second--;
                
                NSLog(@"$$$$$$$$");
            }else
            {
                //这句话必须写否则会出问题
                dispatch_source_cancel(timer);
                [self.beginCountDownButton setTitle:@"获取验证码" forState:UIControlStateNormal];
            }
        });
    });
    
    //启动源
    dispatch_resume(timer);
}

- (IBAction)stopCountDown:(id)sender
{
    //关闭定时器
    dispatch_source_cancel(_timer) ;
    
    /**
     * 挂起定时器
     * dispatch_suspend之后的Timer是不能被释放的，那样会引起崩溃
     */
//    dispatch_suspend(_timer);
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}


@end
