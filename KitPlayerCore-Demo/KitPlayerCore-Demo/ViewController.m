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
    mpvCoreView = [[KitNSMPVCore alloc] initWithFrame:CGRectMake(0, 0, 1920, 1080)];
    mpvCoreView.delegate = self;
    [self.view addSubview:mpvCoreView];
    [mpvCoreView initView];
    mpvCoreView.isLog = true;
    //mpvCoreView.optionDic = @{@"vo":@"opengl-cb", @"hwdec":@"yes", @"hwdec-codecs": @"all"};
    [mpvCoreView setRenderMode:@"libmpv"];
    mpvCoreView.isHardDecoding = false;
    [mpvCoreView setHardwareFormat:@"uyvy422"];
    //mpvCoreView.avOptionDic = @{@"maxPacketSize3":@"20481", @"maxPacketSize":@"20481"};
    mpvCoreView.fontSize = 20;
    mpvCoreView.url = @"http://127.0.0.1:9001/LG.4K.DEMO_Colors.of.Journey-HDR.ts";
    mpvCoreView.headerDic = @{@"User-Agent":@"Mozilla/5.0 (Macintosh; Intel Mac OS X 10_15_7) AppleWebKit/605.1.15 (KHTML, like Gecko) Version/15.5 Safari/605.1.15",@"Origin":@"https://www.bilibili.com",@"Referer":@"https://www.bilibili.com/"};
    //mpvCoreView.resumeTime = 50;
    [mpvCoreView open];
    [mpvCoreView addSubtitle:@"http://127.0.0.1:9001/Venom.2018.srt"];
}

- (IBAction)doTest:(id)sender {
    [mpvCoreView stop];
    //[NSThread sleepForTimeInterval:3];
    //mpvCoreView.url = @"http://127.0.0.1:9001/video-h265.mkv";
    //mpvCoreView.headerDic = @{@"User-Agent":@"Mozilla/5.0 (Macintosh; Intel Mac OS X 10_15_7) AppleWebKit/605.1.15 (KHTML, like Gecko) Version/15.5 Safari/605.1.15"};
    //[mpvCoreView open];
    //[mpvCoreView seekTime:20 isExact:true];
}

- (void)manageCoreEvent:(KitNSEventStatus)status {
    switch (status) {
        case KitNSStatusReadyToPlay:
            NSLog(@"It is ready to play, and relevant video parameters can be obtained");
            NSLog(@"duration: %f",mpvCoreView.duration);
            NSLog(@"fps: %f",mpvCoreView.fps);
            NSLog(@"width: %f",mpvCoreView.width);
            NSLog(@"channelsType: %@",mpvCoreView.channelsType);
            NSLog(@"track: %@",[mpvCoreView getParameterStr:@"track-list/count"]);
            NSLog(@"bit: %@",[mpvCoreView getParameterStr:@"eof-reached"]);
            NSLog(@"%@",[mpvCoreView getParameterStr:@"video-codec"]);
            NSLog(@"解码: %@",[mpvCoreView getParameterStr:@"video-params/pixelformat"]);
            //NSLog(@"%@",[mpvCoreView getParameterStr:@"video-params/par"]);
            NSLog(@"%@",[mpvCoreView getParameterStr:@"video-params/plane-depth"]);
            NSLog(@"结果: %@",[mpvCoreView getParameterStr:@"track-list"]);
            if (mpvCoreView.isLive) {
                NSLog(@"正在直播...");
            }
            if (mpvCoreView.isHDR) {
                NSLog(@"确定是HDR视频");
            }
            NSLog(@"currentTime: %f",mpvCoreView.currentTime);
            //mpvCoreView.isProbeInfo
            //NSLog(@"%@",[mpvCoreView getParameterStr:@"estimated-vf-fps"]);
            //NSLog(@"fps: %@",mpvCoreView.fpsStr);
            //NSLog(@"%@",[mpvCoreView getParameterStr:@"display-fps"]);
            if (mpvCoreView.isPlay) {
                NSLog(@"正在播放");
            }
            
            [NSThread sleepForTimeInterval:5];
            [mpvCoreView setAudioSpeed:2.0];
            NSLog(@"bit: %@",[mpvCoreView getParameterStr:@"video-bitrate"]);
            //NSLog(@"pause: %@",[mpvCoreView getParameterStr:@"pause"]);
            //[mpvCoreView setParameter:@"pause" Enable:true];
            if (mpvCoreView.isPlay) {
                NSLog(@"正在播放 2");
            }else{
                NSLog(@"已经暂停");
            }
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
