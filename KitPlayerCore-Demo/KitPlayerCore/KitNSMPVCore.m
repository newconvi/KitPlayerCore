//
//  KitNSMPVCore.m
//  KitPlayerCore
//
//  Created by ns on 2022/7/14.
//

#import "KitNSMPVCore.h"
#import "KitNSLKView.h"

@interface KitNSMPVCore ()
{
    mpv_handle *mpv;
    NSLock *shutdownLock;
    NSLock *parLock;
    BOOL isLoaded;
    BOOL isError;
    BOOL isManualStop;
    BOOL isInitTrack;
    NSMutableArray *subArray;
    NSMutableArray *audioArray;
}
@property (nonatomic) KitNSLKView *lkView;
- (void)readEvents;
@end

@implementation KitNSMPVCore

/*
// Only override drawRect: if you perform custom drawing.
// An empty implementation adversely affects performance during animation.
- (void)drawRect:(CGRect)rect {
    // Drawing code
}
*/

static inline void check_error(int status) {
    if (status < 0) {
        printf("mpv API error: %s\n", mpv_error_string(status));
    }
}

static void *get_proc_address(void *ctx, const char *name) {
    CFStringRef symbolName = CFStringCreateWithCString(kCFAllocatorDefault, name, kCFStringEncodingASCII);
    void *addr = CFBundleGetFunctionPointerForName(CFBundleGetBundleWithIdentifier(CFSTR("com.apple.opengles")), symbolName);
    CFRelease(symbolName);
    return addr;
}

static void wakeup(void *);

static void glupdate(void *ctx) {
    KitNSLKView *glView = (__bridge KitNSLKView *)ctx;
    if (!glView) {
        return;
    }
    if ([glView respondsToSelector:@selector(isStopDraw)]) {
        if (glView.isStopDraw) {
            return;
        }
    }
    //Determine whether updatecbdraw exists
    if ([glView respondsToSelector:@selector(updateCBDraw)]) {
        [glView updateCBDraw];
    }
}

static void wakeup(void *context) {
    KitNSMPVCore *a = (__bridge KitNSMPVCore *)context;
    if (!a) {
        return;
    }
    if ([a respondsToSelector:@selector(isStopEvent)]) {
        if (a.isStopEvent) {
            return;
        }
    }
    [a readEvents];
}

- (id)initWithFrame:(CGRect)frame {
    self = [super initWithFrame:frame];
    if (self) {
        
    }
    return self;
}

- (void)initView {
    subArray = [[NSMutableArray alloc] init];
    audioArray = [[NSMutableArray alloc] init];
    self.lkView = [[KitNSLKView alloc] initWithFrame:self.bounds];
    shutdownLock = [[NSLock alloc] init];
    parLock = [[NSLock alloc] init];
    mpv = mpv_create();
    
    check_error(mpv_request_log_messages(mpv, "status"));
    check_error(mpv_initialize(mpv));
    check_error(mpv_request_log_messages(mpv, "info"));
    
    mpv_opengl_cb_context *mpvGL = mpv_get_sub_api(mpv, MPV_SUB_API_OPENGL_CB);
    if (!mpvGL) {
        puts("libmpv does not have the opengl-cb sub-API.");
        return;
    }
    
    //[self.lkView display];
    
    self.lkView.mpvGL = mpvGL;
    int r = mpv_opengl_cb_init_gl(mpvGL, NULL, get_proc_address, NULL);
    if (r < 0) {
        puts("gl init has failed.");
        return;
    }
    mpv_opengl_cb_set_update_callback(mpvGL, glupdate, (__bridge void *)self.lkView);
    
    queue = dispatch_queue_create("com.sjw.mpv-open", DISPATCH_QUEUE_SERIAL);
    mpv_set_wakeup_callback(mpv, wakeup, (__bridge void *)self);
    [self addSubview:self.lkView];
}

- (void)setOptionDic:(NSDictionary *)optionDic {
    _optionDic = optionDic;
    if (optionDic) {
        NSDictionary *dic = optionDic;
        if (dic) {
            for (NSString *key in [dic allKeys]) {
                NSString *value = [dic valueForKey:key];
                mpv_set_option_string(mpv, key.UTF8String, value.UTF8String);
            }
        }
    }
}

- (void)setIsLog:(BOOL)isLog {
    _isLog = isLog;
    
    NSArray *paths = NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES);
    NSString *documentsDirectory = [paths objectAtIndex:0];
    
    //Enable log debugging
    if (isLog) {
        NSString *fileName = [NSString stringWithFormat:@"mpv-%@.log",[NSDate date]];
        NSString *logFile = [documentsDirectory stringByAppendingPathComponent:fileName];
        check_error(mpv_set_option_string(mpv, "log-file", logFile.UTF8String));
        NSLog(@"%@", logFile);
    }
}

