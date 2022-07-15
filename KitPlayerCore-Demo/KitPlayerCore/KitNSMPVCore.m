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
    BOOL isLoaded;
    BOOL isError;
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
    self.lkView = [[KitNSLKView alloc] initWithFrame:self.bounds];
    self.isStopEvent = false;
    isLoaded = false;
    isError = false;
    shutdownLock = [[NSLock alloc] init];
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
        NSDictionary *dic = headerDic;
        if (dic) {
            NSMutableString *tmpStr = [[NSMutableString alloc] init];
            for (NSString *key in [dic allKeys]) {
                NSString *newKey = key;
                newKey = [newKey stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceAndNewlineCharacterSet]];
                if (![newKey isEqual:@"User-Agent"]) {
                    NSString *value = [dic valueForKey:newKey];
                    value = [value stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceAndNewlineCharacterSet]];
                    [tmpStr appendFormat:@"%@: %@,", newKey, value];
                }
            }
            if (tmpStr.length > 0) {
                [tmpStr deleteCharactersInRange:NSMakeRange(tmpStr.length - 1, 1)];
                mpv_set_option_string(mpv, "http-header-fields", tmpStr.UTF8String);
            }
        }
    }
}

- (void)open {
    if (!self.url) {
        NSLog(@"video url or audio url is empty");
        return;
    }
    dispatch_async(queue, ^{
        mpv_set_wakeup_callback(self->mpv, wakeup, (__bridge void *)self);
        
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
            if (isLoaded == false) {
                isLoaded = true;
                [self runCoreEvent:KitNSStatusReadyToPlay];
            }
            break;
        }
            
        case MPV_EVENT_END_FILE: {
            NSLog(@"MPV_EVENT_END_FILE");
            if (isLoaded == false) {
                isError = true;
                //NSLog(@"open video error");
                [self runCoreEvent:KitNSStatusFailed];
                break;
            }
            [self runCoreEvent:KitNSStatusAtItemEnd];
            break;
        }
            
        case MPV_EVENT_START_FILE: {
            NSLog(@"MPV_EVENT_START_FILE");
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
    const char *cmd[] = {"stop", NULL};
    check_error(mpv_command(mpv, cmd));
}

- (void)pause {
    int pause = 1;
    check_error(mpv_set_property(mpv, "pause", MPV_FORMAT_FLAG, &pause));
}

- (void)play {
    int pause = 0;
    check_error(mpv_set_property(mpv, "pause", MPV_FORMAT_FLAG, &pause));
}

- (double)duration {
    double duration = 0.0;
    if (!mpv) {
        return 0.0;
    }
    if (!isLoaded) {
        return 0.0;
    }
    check_error(mpv_get_property(mpv, "duration", MPV_FORMAT_DOUBLE, &duration));
    return duration;
}

- (double)currentTime {
    double time = 0.0;
    if (!mpv) {
        return 0.0;
    }
    if (!isLoaded) {
        return 0.0;
    }
    check_error(mpv_get_property(mpv, "time-pos", MPV_FORMAT_DOUBLE, &time));
    return time;
}

- (double)width {
    double width = 0.0;
    if (!mpv) {
        return 0.0;
    }
    if (!isLoaded) {
        return 0.0;
    }
    check_error(mpv_get_property(mpv, "width", MPV_FORMAT_DOUBLE, &time));
    return width;
}

- (double)height {
    double height = 0.0;
    if (!mpv) {
        return 0.0;
    }
    if (!isLoaded) {
        return 0.0;
    }
    check_error(mpv_get_property(mpv, "height", MPV_FORMAT_DOUBLE, &time));
    return height;
}
@end
