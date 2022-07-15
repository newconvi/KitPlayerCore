//
//  ViewController.m
//  KitPlayerCore-Demo
//
//  Created by ns on 2022/7/14.
//
#import <KitPlayerCore/KitPlayerCore.h>
#import "ViewController.h"
#import <AVKit/AVKit.h>
@interface ViewController ()<KitNSDelegate>
{
    KitNSMPVCore *mpvCoreView;
}
@end

@implementation ViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    // Do any additional setup after loading the view.
    mpvCoreView = [[KitNSMPVCore alloc] initWithFrame:CGRectMake(0, 0, 500, 300)];
    mpvCoreView.delegate = self;
    [self.view addSubview:mpvCoreView];
    [mpvCoreView initView];
    mpvCoreView.isLog = true;
    mpvCoreView.optionDic = @{@"vo":@"opengl-cb", @"hwdec":@"yes", @"hwdec-codecs": @"all"};
    mpvCoreView.url = @"http://127.0.0.1:9001/video-h265.mkv";
    mpvCoreView.headerDic = @{@"User-Agent":@"Mozilla/5.0 (Macintosh; Intel Mac OS X 10_15_7) AppleWebKit/605.1.15 (KHTML, like Gecko) Version/15.5 Safari/605.1.15"};
    [mpvCoreView open];
}

- (void)manageCoreEvent:(KitNSEventStatus)status {
    switch (status) {
        case KitNSStatusReadyToPlay:
            NSLog(@"It is ready to play, and relevant video parameters can be obtained");
            NSLog(@"duration: %f",mpvCoreView.duration);
            break;
        
        case KitNSStatusFailed:
            NSLog(@"play faild");
            break;
        
        case KitNSStatusAtItemEnd:
            NSLog(@"play item end");
            break;
            
        default:
            break;
    }
}

@end