- (void)setHeaderDic:(NSDictionary *)headerDic {
    _headerDic = headerDic;
    if (headerDic) {
        NSString *uaStr = [headerDic valueForKey:@"User-Agent"];
        if (uaStr) {
            mpv_set_option_string(mpv, "user-agent", uaStr.UTF8String);
        }
        NSString *tmpStr = [self formatParToStr:headerDic Format:@"%@: %@,"];
        if (tmpStr.length > 0) {
            mpv_set_option_string(mpv, "http-header-fields", tmpStr.UTF8String);
        }
    }
}

- (void)open {
    if (!mpv) {
        return;
    }
    if (!self.url) {
        NSLog(@"video url or audio url is empty");
        return;
    }
    isManualStop = true;
    dispatch_async(queue, ^{
        const char *cmd[] = {"loadfile", self.url.UTF8String, NULL};
        check_error(mpv_command(self->mpv, cmd));
    });
}

- (void)handleEvent:(mpv_event *)event {
    switch (event->event_id) {
        case MPV_EVENT_LOG_MESSAGE: {
            struct mpv_event_log_message *msg = (struct mpv_event_log_message *)event->data;
            printf("[%s] %s: %s", msg->prefix, msg->level, msg->text);
        }
            
        case MPV_EVENT_FILE_LOADED: {
            //NSLog(@"MPV_EVENT_FILE_LOADED");
            break;
        }
        
        case MPV_EVENT_PLAYBACK_RESTART: {
            NSLog(@"MPV_EVENT_PLAYBACK_RESTART");
            //Resources have been loaded, and it is confirmed that resource information such as width and height can be obtained
            if (isManualStop == false && isLoaded == false) {
                isLoaded = true;
                [self runCoreEvent:KitNSStatusReadyToPlay];
            }
            break;
        }
            
        case MPV_EVENT_END_FILE: {
            NSLog(@"MPV_EVENT_END_FILE");
            if (isManualStop == false) {
                if (isLoaded == false) {
                    isError = true;
                    //NSLog(@"open video error");
                    [self runCoreEvent:KitNSStatusFailed];
                    break;
                }
                [self runCoreEvent:KitNSStatusAtItemEnd];
            }
            break;
        }
            
        case MPV_EVENT_START_FILE: {
            NSLog(@"MPV_EVENT_START_FILE");
            isLoaded = false;
            isError = false;
            isManualStop = false;
            self.isStopEvent = false;
            isInitTrack = false;
            [subArray removeAllObjects];
            [audioArray removeAllObjects];
            break;
        }
            
        default:
            NSLog(@"event: %s\n", mpv_event_name(event->event_id));
    }
}

- (void)runCoreEvent:(KitNSEventStatus)status {
    if ([self.delegate respondsToSelector:@selector(manageCoreEvent:)]) {
        [self.delegate manageCoreEvent:status];
    }
}

- (void)readEvents {
    dispatch_async(queue, ^{
        while (self->mpv) {
            if (self.isStopEvent) {
                break;
            }
            mpv_event *event = mpv_wait_event(self->mpv, 0);
            if (event->event_id == MPV_EVENT_NONE) {
                break;
            }
            [self handleEvent:event];
        }
    });
}

- (void)shutDown {
    [shutdownLock lock];
    if (!mpv) {
        [shutdownLock unlock];
        return;
    }
    self.isStopEvent = true;
    if (_lkView) {
        self.lkView.isStopDraw = true;
    }
    mpv_set_wakeup_callback(mpv, NULL, NULL);
    mpv_opengl_cb_set_update_callback(self.lkView.mpvGL, NULL, NULL);
    
    mpv_opengl_cb_uninit_gl(self.lkView.mpvGL);
    mpv_detach_destroy(mpv);
    mpv = NULL;
    [shutdownLock unlock];
}

- (void)stop {
    if (!mpv) {
        return;
    }
    const char *cmd[] = {"stop", NULL};
    check_error(mpv_command(mpv, cmd));
}

- (void)pause {
    if (!mpv) {
        return;
    }
    if (!isLoaded) {
        return;
    }
    if (self.isStopEvent) {
        return;
    }
    int pause = 1;
    check_error(mpv_set_property(mpv, "pause", MPV_FORMAT_FLAG, &pause));
}

- (void)play {
    if (!mpv) {
        return;
    }
    if (!isLoaded) {
        return;
    }
    if (self.isStopEvent) {
        return;
    }
    int pause = 0;
    check_error(mpv_set_property(mpv, "pause", MPV_FORMAT_FLAG, &pause));
}

