//
//  AVQueuePlayerPrevious.h
//
//  Based on AVQueuePlayerPrevious by Daniel Giovannelli.

#import <AVFoundation/AVFoundation.h>

@class AVQueuePlayerPrevious;

@protocol AVQueuePlayerPreviousDelegate <NSObject>

- (void)queuePlayerDidReceiveNotificationForSongIncrement:(AVQueuePlayerPrevious *)previousPlayer;

@end

@interface AVQueuePlayerPrevious : AVQueuePlayer

@property (nonatomic, weak) id <AVQueuePlayerPreviousDelegate> delegate;
@property (nonatomic, readonly) NSArray *itemsForPlayer;
@property (nonatomic, readonly) NSInteger index;

- (void)playPreviousItem;
- (void)playBeginningItem;

@end
