/**
 *  DiscoveryController.h
 *
 * Copyright (c) 2015 Amazon Technologies, Inc. All rights reserved.
 *
 * PROPRIETARY/CONFIDENTIAL
 *
 * Use is subject to license terms.
 */

#import <Foundation/Foundation.h>
#import "RemoteMediaPlayer.h"

@class WhisperplayAdaptor;

/**
 Listener implemented by client developer for player discovery.
 */
@protocol DiscoveryListener

/**
 Called when a new player is discovered or Updated.
 @param device The device found on the local network
 */
-(void)deviceDiscovered:(id<RemoteMediaPlayer>)device;

/**
 Called when a device is no longer reachable.
 @param device The lost device
 */
-(void)deviceLost:(id<RemoteMediaPlayer>)device;

/**
 Called in the case where discovery is no longer working.
 */
-(void)discoveryFailure;
@end


/**
 A simple interface used to discover Amazon devices supporting simple media player.
 */
@interface DiscoveryController : NSObject {
    WhisperplayAdaptor *implementation;
}

/**
 Start discovery on this device, searching for the Fire TV built-in player.
 @param listener The discovery listener implementation
 */
-(void) searchDefaultPlayerWithListener:(id <DiscoveryListener>)listener;

/**
 Start discovery on this device, searching for a custom player.
 @param serviceId The service id of the player to search for
 @param listener The discovery listener implementation
 */
-(void) searchPlayerWithId : (NSString*)serviceId
               andListener : (id <DiscoveryListener> )listener;

/**
 Resume discovery
*/
-(void) resume;

/**
 Stop discovery, and clean up.
 */
-(void) close;
@end