- (double)duration {
    [parLock lock];
    double_t duration;
    if (!mpv) {
        [parLock unlock];
        return 0.0;
    }
    if (!isLoaded) {
        [parLock unlock];
        return 0.0;
    }
    mpv_get_property(mpv, "duration", MPV_FORMAT_DOUBLE, &duration);
    [parLock unlock];
    return duration;
}

- (double)currentTime {
    [parLock lock];
    double_t time;
    if (!mpv) {
        [parLock unlock];
        return 0.0;
    }
    if (!isLoaded) {
        [parLock unlock];
        return 0.0;
    }
    check_error(mpv_get_property(mpv, "time-pos", MPV_FORMAT_DOUBLE, &time));
    [parLock unlock];
    return time;
}

- (double)remainTime {
    [parLock lock];
    double_t time;
    if (!mpv) {
        [parLock unlock];
        return 0.0;
    }
    if (!isLoaded) {
        [parLock unlock];
        return 0.0;
    }
    check_error(mpv_get_property(mpv, "time-remaining", MPV_FORMAT_DOUBLE, &time));
    [parLock unlock];
    return time;
}

- (double)width {
    [parLock lock];
    double_t width;
    if (!mpv) {
        [parLock unlock];
        return 0.0;
    }
    if (!isLoaded) {
        [parLock unlock];
        return 0.0;
    }
    mpv_get_property(mpv, "width", MPV_FORMAT_DOUBLE, &width);
    [parLock unlock];
    return width;
}

- (int)widthInt {
    NSString *widthStr = [self getParameterStr:@"video-params/w"];
    return widthStr.intValue;
}

- (int)heightInt {
    NSString *heightStr = [self getParameterStr:@"video-params/h"];
    return heightStr.intValue;
}

- (double)height {
    [parLock lock];
    double_t height;
    if (!mpv) {
        [parLock unlock];
        return 0.0;
    }
    if (!isLoaded) {
        [parLock unlock];
        return 0.0;
    }
    mpv_get_property(mpv, "height", MPV_FORMAT_DOUBLE, &height);
    [parLock unlock];
    return height;
}

- (NSString *)getParameterStr:(NSString *)key {
    [parLock lock];
    char *str;
    if (!mpv) {
        [parLock unlock];
        return @"";
    }
    if (!isLoaded) {
        [parLock unlock];
        return @"";
    }
    if (self.isStopEvent) {
        [parLock unlock];
        return @"";
    }
    int resultInt = mpv_get_property(mpv, key.UTF8String, MPV_FORMAT_STRING, &str);
    NSString *resultStr = @"";
    if (resultInt == 0) {
        //Release the object after successfully obtaining the results, otherwise it will crash
        mpv_free(str);
        resultStr = [[NSString alloc] initWithCString:str encoding:NSUTF8StringEncoding];
    }
    [parLock unlock];
    return resultStr;
}

- (void)setParameter:(NSString *)key String:(NSString *)value {
    if (!mpv) {
        return;
    }
    if (self.isStopEvent) {
        return;
    }
    const char *charValue = value.UTF8String;
    check_error(mpv_set_property(mpv, key.UTF8String, MPV_FORMAT_STRING, &charValue));
}

- (void)setParameter:(NSString *)key Double:(double)value {
    if (!mpv) {
        return;
    }
    if (self.isStopEvent) {
        return;
    }
    double_t ad = value;
    check_error(mpv_set_property(mpv, key.UTF8String, MPV_FORMAT_DOUBLE, &ad));
}

- (void)setParameter:(NSString *)key Int:(int)value {
    if (!mpv) {
        return;
    }
    if (self.isStopEvent) {
        return;
    }
    int64_t ad = value;
    check_error(mpv_set_property(mpv, key.UTF8String, MPV_FORMAT_INT64, &ad));
}

- (void)setParameter:(NSString *)key Enable:(BOOL)isCheck {
    if (!mpv) {
        return;
    }
    if (self.isStopEvent) {
        return;
    }
    int state = 0;
    if (isCheck) {
        state = 1;
    }
    check_error(mpv_set_property(mpv, key.UTF8String, MPV_FORMAT_FLAG, &state));
}

- (BOOL)isHDR {
    NSString *colorSpaceStr = [self getParameterStr:@"video-params/primaries"];
    if ([colorSpaceStr rangeOfString:@"bt.2020"].location != NSNotFound) {
        return true;
    }
    return false;
}

- (NSString *)videoFormat {
    NSString *videoFormatStr = [self getParameterStr:@"video-format"];
    return videoFormatStr;
}

