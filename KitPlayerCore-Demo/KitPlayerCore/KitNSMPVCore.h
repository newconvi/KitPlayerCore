//
//  KitNSMPVCore.h
//  KitPlayerCore
//
//  Created by ns(sjw) on 2022/7/14.
//
//Third Party Libraries Used by KitPlayerCore
//This software uses libmpv and FFmpeg libraries from the under the LGPL
//https://www.gnu.org/licenses/lgpl-2.1.html
//source code: https://github.com/newconvi/KitPlayerCore

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
///set ffmpeg option
///key cannot contain special symbols ( such as maxPacketSize )
@property (nonatomic) NSDictionary *avOptionDic;
///return video total time
@property (nonatomic) double duration;
///return video current time
@property (nonatomic) double currentTime;
///retuen video remain time
@property (nonatomic) double remainTime;
///return the width of video definition
@property (nonatomic) double width;
///width video-params/w to int
@property (nonatomic) int widthInt;
///return the height of video definition
@property (nonatomic) double height;
///height video-params/w to int
@property (nonatomic) int heightInt;
///video is HDR
@property (nonatomic) BOOL isHDR;
///get video format( such as: hevc h264 vp9 )
@property (nonatomic) NSString *videoFormat;
@property (nonatomic) NSString *audioFormat;
///get video fps
@property (nonatomic) double fps;
//get playing state
@property (nonatomic) BOOL isPlay;
///video bit depth
@property (nonatomic) NSString *bitDepth;
@property (nonatomic) NSString *samplerate;
@property (nonatomic) NSString *channelCount;
@property (nonatomic) NSString *channelsType;
///video bitrate, Do not refresh regularly to get results
@property (nonatomic) NSString *videoBitrate;
///audio bitrate, Do not refresh regularly to get results
@property (nonatomic) NSString *audioBitrate;
///get audio speed
@property (nonatomic) double audioSpeed;
///network cache is memory, yes|no|auto
@property (nonatomic) BOOL isMemoryCache;
///avformat_find_stream_info, but it can also make startup slower
@property (nonatomic) BOOL isProbeInfo;
///fallback to software decoding if the hardware-accelerated decoder fails( 3 )
@property (nonatomic) BOOL isAutoSoft;
///enable hardware decode
@property (nonatomic) BOOL isHardDecoding;
@property (nonatomic) BOOL isLive;
///set current video mute
@property (nonatomic) BOOL isMute;
///jump time when starting video loading, use before open a function
@property (nonatomic) double resumeTime;
///close audio track
@property (nonatomic) BOOL isNoAudio;
///close subtitle track
@property (nonatomic) BOOL isNoSub;
///mpv font name
@property (nonatomic) NSString *fontName;
///mpv font size, defalut is 55
@property (nonatomic) int fontSize;
///mpv font Margin Y, defalut is 22
@property (nonatomic) int fontMarginY;
@property (nonatomic) NSInteger audioCount;
@property (nonatomic) NSInteger subtitleCount;
//1. initView 2. setOptionDic 3. open
///init mpv view
- (void)initView;
///start open url
- (void)open;
///close mpv lib
- (void)shutDown;
- (void)stop;
///continue playing
- (void)play;
///pause video after playing video
- (void)pause;
///get parameters of video
- (NSString *)getParameterStr:(NSString *)key;
///set video parameters, value is string
- (void)setParameter:(NSString *)key String:(NSString *)value;
///set video parameters, value is bool
- (void)setParameter:(NSString *)key Enable:(BOOL)isCheck;
- (void)setParameter:(NSString *)key Double:(double)value;
///prefetch 20 seconds, maxBytes > CacheSecs > ReadaheadSecs
- (void)setCacheSecs:(int)seconds;
///prefetch 20 seconds, ReadaheadSecs < CacheSecs < maxBytes
- (void)setReadaheadSecs:(int)seconds;
///prefetch max video bytes ( 20240KiB, MiB, GiB )
- (void)setReadMaxBytes:(NSString *)str;
///if is memory cache, this option enable,  memory video past data allowed to preserve
///( 20240KiB, MiB, GiB )
- (void)setBackMaxBytes:(NSString *)str;
///mpv render  mode
- (void)setRenderMode:(NSString *)type;
///Set the internal pixel format used by hardware decoding ( uyvy422 )
- (void)setHardwareFormat:(NSString *)type;
///set audio speed
- (void)setAudioSpeed:(double)value;
- (void)seekTime:(double)time isExact:(BOOL)isExa;
- (void)addSubtitle:(NSString *)str;
- (void)addAudio:(NSString *)str;
- (void)initTrackList;
- (void)setSubIndex:(int)index;
- (void)setAudioIndex:(int)index;
@end

NS_ASSUME_NONNULL_END
