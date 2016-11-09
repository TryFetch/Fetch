/**
 *  InstallDiscoveryController.h
 *
 * Copyright (c) 2015 Amazon Technologies, Inc. All rights reserved.
 *
 * PROPRIETARY/CONFIDENTIAL
 *
 * Use is subject to license terms.
 */

#import <Foundation/Foundation.h>
#import "RemoteInstallService.h"

@class InstallWhisperplayAdaptor;

/**
 Listener implemented by client developer for install service discovery.
 */
@protocol InstallDiscoveryListener

/**
 Called when a new device is discovered or Updated.
 @param device The device found on the local network
 */
-(void)installServiceDiscovered:(id<RemoteInstallService>)device;

/**
 Called when a device is no longer reachable.
 @param device The lost device
 */
-(void)installServiceLost:(id<RemoteInstallService>)device;

/**
 Called in the case where discovery is no longer working.
 */
-(void)discoveryFailure;
@end


/**
 A simple interface used to discover Amazon devices supporting install service.
 */
@interface InstallDiscoveryController : NSObject {
    InstallWhisperplayAdaptor *implementation;
}

/**
 Start discovery of all the devices on local network that support install service.
 @param listener The discovery listener implementation
 */
-(void) searchInstallServiceWithListener:(id <InstallDiscoveryListener>)listener;

/**
 Resume discovery
*/
-(void) resume;

/**
 Stop discovery, and clean up.
 */
-(void) close;
@end
