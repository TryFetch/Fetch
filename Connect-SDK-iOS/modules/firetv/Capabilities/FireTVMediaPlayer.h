//
//  FireTVMediaPlayer.h
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

#import "MediaPlayer.h"

@class FireTVCapabilityMixin;
@class FireTVService;

NS_ASSUME_NONNULL_BEGIN
/**
 * Implements the @c MediaPlayer capability for the @c FireTVService class.
 */
@interface FireTVMediaPlayer : NSObject <MediaPlayer>

/// Mixin containing common capability properties and methods.
@property (nonatomic, strong) FireTVCapabilityMixin *capabilityMixin;

/// A @c FireTVService object that owns this instance.
@property (nonatomic, weak) FireTVService *service;

@end
NS_ASSUME_NONNULL_END