- (double)fps {
    NSString *fpsStr = [self getParameterStr:@"container-fps"];
    if ([fpsStr isEqual:@""]) {
        fpsStr = [self getParameterStr:@"estimated-vf-fps"];
    }
    return fpsStr.doubleValue;
}

- (void)setIsMemoryCache:(BOOL)isMemoryCache {
    _isMemoryCache = isMemoryCache;
    NSString *str = @"no";
    if (isMemoryCache) {
        str = @"yes";
    }
    [self setParameter:@"cache" String:str];
}

- (void)setCacheSecs:(int)seconds {
    NSString *secStr = [NSString stringWithFormat:@"%d",seconds];
    [self setParameter:@"cache-secs" String:secStr];
}

- (void)setReadaheadSecs:(int)seconds {
    NSString *secStr = [NSString stringWithFormat:@"%d",seconds];
    [self setParameter:@"demuxer-readahead-secs" String:secStr];
}

- (void)setReadMaxBytes:(NSString *)str {
    [self setParameter:@"demuxer-max-bytes" String:str];
}

- (void)setBackMaxBytes:(NSString *)str {
    [self setParameter:@"demuxer-max-back-bytes" String:str];
}

- (void)setIsProbeInfo:(BOOL)isProbeInfo {
    _isProbeInfo = isProbeInfo;
    NSString *str = @"no";
    if (isProbeInfo) {
        str = @"yes";
    }
    [self setParameter:@"demuxer-lavf-probe-info" String:str];
}

- (void)setIsAutoSoft:(BOOL)isAutoSoft {
    _isAutoSoft = isAutoSoft;
    NSString *str = @"no";
    if (isAutoSoft) {
        str = @"yes";
    }
    [self setParameter:@"vd-lavc-software-fallback" String:str];
}

- (BOOL)isPlay {
    NSString *stateStr = [self getParameterStr:@"pause"];
    if ([stateStr isEqual:@"no"]) {
        return true;
    }
    return false;
}

- (void)setIsHardDecoding:(BOOL)isHardDecoding {
    _isHardDecoding = isHardDecoding;
    NSString *str = @"no";
    if (isHardDecoding) {
        str = @"yes";
        [self setParameter:@"hwdec-codecs" String:@"all"];
    }
    [self setParameter:@"hwdec" String:str];
}

- (void)setRenderMode:(NSString *)type {
    [self setParameter:@"vo" String:type];
}

- (void)setHardwareFormat:(NSString *)type {
    [self setParameter:@"hwdec-image-format" String:type];
}

- (NSString *)bitDepth {
    return [self getParameterStr:@"video-params/plane-depth"];
}

- (NSString *)audioFormat {
    return [self getParameterStr:@"audio-codec-name"];
}

- (NSString *)samplerate {
    return [self getParameterStr:@"audio-params/samplerate"];
}

- (NSString *)channelCount {
    return [self getParameterStr:@"audio-params/channel-count"];
}

- (NSString *)channelsType {
    return [self getParameterStr:@"audio-params/channels"];
}

- (NSString *)videoBitrate {
    return [self getParameterStr:@"video-bitrate"];
}

- (NSString *)audioBitrate {
    return [self getParameterStr:@"audio-bitrate"];
}

- (void)setAudioSpeed:(double)value {
    [self setParameter:@"speed" Double:value];
}

- (double)audioSpeed {
    NSString *speedStr = [self getParameterStr:@"speed"];
    return speedStr.doubleValue;
}

- (void)setAvOptionDic:(NSDictionary *)avOptionDic {
    _avOptionDic = avOptionDic;
    NSString *tmpStr = [self formatParToStr:avOptionDic Format:@"%@=%@,"];
    if (tmpStr.length > 0) {
        mpv_set_option_string(mpv, "demuxer-lavf-o", tmpStr.UTF8String);
    }
}

- (BOOL)isLive {
    if (self.duration < 120) {
        return true;
    }
    return false;
}

- (NSString *)formatParToStr:(NSDictionary *)dic Format:(NSString *)formatStr {
    if (dic) {
        NSMutableString *tmpStr = [[NSMutableString alloc] init];
        for (NSString *key in dic.allKeys) {
            NSString *value = [dic valueForKey:key];
            NSString *newKey = key;
            newKey = [newKey stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceAndNewlineCharacterSet]];
            value = [value stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceAndNewlineCharacterSet]];
            [tmpStr appendFormat:formatStr, newKey, value];
        }
        if (tmpStr.length > 0) {
            [tmpStr deleteCharactersInRange:NSMakeRange(tmpStr.length - 1, 1)];
            return tmpStr.copy;
        }
    }
    return @"";
}

