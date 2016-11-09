//
//  FireTVMediaControl.m
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

#import "FireTVMediaControl.h"
#import "BlockRunner.h"
#import "FireTVCapabilityMixin.h"
#import "SubscriptionDeduplicator.h"

#import "NSMutableDictionary+NilSafe.h"

#import <AmazonFling/MediaPlayerInfo.h>
#import <AmazonFling/RemoteMediaPlayer.h>

@interface FireTVMediaControl () <MediaPlayerStatusListener,
            ServiceCommandDelegate>

/// An object managing play state subscription, if created.
@property (nonatomic, strong) ServiceSubscription *playStateSubscription;
/// Play state subscription deduplicator.
@property (nonatomic, strong) SubscriptionDeduplicator *playStateSubscriptionDeduplicator;

@end

// the use of a category silences unimplemented method warnings
@interface FireTVMediaControl (Configuration) <FireTVCapabilityMixin>

@end

@implementation FireTVMediaControl

#pragma mark - Public Methods

- (void)unsubscribeSubscriptions {
    [self unsubscribePlayState];
}

- (void)pauseSubscriptions {
    [self pausePlayState];
}

- (void)resumeSubscriptions {
    [self resumePlayState];
}

- (MediaControlPlayState)playStateForMediaState:(enum MediaState)state {
    switch (state) {
        case NoMedia:
            return MediaControlPlayStateIdle;

        case PreparingMedia:
            return MediaControlPlayStateBuffering;

        case Playing:
            return MediaControlPlayStatePlaying;

        case Paused:
            return MediaControlPlayStatePaused;

        case Finished:
            return MediaControlPlayStateFinished;

        default:
            return MediaControlPlayStateUnknown;
    }
}

#pragma mark - MediaControl

- (id<MediaControl>)mediaControl {
    return self;
}

- (CapabilityPriorityLevel)mediaControlPriority {
    return CapabilityPriorityLevelHigh;
}

- (void)playWithSuccess:(SuccessBlock)success failure:(FailureBlock)failure {
    [self continueTask:[self.remoteMediaPlayer play]
      withSuccessBlock:success
       andFailureBlock:failure];
}

- (void)pauseWithSuccess:(SuccessBlock)success failure:(FailureBlock)failure {
    [self continueTask:[self.remoteMediaPlayer pause]
      withSuccessBlock:success
       andFailureBlock:failure];
}

- (void)stopWithSuccess:(SuccessBlock)success failure:(FailureBlock)failure {
    [self continueTask:[self.remoteMediaPlayer stop]
      withSuccessBlock:success
       andFailureBlock:failure];
}

- (void)seek:(NSTimeInterval)position
     success:(SuccessBlock)success
     failure:(FailureBlock)failure {
    long long positionMilliseconds = position * 1000;
    [self continueTask:[self.remoteMediaPlayer seekToPosition:positionMilliseconds
                                                      andMode:ABSOLUTE]
      withSuccessBlock:success
       andFailureBlock:failure];
}

- (void)getDurationWithSuccess:(MediaDurationSuccessBlock)success
                       failure:(FailureBlock)failure {
    [self continueTask:[self.remoteMediaPlayer getDuration]
convertingMillisecondsToTimeIntervalWithSuccess:success
       andFailureBlock:failure];
}

- (void)getPositionWithSuccess:(MediaPositionSuccessBlock)success
                       failure:(FailureBlock)failure {
    [self continueTask:[self.remoteMediaPlayer getPosition]
convertingMillisecondsToTimeIntervalWithSuccess:success
       andFailureBlock:failure];
}

- (void)getPlayStateWithSuccess:(MediaPlayStateSuccessBlock)success
                        failure:(FailureBlock)failure {
    [self continueTask:[self.remoteMediaPlayer getStatus]
  withSuccessCompleter:^(MediaPlayerStatus *status) {
      if (success) {
          success([self playStateForMediaState:[status state]]);
      }
  }
       andFailureBlock:failure];
}

- (ServiceSubscription *)subscribePlayStateWithSuccess:(MediaPlayStateSuccessBlock)success
                                               failure:(FailureBlock)failure {
    if (!self.playStateSubscription) {
        self.playStateSubscription = [ServiceSubscription subscriptionWithDelegate:self
                                                                            target:nil
                                                                           payload:nil
                                                                            callId:kUnsetCallId];

        [self continueTask:[self.remoteMediaPlayer addStatusListener:self]
      withSuccessCompleter:^(id result) {
          self.playStateSubscription.isSubscribed = YES;
          self.playStateSubscriptionDeduplicator = [SubscriptionDeduplicator new];
      }
           andFailureBlock:failure];
    }

    // push the current play state value to the subscription because we don't
    // get it automatically from the Fling SDK
    [self getPlayStateWithSuccess:success failure:failure];

    [self.playStateSubscription addSuccess:success];
    [self.playStateSubscription addFailure:failure];

    return self.playStateSubscription;
}

