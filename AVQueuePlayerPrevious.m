//
//  AVQueuePlayerPrevious.m
//  IntervalPlayer
//
//  Created by Daniel Giovannelli on 2/18/13.
//

#import "AVQueuePlayerPrevious.h"

@implementation AVQueuePlayerPrevious

@synthesize itemsForPlayer = _itemsForPlayer;

// CONSTRUCTORS

-(id)initWithItems:(NSArray *)items
{
    // This function calls the constructor for AVQueuePlayer, then sets up the nowPlayingIndex to 0 and
    // saves the array that the player was generated from as itemsForPlayer
    self = [super initWithItems:items];
    if (self){
        self.itemsForPlayer = [NSMutableArray arrayWithArray:items];
        nowPlayingIndex = 0;
    }
    return self;
}

+ (AVQueuePlayerPrevious *)queuePlayerWithItems:(NSArray *)items
{
    // This function just allocates space for, creates, and returns an AVQueuePlayerPrevious from an array.
    // Honestly I think having it is a bit silly, but since its present in AVQueuePlayer it needs to be
    // overridden here to ensure compatability. If anyone has any insight on why this method exists at all,
    // let me know.
    AVQueuePlayerPrevious *playerToReturn = [[AVQueuePlayerPrevious alloc] initWithItems:items];
    return playerToReturn;
}

// NEW METHODS

-(void)playPreviousItem
{
    // This function is the meat of this library: it allows for going backwards in an AVQueuePlayer,
    // basically by clearing the player and repopulating it from the index of the last song played.
    // It should be noted that if the player is on its first song, this function will do nothing. It will
    // not restart the song or anything like that; if you want that functionality you can implement it
    // yourself fairly easily using the isAtBeginning method to test if the player is at its start.
    if (nowPlayingIndex>0){
        [self pause];
        // Note: it is necessary to have seekToTime called twice in this method, once before and once after re-making the area. If it is not present before, the player will resume from the same spot in the next song when the previous song finishes playing; if it is not present after, the previous song will be played from the same spot that the current song was on.
        [self seekToTime:kCMTimeZero toleranceBefore:kCMTimeZero toleranceAfter:kCMTimeZero];
        int tempNowPlayingIndex = nowPlayingIndex;
        [self removeAllItems];
        for (int i=nowPlayingIndex - 1; i < [_itemsForPlayer count]; i++) {
            [self insertItem:[_itemsForPlayer objectAtIndex:i] afterItem:nil];
        }
        // The temp index is necessary since removeAllItems resets the nowPlayingIndex
        nowPlayingIndex = tempNowPlayingIndex - 1;
        // Not a typo; see above comment
        [self seekToTime:kCMTimeZero toleranceBefore:kCMTimeZero toleranceAfter:kCMTimeZero];
        [self play];
    }
}

-(Boolean)isAtBeginning
{
    // This function simply returns whether or not the AVQueuePlayerPrevious is at the first song. This is
    // useful for implementing custom behavior if the user tries to play a previous song at the start of
    // the queue (such as restarting the song).
    if (nowPlayingIndex == 0){
        return YES;
    } else {
        return NO;
    }
}

// OVERRIDDEN AVQUEUEPLAYER METHODS

-(void)removeAllItems
{
    // This does the same thing as the normal AVQueuePlayer removeAllItems, but also sets the
    // nowPlayingIndex to 0.
    [super removeAllItems];
    nowPlayingIndex = 0;
}

-(void)removeItem:(AVPlayerItem *)item
{
    // This method calls the superclass to remove the items from the AVQueuePlayer itself, then removes
    // any instance of the item from the itemsForPlayer array. This mimics the behavior of removeItem on
    // AVQueuePlayer, which removes all instances of the item in question from the queue.
    // It also subtracts 1 from the nowPlayingIndex for every time the item shows up in the itemsForPlayer
    // array before the current value.
    [super removeItem:item];
    int appearancesBeforeCurrent = 0;
    for (int tracer = 0; tracer < nowPlayingIndex; tracer++){
        if ([_itemsForPlayer objectAtIndex:tracer] == item) {
            appearancesBeforeCurrent++;
        }
    }
    nowPlayingIndex -= appearancesBeforeCurrent;
    [_itemsForPlayer removeObject:item];
}

- (void)advanceToNextItem
{
    // The only addition this method makes to AVQueuePlayer is advancing the nowPlayingIndex by 1.
    [super advanceToNextItem];
    nowPlayingIndex++;
}

-(void)insertItem:(AVPlayerItem *)item afterItem:(AVPlayerItem *)afterItem
{
    // This method calls the superclass to add the new item to the AVQueuePlayer, then adds that item to the
    // proper location in the itemsForPlayer array and increments the nowPlayingIndex if necessary.
    [super insertItem:item afterItem:afterItem];
    if ([_itemsForPlayer indexOfObject:item] < nowPlayingIndex)
    {
        nowPlayingIndex++;
    }
    [_itemsForPlayer insertObject:afterItem atIndex:[_itemsForPlayer indexOfObject:item]];
}

@end