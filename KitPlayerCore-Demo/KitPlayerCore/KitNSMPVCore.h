//
//  KitNSMPVCore.h
//  KitPlayerCore
//
//  Created by ns on 2022/7/14.
//

#import <UIKit/UIKit.h>
#import <KitPlayerCore/KitNSDelegate.h>
NS_ASSUME_NONNULL_BEGIN

@interface KitNSMPVCore : UIView
{
    dispatch_queue_t queue;
}
///mpv core event delegate
@property (nonatomic, readwrite, strong) id<KitNSDelegate> delegate;
@property (nonatomic) BOOL isStopEvent;
///Enable log debugging
@property (nonatomic) BOOL isLog;
///Video url or Audio url
@property (nonatomic) NSString *url;
///MPV set configuration options
@property (nonatomic) NSDictionary *optionDic;
///MPV set requet header
@property (nonatomic) NSDictionary *headerDic;
///return video total time
@property (nonatomic) double duration;
///return video current time
@property (nonatomic) double currentTime;
///return the width of video definition
@property (nonatomic) double width;
///return the height of video definition
@property (nonatomic) double height;
//1. initView 2. setOptionDic 3. open
///init mpv view
- (void)initView;
///start open url
- (void)open;
///close mpv frame
- (void)shutDown;
- (void)stop;
- (void)play;
@end

NS_ASSUME_NONNULL_END
