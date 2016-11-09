//
//  FireTVService.m
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

#import "FireTVService.h"

#import "AppStateChangeNotifier.h"
#import "CommonMacros.h"
#import "DispatchQueueBlockRunner.h"
#import "FireTVCapabilityMixin.h"
#import "FireTVMediaControl.h"
#import "FireTVMediaPlayer.h"

#import <AmazonFling/RemoteMediaPlayer.h>

NSString *const kConnectSDKFireTVServiceId = @"FireTV";


@interface FireTVService ()

/// Common mixin object for all capabilities.
@property (nonatomic, readonly, nonnull) FireTVCapabilityMixin *capabilityMixin;

@end

#pragma clang diagnostic push
#pragma clang diagnostic ignored "-Wprotocol"
// unimplemented protocol methods are forwarded to a certain implementation object
@implementation FireTVService
#pragma clang diagnostic pop

@synthesize capabilityMixin = _capabilityMixin;

#pragma mark - Init

- (instancetype)initWithAppStateChangeNotifier:(nullable AppStateChangeNotifier *)stateNotifier {
    self = [super init];

    _appStateChangeNotifier = stateNotifier ?: [AppStateChangeNotifier new];
    __weak typeof(self) wself = self;
    _appStateChangeNotifier.didBackgroundBlock = ^{
        typeof(self) sself = wself;
        // using an ivar here in order not to init the property if it's nil
        [sself->_fireTVMediaControl pauseSubscriptions];
    };
    _appStateChangeNotifier.didForegroundBlock = ^{
        typeof(self) sself = wself;
        // using an ivar here in order not to init the property if it's nil
        [sself->_fireTVMediaControl resumeSubscriptions];
    };

    return self;
}

- (instancetype)init {
    return [self initWithAppStateChangeNotifier:nil];
}

#pragma mark - Properties

- (id<BlockRunner> __nonnull)delegateBlockRunner {
    if (!_delegateBlockRunner) {
        _delegateBlockRunner = [DispatchQueueBlockRunner mainQueueRunner];
    }

    return _delegateBlockRunner;
}

- (FireTVCapabilityMixin * __nonnull)capabilityMixin {
    if (!_capabilityMixin) {
        _capabilityMixin = [[FireTVCapabilityMixin alloc]
                            initWithRemoteMediaPlayer:self.remoteMediaPlayer];
    }

    return _capabilityMixin;
}

- (FireTVMediaPlayer * __nonnull)fireTVMediaPlayer {
    if (!_fireTVMediaPlayer) {
        _fireTVMediaPlayer = [FireTVMediaPlayer new];
        _fireTVMediaPlayer.capabilityMixin = self.capabilityMixin;
        _fireTVMediaPlayer.service = self;
    }

    return _fireTVMediaPlayer;
}

- (FireTVMediaControl * __nonnull)fireTVMediaControl {
    if (!_fireTVMediaControl) {
        _fireTVMediaControl = [FireTVMediaControl new];
        _fireTVMediaControl.capabilityMixin = self.capabilityMixin;
    }

    return _fireTVMediaControl;
}

- (id<RemoteMediaPlayer> __nullable)remoteMediaPlayer {
    return self.serviceDescription.device;
}

#pragma mark - Overridden DeviceService Methods

+ (NSDictionary *)discoveryParameters {
    return @{@"serviceId": kConnectSDKFireTVServiceId};
}

- (void)updateCapabilities {
    NSArray *capabilities = @[kMediaPlayerDisplayImage,
                              kMediaPlayerPlayVideo,
                              kMediaPlayerPlayAudio,
                              kMediaPlayerClose,
                              kMediaPlayerMetaDataTitle,
                              kMediaPlayerMetaDataDescription,
                              kMediaPlayerMetaDataThumbnail,
                              kMediaPlayerMetaDataMimeType,
                              kMediaPlayerSubtitleWebVTT,

                              kMediaControlPlay,
                              kMediaControlPause,
                              kMediaControlStop,
                              kMediaControlDuration,
                              kMediaControlPosition,
                              kMediaControlSeek,
                              kMediaControlPlayState,
                              kMediaControlPlayStateSubscribe,
                              kMediaControlMetadata];

    self.capabilities = capabilities;
}

- (void)setServiceDescription:(ServiceDescription *)serviceDescription {
    _assert_state([serviceDescription.device conformsToProtocol:@protocol(RemoteMediaPlayer)],
                  @"The RemoteMediaPlayer device object must be available");
    const BOOL deviceIsChanging = self.serviceDescription.device != serviceDescription.device;
    [super setServiceDescription:serviceDescription];

    if (deviceIsChanging) {
        // reinit the capabilityMixin, and assign it to capabilities
        _capabilityMixin = nil;
        // ivars are used here to leave them nil if they haven't been
        // initialized yet
        _fireTVMediaPlayer.capabilityMixin = self.capabilityMixin;
        _fireTVMediaControl.capabilityMixin = self.capabilityMixin;
    }
}

- (BOOL)isConnectable {
    // even though we don't need to actually connect to the device because it's
    // already provided, we return YES to do some cleanup in -disconnect
    return YES;
}

- (void)connect {
    self.connected = YES;

    [self.appStateChangeNotifier startListening];

    [self.delegateBlockRunner runBlock:^{
        [self.delegate deviceServiceConnectionSuccess:self];
    }];
}

- (void)disconnect {
    self.connected = NO;

    [self.fireTVMediaControl unsubscribeSubscriptions];
    [self.appStateChangeNotifier stopListening];

    [self.delegateBlockRunner runBlock:^{
        [self.delegate deviceService:self disconnectedWithError:nil];
    }];
}

#pragma mark - MediaPlayer

- (id<MediaPlayer>)mediaPlayer {
    return self.fireTVMediaPlayer;
}

#pragma mark - MediaControl

- (id<MediaControl>)mediaControl {
    return self.fireTVMediaControl;
}

#pragma mark - Message Forwarding

// All other capability methods are forwarded to the corresponding capability
// object.
- (id)forwardingTargetForSelector:(SEL)aSelector {
    NSPredicate *selectorPredicate = [NSPredicate predicateWithBlock:
                                      ^BOOL(id obj, NSDictionary *bindings) {
                                          return [obj respondsToSelector:aSelector];
                                      }];
    NSArray *allTargets = @[self.fireTVMediaPlayer, self.fireTVMediaControl];
    id target = [[allTargets filteredArrayUsingPredicate:selectorPredicate]
                 firstObject];
    return target ?: [super forwardingTargetForSelector:aSelector];
}

@end
