//
//  KitNSLKView.h
//  KitPlayerCore
//
//  Created by ns on 2022/7/14.
//

#import <UIKit/UIKit.h>
@import GLKit;

#import "client.h"
#import "opengl_cb.h"

NS_ASSUME_NONNULL_BEGIN

@interface KitNSLKView : GLKView
{
    GLint defaultFBO;
    BOOL isStopDraw;
    dispatch_queue_t drawQueue;
}
@property BOOL isStopDraw;
@property dispatch_semaphore_t drawSem;
@property mpv_opengl_cb_context *mpvGL;
@property int width;
@property int height;
- (void)updateCBDraw;
@end

NS_ASSUME_NONNULL_END
