//
//  FireTVMediaControl.h
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

#import "MediaControl.h"

#import <AmazonFling/MediaPlayerStatus.h>

@class FireTVCapabilityMixin;

NS_ASSUME_NONNULL_BEGIN
/**
 * Implements the @c MediaControl capability for the @c FireTVService class.
 */
@interface FireTVMediaControl : NSObject <MediaControl>

/// Mixin containing common capability properties and methods.
@property (nonatomic, strong) FireTVCapabilityMixin *capabilityMixin;

/// Unsubscribes and removes all previously created subscriptions.
/// @warning You must call this method to break a circular dependency to be able
/// to @c dealloc this object.
- (void)unsubscribeSubscriptions;

/// Temporarily pauses subscriptions w/o unsubscribing them. Required to support
/// app suspend/resume properly.
- (void)pauseSubscriptions;

/// Resumes subscriptions paused by @c -pauseSubscriptions. Required to support
/// app suspend/resume properly.
- (void)resumeSubscriptions;

/// Converts a @c MediaState value into the corresponding
/// @c MediaControlPlayState value.
- (MediaControlPlayState)playStateForMediaState:(enum MediaState)state;

@end
NS_ASSUME_NONNULL_END
