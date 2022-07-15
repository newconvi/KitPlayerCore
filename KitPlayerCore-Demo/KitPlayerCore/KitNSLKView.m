//
//  KitNSLKView.m
//  KitPlayerCore
//
//  Created by ns on 2022/7/14.
//

#import "KitNSLKView.h"

@implementation KitNSLKView
@synthesize isStopDraw = isStopDraw;
- (id)initWithFrame:(CGRect)frame {
    self = [super initWithFrame:frame];
    if (self) {
        self.isStopDraw = false;
        //Minimal delay in video rendering and minimal impact on interface animation
        dispatch_queue_attr_t att = dispatch_queue_attr_make_with_qos_class(DISPATCH_QUEUE_SERIAL, QOS_CLASS_USER_INTERACTIVE, -1);
        
        drawQueue = dispatch_queue_create("com.sjw.KitPlayerCore", att);
        
        //Ensure that there is only one operation at a time
        self.drawSem = dispatch_semaphore_create(0);
        
        //4K definition video rendering is normal
        self.context = [[EAGLContext alloc] initWithAPI:kEAGLRenderingAPIOpenGLES3];
        if (!self.context) {
            NSLog(@"Failed to initialize OpenGLES 3.0 context");
            return self;
        }
        [EAGLContext setCurrentContext:self.context];
        
        self.drawableColorFormat = GLKViewDrawableColorFormatRGBA8888;
        self.drawableDepthFormat = GLKViewDrawableDepthFormatNone;
        self.drawableStencilFormat = GLKViewDrawableStencilFormatNone;
        
        self.width = self.bounds.size.width * self.contentScaleFactor;
        self.height = -self.bounds.size.height * self.contentScaleFactor;
        defaultFBO = -1;
        self.opaque = true;
        
        glClearColor(0, 0, 0, 0);
        glClear(GL_COLOR_BUFFER_BIT);
    }
    return self;
}

//openCB draw
- (void)canCBDraw {
    if (self.isStopDraw) {
        dispatch_semaphore_signal(self.drawSem);
        return;
    }
    if (defaultFBO == -1) {
        glGetIntegerv(GL_FRAMEBUFFER_BINDING, &defaultFBO);
    }
    if (self.mpvGL) {
        mpv_opengl_cb_draw(self.mpvGL, defaultFBO, self.width, self.height);
    }
    dispatch_semaphore_signal(self.drawSem);
}

//update rendered image in sub thread
- (void)updateCBDraw {
    dispatch_async(drawQueue, ^{
        [self display];
    });
    dispatch_semaphore_wait(self.drawSem, DISPATCH_TIME_FOREVER);
}

- (void)drawRect:(CGRect)rect {
    [self canCBDraw];
}

- (void)dealloc {
    
}
@end