- (void)setIsMute:(BOOL)isMute {
    NSString *str = @"no";
    if (isMute) {
        str = @"yes";
    }
    [self setParameter:@"mute" String:str];
}

- (BOOL)isMute {
    NSString *muteStr = [self getParameterStr:@"mute"];
    if ([muteStr isEqual:@"yes"]) {
        return true;
    }
    return false;
}

- (void)setResumeTime:(double)resumeTime {
    _resumeTime = resumeTime;
    [self setParameter:@"start" String:[NSString stringWithFormat:@"+%f",resumeTime]];
}

- (void)seekTime:(double)time isExact:(BOOL)isExa {
    if (!mpv) {
        return;
    }
    char *cmdStr = "absolute+keyframes";
    if (isExa) {
        cmdStr = "absolute+exact";
    }
    NSString *timeStr = [NSString stringWithFormat:@"%f", time];
    const char *cmd[] = {"seek", timeStr.UTF8String, cmdStr, NULL};
    check_error(mpv_command(mpv, cmd));
}

- (void)setIsNoAudio:(BOOL)isNoAudio {
    if (isNoAudio) {
        [self setParameter:@"aid" String:@"no"];
    }
}

- (void)setIsNoSub:(BOOL)isNoSub {
    if (isNoSub) {
        [self setParameter:@"sid" String:@"no"];
    }
}

//track-list json str
- (void)initTrackList {
    if (isInitTrack == false) {
        isInitTrack = true;
        NSString *countStr = [self getParameterStr:@"track-list/count"];
        int i;
        for (i = 0; i < countStr.intValue; i++) {
            NSMutableDictionary *dic = [[NSMutableDictionary alloc] init];
            NSString *idStr = [self getParameterStr:[NSString stringWithFormat:@"track-list/%d/id",i]];
            [dic setObject:idStr forKey:@"id"];
            
            NSString *typeStr = [self getParameterStr:[NSString stringWithFormat:@"track-list/%d/type",i]];
            [dic setObject:typeStr forKey:@"type"];
            
            NSString *titleStr = [self getParameterStr:[NSString stringWithFormat:@"track-list/%d/title",i]];
            [dic setObject:titleStr forKey:@"title"];
            
            NSString *langStr = [self getParameterStr:[NSString stringWithFormat:@"track-list/%d/lang",i]];
            [dic setObject:langStr forKey:@"lang"];
            
            NSString *codecStr = [self getParameterStr:[NSString stringWithFormat:@"track-list/%d/codec",i]];
            [dic setObject:codecStr forKey:@"codec"];
            
            NSString *audioChannelCountStr = [self getParameterStr:[NSString stringWithFormat:@"track-list/%d/demux-channel-count",i]];
            [dic setObject:audioChannelCountStr forKey:@"audioChannelCount"];
            
            NSString *audioSampleRateStr = [self getParameterStr:[NSString stringWithFormat:@"track-list/%d/demux-samplerate",i]];
            [dic setObject:audioSampleRateStr forKey:@"audioSampleRate"];
            
            if ([typeStr isEqual:@"audio"]) {
                [audioArray addObject:dic];
            }else if ([typeStr isEqual:@"sub"]) {
                [subArray addObject:dic];
            }
        }
    }
}

- (void)addSubtitle:(NSString *)str {
    if (!mpv) {
        return;
    }
    dispatch_async(queue, ^{
        const char *cmd[] = {"sub-add", str.UTF8String, NULL};
        check_error(mpv_command(self->mpv, cmd));
    });
}

- (void)addAudio:(NSString *)str {
    if (!mpv) {
        return;
    }
    dispatch_async(queue, ^{
        const char *cmd[] = {"audio-add", str.UTF8String, NULL};
        check_error(mpv_command(self->mpv, cmd));
    });
}

- (void)setFontName:(NSString *)fontName {
    [self setParameter:@"sub-font" String:fontName];
}

- (void)setFontSize:(int)fontSize {
    [self setParameter:@"sub-font-size" Int:fontSize];
}

- (void)setFontMarginY:(int)fontMarginY {
    [self setParameter:@"sub-margin-y" Int:fontMarginY];
}

- (NSInteger)audioCount {
    [self initTrackList];
    return audioArray.count;
}

- (NSInteger)subtitleCount {
    [self initTrackList];
    return subArray.count;
}

- (void)setSubIndex:(int)index {
    [self setParameter:@"sid" Int:index];
}

- (void)setAudioIndex:(int)index {
    [self setParameter:@"aid" Int:index];
}
@end
