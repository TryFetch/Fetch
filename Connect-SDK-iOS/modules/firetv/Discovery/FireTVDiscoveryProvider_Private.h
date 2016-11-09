//
//  FireTVDiscoveryProvider_Private.h
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

#import "FireTVDiscoveryProvider.h"

#import <AmazonFling/DiscoveryController.h>

@protocol BlockRunner;

NS_ASSUME_NONNULL_BEGIN
@interface FireTVDiscoveryProvider () <DiscoveryListener>

/// Initializes the instance with the given @c DiscoveryController. Using @c nil
/// parameter will create a real object.
- (instancetype)initWithDiscoveryController:(nullable DiscoveryController *)controller;

/// The @c DiscoveryController object to control.
@property (nonatomic, strong, readonly) DiscoveryController *flingDiscoveryController;

/// The @c BlockRunner instance specifying where to run delegate callbacks. The
/// default value is the main dispatch queue runner. Cannot be @c nil, as it
/// will reset to the default value.
@property (nonatomic, strong) id<BlockRunner> delegateBlockRunner;

@end
NS_ASSUME_NONNULL_END
