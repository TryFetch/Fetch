/**
 *  MediaPlayerStatus.h
 *
 * Copyright (c) 2015 Amazon Technologies, Inc. All rights reserved.
 *
 * PROPRIETARY/CONFIDENTIAL
 *
 * Use is subject to license terms.
 */

#import <Foundation/Foundation.h>


/**
 Simple status object.
 */
@interface MediaPlayerStatus : NSObject
{
    /**
     The MediaState describes what is happening with the Media Player. The codes are self-descriptive.
     */
    enum MediaState {NoMedia, PreparingMedia, ReadyToPlay, Playing, Paused, Seeking, Finished, Error} _state;
    
    
    /**
     The MediaCondition describes the 'condition' of the Media Player - that is, the current error state, or a warning state. 
     Any Error condition can only occur when the AmazonMediaStatus.MediaState is Error, but a Warning state can co-exist with 
     another AmazonMediaStatus.MediaState, though usually Playing.
     */
    enum MediaCondition {Good, WarningContent, WarningBandwidth, ErrorContent, ErrorChannel, ErrorUnknown} _condition;
    
    bool _mute;
    double _volume;
    bool _muteSet;
    bool _volumeSet;
}

/**
 Initializes the media playback status with given values.
 @param newState The new state of the playback status
 @param newCond The new condition of the playback status
 */
- (MediaPlayerStatus*) initWithState : (enum MediaState)newState
                        andCondition : (enum MediaCondition)newCond;

/**
 Returns the media state.
 @return MediaState enum
 */
- (enum MediaState) state;

/**
 Returns the Media condition.
 @return MediaCondition enum
 */
- (enum MediaCondition) condition;

/**
 Sets the optional mute variable
 @param newMute The value of the mute status on the player.
 */
- (void) setMute:(bool)newMute;

/**
 Sets the optional volume variable
 @param newVolume The value of the new volume on the player.
 */
- (void) setVolume:(double)newVolume;

/**
 Returns the mute status
 @return YES if the player is muted, NO otherwise
 */
- (bool) isMute;

/**
 Returns the volume
 @return The volume of player between 0.0 and 1.0
 */
- (double) volume;

/**
 Returns the status of the mute variable
 @return YES if the mute flag is set, NO otherwise.
 */
- (bool) isMuteSet;

/**
 Returns the status of the volume variable
 @return YES if the volume is set, NO otherwise.
 */
- (bool) isVolumeSet;

@end
