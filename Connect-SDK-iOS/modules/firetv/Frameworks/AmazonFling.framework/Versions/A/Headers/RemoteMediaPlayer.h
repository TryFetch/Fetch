/**
 * RemoteMediaPlayer.h
 *
 * Copyright (c) 2015 Amazon Technologies, Inc. All rights reserved.
 *
 * PROPRIETARY/CONFIDENTIAL
 *
 * Use is subject to license terms.
 */

#import <Foundation/Foundation.h>
#import <Bolts/BFTask.h>

@class MediaPlayerStatus;
@class MediaPlayerInfo;

/**
 The seek mode.
 */
typedef enum SeekType :
NSUInteger {
    ABSOLUTE, // Seek to the given position
    RELATIVE  // Seek from the current position by given interval
} SeekType;

/**
 Media playback status listener object representation
 */
@protocol MediaPlayerStatusListener <NSObject>

/**
 Called on status changes and poistion updates.
 @param status The current status of the playback stream
 @param position The current playback position in milliseconds from start
 */
-(void) onStatusChange : (MediaPlayerStatus*) status
     positionChangedTo : (long long) position;
@end

/**
  Simple representation of a remote device's Media Player
 */
@protocol RemoteMediaPlayer

/**
  Returns the remote device's display name.
 */
- (NSString*) name;

/**
  Returns a unique id (UUID) for the remote device.
 */
- (NSString*) uniqueIdentifier;

/**
  Gets the current volume setting between 0 (mute) to 1 (full).
  @return BFTask (double)result from asynchronous calling
 */
-(BFTask *) getVolume;

/**
 Set the current volume setting between 0 (mute) to 1 (full).
 @param volume The volume normalized between 0 and 1.
 @return BFTask (void)result from asynchronous calling
 */
-(BFTask *) setVolume:(double)volume;

/**
 Gets the mute status of the receiver.
 @return BFTask (BOOL)result from asynchronous calling
 */
-(BFTask *) isMute;

/**
 Mute or un-mute the device.
 @param mute Set to true to mute the receiver
 @return BFTask (void)result from asynchronous calling
 */
-(BFTask *) setMute:(BOOL)mute;

/**
 Gets the current playback position from start.
 @return BFTask (long long)result from asynchronous calling
 */
-(BFTask *) getPosition;

/**
 Gets the duration of the current media clip, if known.
 @return BFTask (long long)result from asynchronous calling
 */
-(BFTask *) getDuration;

/**
 Gets the current playback status.
 @return BFTask (MediaPlayerStatus)result from asynchronous calling
 */
-(BFTask *) getStatus;

/**
 Gets whether the device can play media of type 'mimeType'.
 @param mimeType The MIME type to be checked
 @return BFTask (BOOL)result from asynchronous calling
 */
-(BFTask *) isMimeTypeSupported:(NSString*)mimeType;

/**
 Pause play back. Does nothing if currently paused.
 @return BFTask (void)result from asynchronous calling
 */
-(BFTask *) pause;

/**
 Start playing current media stream.
 @return BFTask (void)result from asynchronous calling
 */
-(BFTask *) play;

/**
 Stop playing current media stream.
 @return BFTask (void)result from asynchronous calling
 */
-(BFTask *) stop;

/**
 Seek to position in media stream.
 @param positionMilliseconds The position in milliseconds to seek to
 @param seekMode The seek mode, either relative or absolute
 @return BFTask (void)result from asynchronous calling
 */
-(BFTask *) seekToPosition : (long long)positionMilliseconds
                   andMode : (SeekType)seekMode;

/**
 Set the Url to stream from.
 @param mediaLoc The URL of the media
 @param metaData The metadata of the media clip, including the title, in JSON format
 @param autoPlay Set to true to automatically play when media stream is ready
 @param playInBg Set to true to prevent any UI from showing on target device
 @return BFTask (void)result from asynchronous calling
 */
-(BFTask *) setMediaSourceToURL : (NSString*)mediaLoc
                       metaData : (NSString*)metaData
                       autoPlay : (BOOL)autoPlay
            andPlayInBackground : (BOOL)playInBg;

/**
 Add a status update listener. Currently, Amazon Fling supports only one status listener per player.
 @param listener The listener to add
 @return BFTask (void)result from asynchronous calling
 */
-(BFTask *) addStatusListener : (id<MediaPlayerStatusListener>) listener;

/**
 Remove a status update listener. Currently, Amazon Fling supports only one status listener per player.
 @param listener The listener to remove
 @return BFTask (void)result from asynchronous calling
 */
-(BFTask *) removeStatusListener : (id<MediaPlayerStatusListener>) listener;

/**
 Set the update interval for position updates when playing. Set to '0' to stop updating on a regular interval.
 @param intervalMs The update interval in milliseconds
 @return BFTask (void)result from asynchronous calling
 */
-(BFTask *) setPositionUpdateInterval : (long long) intervalMs;

/**
 Send a command string to the player. The behavior of this is player-dependent, and is a no-op in the default player.
 @param cmd The command to be sent to the receiver
 @return BFTask (void)result from asynchronous calling
 */
-(BFTask *) sendCommand: (NSString*) cmd;

/**
 Sets player style using parameters sent in a JSON string.
 @param styleJson The JSON string used to set style of the player to differenctiate user experience.
 @return BFTask (void)result from asynchronous calling
 */
-(BFTask *) setPlayerStyle : (NSString*) styleJson;

/**
 Gets information about currently playing media.
 @return BFTask (MediaPlayerInfo)result from asynchronous calling
 */
-(BFTask *) getMediaInfo;

@end