- (void)getMediaMetaDataWithSuccess:(SuccessBlock)success
                            failure:(FailureBlock)failure {
    [self continueTask:[self.remoteMediaPlayer getMediaInfo]
  withSuccessCompleter:^(id result) {
      MediaPlayerInfo *playerInfo = result;
      NSData *mediaInfoJSONData = [[playerInfo metadata]
                                   dataUsingEncoding:NSUTF8StringEncoding];
      NSDictionary *mediaInfo = [NSJSONSerialization JSONObjectWithData:mediaInfoJSONData
                                                                options:0
                                                                  error:nil];

      NSMutableDictionary *metadataDict = [NSMutableDictionary dictionary];
      [metadataDict setNullableObject:mediaInfo[@"title"] forKey:@"title"];
      [metadataDict setNullableObject:mediaInfo[@"description"]
                               forKey:@"subtitle"];
      [metadataDict setNullableObject:mediaInfo[@"poster"] forKey:@"iconURL"];
      success([metadataDict copy]);
  }
        ifSuccessBlock:success
       andFailureBlock:failure];
}

#pragma mark - MediaControl: unsupported methods

- (void)rewindWithSuccess:(SuccessBlock)success failure:(FailureBlock)failure {
    [self callFailureBlockWithUnsupportedError:failure];
}

- (void)fastForwardWithSuccess:(SuccessBlock)success
                       failure:(FailureBlock)failure {
    [self callFailureBlockWithUnsupportedError:failure];
}

- (ServiceSubscription *)subscribeMediaInfoWithSuccess:(SuccessBlock)success
                                               failure:(FailureBlock)failure {
    return [self callFailureBlockWithUnsupportedError:failure];
}

#pragma mark - MediaPlayerStatusListener

- (void)onStatusChange:(MediaPlayerStatus *)status
     positionChangedTo:(long long)position {
    const MediaControlPlayState playState = [self playStateForMediaState:[status state]];

    self.playStateSubscriptionDeduplicator = [self.playStateSubscriptionDeduplicator runBlock:^{
        [self.playStateSubscription.successCalls enumerateObjectsUsingBlock:
         ^(MediaPlayStateSuccessBlock success, NSUInteger idx, BOOL *stop) {
             [self.callbackBlockRunner runBlock:^{
                 success(playState);
             }];
         }];
    }
                                                                           ifStateDidChangeTo:@(playState)];
}

#pragma mark - ServiceCommandDelegate

- (int)sendSubscription:(ServiceSubscription *)subscription
                   type:(ServiceSubscriptionType)type
                payload:(id)payload
                  toURL:(NSURL *)URL
                 withId:(int)callId {
    if (ServiceSubscriptionTypeUnsubscribe == type) {
        [self unsubscribePlayState];
    }

    return kUnsetCallId;
}

#pragma mark - Forwarding to Configuration

- (id)forwardingTargetForSelector:(SEL)aSelector {
    return ([self.capabilityMixin respondsToSelector:aSelector] ?
            self.capabilityMixin :
            [super forwardingTargetForSelector:aSelector]);
}

#pragma mark - Helpers

/// Unsubscribes and removes the @c playStateSubscription.
- (void)unsubscribePlayState {
    if (self.playStateSubscription) {
        [self.remoteMediaPlayer removeStatusListener:self];
        self.playStateSubscription.isSubscribed = NO;
        self.playStateSubscription = nil;
        self.playStateSubscriptionDeduplicator = nil;
    }
}

/// Pauses the @c playStateSubscription.
- (void)pausePlayState {
    if (self.playStateSubscription) {
        [self.remoteMediaPlayer removeStatusListener:self];
    }
}

/// Resumes the @c playStateSubscription, paused by @c -pausePlayState.
- (void)resumePlayState {
    if (self.playStateSubscription) {
        [self.remoteMediaPlayer addStatusListener:self];
    }
}

/// Converts the result of running the @c task from milliseconds to
/// NSTimeInterval. Used for duration and position.
- (void)continueTask:(BFTask *)task
convertingMillisecondsToTimeIntervalWithSuccess:(void (^)(NSTimeInterval))success
     andFailureBlock:(FailureBlock)failure {
    [self continueTask:task
  withSuccessCompleter:^(NSNumber *result) {
      if (success) {
          success([result longLongValue] / 1000.0);
      }
  }
       andFailureBlock:failure];
}

@end
