//
//  FireTVDiscoveryProvider.m
//  ConnectSDK
//
//  Created by Eugene Nikolskyi on 2015-07-08.
//  Copyright (c) 2015 LG Electronics. All rights reserved.
//
//  Licensed under the Apache License, Version 2.0 (the "License");
//  you may not use this file except in compliance with the License.
//  You may obtain a copy of the License at
//
//      http://www.apache.org/licenses/LICENSE-2.0
//
//  Unless required by applicable law or agreed to in writing, software
//  distributed under the License is distributed on an "AS IS" BASIS,
//  WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
//  See the License for the specific language governing permissions and
//  limitations under the License.
//

#import "FireTVDiscoveryProvider_Private.h"
#import "ConnectError.h"
#import "DispatchQueueBlockRunner.h"
#import "FireTVService.h"
#import "ServiceDescription.h"

#import <AmazonFling/DiscoveryController.h>
#import <AmazonFling/RemoteMediaPlayer.h>


@interface FireTVDiscoveryProvider ()

/// Stores the created service descriptions mapped by device's UUID. It also allows to diagnose
/// devices that are lost before discovered (if that can happen).
@property (nonatomic, strong, readonly) NSMutableDictionary *storedServiceDescriptions;

/// Whether the @c flingDiscoveryController has been once initialized. You can
/// call @c -open: only once, otherwise discovery won't work.
@property (nonatomic, assign) BOOL isInitialized;

@end


@implementation FireTVDiscoveryProvider

#pragma mark - Init

- (instancetype)initWithDiscoveryController:(nullable DiscoveryController *)controller {
    if ((self = [super init])) {
        _flingDiscoveryController = controller ?: [DiscoveryController new];
        _storedServiceDescriptions = [NSMutableDictionary dictionary];

        _isInitialized = NO;
    }

    return self;
}

- (instancetype)init {
    return [self initWithDiscoveryController:nil];
}

#pragma mark - Discovery

- (void)startDiscovery {
    if (!self.isRunning) {
        self.isRunning = YES;

        if (self.isInitialized) {
            [self.flingDiscoveryController resume];
        } else {
            [self.flingDiscoveryController searchDefaultPlayerWithListener:self];
            self.isInitialized = YES;
        }
    }
}

- (void)stopDiscovery {
    [self stopDiscoveryWithRemovingServices:YES];
}

- (void)pauseDiscovery {
    [self stopDiscoveryWithRemovingServices:NO];
}

#pragma mark - DiscoveryListener methods

- (void)deviceDiscovered:(id<RemoteMediaPlayer>)device {
    if (device) {
        [self.delegateBlockRunner runBlock:^{
            NSString *uuid = [device uniqueIdentifier];
            // we don't know the IP address, so replace it with the unique ID
            ServiceDescription *serviceDescription = [ServiceDescription descriptionWithAddress:uuid
                                                                                           UUID:uuid];
            serviceDescription.serviceId = kConnectSDKFireTVServiceId;
            serviceDescription.friendlyName = [device name];
            serviceDescription.device = device;
            self.storedServiceDescriptions[uuid] = serviceDescription;

            [self.delegate discoveryProvider:self
                              didFindService:serviceDescription];
        }];
    } else {
        DLog(@"%@: discovered nil media player", self);
    }
}

- (void)deviceLost:(id<RemoteMediaPlayer>)device {
    if (device) {
        [self removeServiceDescriptionWithUUID:[device uniqueIdentifier]];
    } else {
        DLog(@"%@: lost nil media player", self);
    }
}

- (void)discoveryFailure {
    [self.delegateBlockRunner runBlock:^{
        NSError *error = [ConnectError generateErrorWithCode:ConnectStatusCodeError
                                                  andDetails:nil];
        [self.delegate discoveryProvider:self
                        didFailWithError:error];
    }];
}

#pragma mark - Properties

- (id<BlockRunner>)delegateBlockRunner {
    if (!_delegateBlockRunner) {
        _delegateBlockRunner = [DispatchQueueBlockRunner mainQueueRunner];
    }

    return _delegateBlockRunner;
}

#pragma mark - Private Methods

/// Closes the @c flingDiscoveryController if the discovery is running and
/// optionally removes found services.
- (void)stopDiscoveryWithRemovingServices:(BOOL)removingServices {
    if (self.isRunning) {
        [self.flingDiscoveryController close];
        self.isRunning = NO;

        if (removingServices) {
            [self removeAllServiceDescriptions];
        }
    }
}

/// Removes a @c ServiceDescription by its @c uuid from the stored dictionary
/// and notifies the delegate. If the @c uuid is not found, does nothing.
- (void)removeServiceDescriptionWithUUID:(NSString *)uuid {
    ServiceDescription *foundServiceDescription = self.storedServiceDescriptions[uuid];
    if (foundServiceDescription) {
        [self.storedServiceDescriptions removeObjectForKey:uuid];

        [self.delegateBlockRunner runBlock:^{
            [self.delegate discoveryProvider:self
                              didLoseService:foundServiceDescription];
        }];
    } else {
        DLog(@"%@: lost device that was not found: %@", self, uuid);
    }
}

/// Removes all stored @c ServiceDescription objects and notifies the delegate.
- (void)removeAllServiceDescriptions {
    [self.storedServiceDescriptions.allKeys enumerateObjectsUsingBlock:
     ^(NSString *uuid, NSUInteger idx, BOOL *stop) {
         [self removeServiceDescriptionWithUUID:uuid];
     }];
}

@end
