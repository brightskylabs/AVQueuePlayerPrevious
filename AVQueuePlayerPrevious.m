//
//  AVQueuePlayerPrevious.m
//

#import "AVQueuePlayerPrevious.h"

@interface AVQueuePlayerPrevious ()

// This is a flag used to mark whether an item being added to the queue is being added by playPreviousItem (which requires slightly different functionality then in the general case) or if it is being added by an external call
@property (nonatomic) BOOL isCalledFromPlayPreviousItem;

@property (nonatomic) NSInteger nowPlayingIndex;
@property (readwrite) NSMutableArray *innerItems;

@end

@implementation AVQueuePlayerPrevious

- (instancetype)initWithItems:(NSArray *)items {
    // This function calls the constructor for AVQueuePlayer, then sets up the nowPlayingIndex to 0 and saves the array that the player was generated from as itemsForPlayer
    self = [super initWithItems:items];
    if (self){
        self.innerItems = [NSMutableArray arrayWithArray:items];
        self.nowPlayingIndex = 0;
        self.isCalledFromPlayPreviousItem = NO;
        [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(songEnded:) name:AVPlayerItemDidPlayToEndTimeNotification object:nil];
    }
    return self;
}

- (NSArray *)itemsForPlayer {
    return [self.innerItems copy];
}

- (void)songEnded:(NSNotification *)notification {
    [self.delegate queuePlayerDidReceiveNotificationForSongIncrement:self];
    if (self.nowPlayingIndex < [self.innerItems count] - 1) {
        self.nowPlayingIndex++;
    } else {
        [self playBeginningItem];
    }
}

- (void)playPreviousItem {
    if (self.nowPlayingIndex <= 0){
        return;
    }

    [self pause];
    // Note: it is necessary to have seekToTime called twice in this method, once before and once after re-making the area. If it is not present before, the player will resume from the same spot in the next song when the previous song finishes playing; if it is not present after, the previous song will be played from the same spot that the current song was on.
    [self seekToTime:kCMTimeZero toleranceBefore:kCMTimeZero toleranceAfter:kCMTimeZero];
    // The next two lines are necessary since RemoveAllItems resets both the nowPlayingIndex and _itemsForPlayer
    int tempNowPlayingIndex = self.nowPlayingIndex;
    NSMutableArray *tempPlaylist = [[NSMutableArray alloc]initWithArray:self.innerItems];
    [self removeAllItems];
    self.isCalledFromPlayPreviousItem = YES;
    for (int i = tempNowPlayingIndex - 1; i < [tempPlaylist count]; i++) {
        [self insertItem:[tempPlaylist objectAtIndex:i] afterItem:nil];
    }
    self.isCalledFromPlayPreviousItem = NO;
    // The temp index is necessary since removeAllItems resets the nowPlayingIndex
    self.nowPlayingIndex = tempNowPlayingIndex - 1;
    // Not a typo; see above comment
    [self seekToTime:kCMTimeZero toleranceBefore:kCMTimeZero toleranceAfter:kCMTimeZero];
    [self play];
}

- (NSInteger)index {
    return self.nowPlayingIndex;
}

- (void)playBeginningItem {
    [self pause];
    [self seekToTime:kCMTimeZero toleranceBefore:kCMTimeZero toleranceAfter:kCMTimeZero];
    NSMutableArray *tempPlaylist = [[NSMutableArray alloc]initWithArray:self.innerItems];
    [self removeAllItems];
    self.isCalledFromPlayPreviousItem = YES;
    for (AVPlayerItem *item in tempPlaylist) {
        [self insertItem:item afterItem:nil];
    }
    self.isCalledFromPlayPreviousItem = NO;
    // The temp index is necessary since removeAllItems resets the nowPlayingIndex
    self.nowPlayingIndex = 0;
    // Not a typo; see above comment
    [self seekToTime:kCMTimeZero toleranceBefore:kCMTimeZero toleranceAfter:kCMTimeZero];
    [self play];
}

#pragma mark - AVQueuePlayer Methods

- (void)removeAllItems {
    // This does the same thing as the normal AVQueuePlayer removeAllItems, but also sets the
    // nowPlayingIndex to 0.
    [super removeAllItems];
    self.nowPlayingIndex = 0;
    [self.innerItems removeAllObjects];
}

- (void)removeItem:(AVPlayerItem *)item {
    // This method calls the superclass to remove the items from the AVQueuePlayer itself, then removes
    // any instance of the item from the itemsForPlayer array. This mimics the behavior of removeItem on
    // AVQueuePlayer, which removes all instances of the item in question from the queue.
    // It also subtracts 1 from the nowPlayingIndex for every time the item shows up in the itemsForPlayer
    // array before the current value.
    [super removeItem:item];
    int appearancesBeforeCurrent = 0;
    for (int tracer = 0; tracer < self.nowPlayingIndex; tracer++){
        if ([self.innerItems objectAtIndex:tracer] == item) {
            appearancesBeforeCurrent++;
        }
    }
    self.nowPlayingIndex -= appearancesBeforeCurrent;
    [self.innerItems removeObject:item];
}

- (void)advanceToNextItem {
    // The only addition this method makes to AVQueuePlayer is advancing the nowPlayingIndex by 1.
    [super advanceToNextItem];
    if (self.nowPlayingIndex < [self.innerItems count] - 1){
        self.nowPlayingIndex++;
    } else {
        [self playBeginningItem];
    }
}

- (void)insertItem:(AVPlayerItem *)item afterItem:(AVPlayerItem *)afterItem {
    // This method calls the superclass to add the new item to the AVQueuePlayer, then adds that item to the
    // proper location in the itemsForPlayer array and increments the nowPlayingIndex if necessary.
    [super insertItem:item afterItem:afterItem];
    if (!self.isCalledFromPlayPreviousItem){
        if ([self.innerItems indexOfObject:item] < self.nowPlayingIndex) {
            self.nowPlayingIndex++;
        }
    }

    if ([self.innerItems containsObject:afterItem]){ // AfterItem is non-nil
        if ([self.innerItems indexOfObject:afterItem] < [self.innerItems count] - 1){
            [self.innerItems insertObject:item atIndex:[self.innerItems indexOfObject:afterItem] + 1];
        } else {
            [self.innerItems addObject:item];
        }
    } else { // afterItem is nil
        [self.innerItems addObject:item];
    }
}

@end
