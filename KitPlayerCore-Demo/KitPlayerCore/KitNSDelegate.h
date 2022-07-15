//
//  KitNSDelegate.h
//  KitPlayerCore
//
//  Created by ns on 2022/7/15.
//

#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

typedef enum {
    KitNSStatusReadyToPlay,
    KitNSStatusFailed,
    KitNSStatusAtItemEnd,
} KitNSEventStatus;

@protocol KitNSDelegate <NSObject>
- (void)manageCoreEvent:(KitNSEventStatus)status;
@end

NS_ASSUME_NONNULL_END
