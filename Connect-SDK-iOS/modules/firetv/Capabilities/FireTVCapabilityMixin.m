//
//  FireTVCapabilityMixin.m
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

#import "FireTVCapabilityMixin.h"
#import "ConnectError.h"
#import "DispatchQueueBlockRunner.h"

#import "NSObject+FeatureNotSupported_Private.h"

#import <Bolts/BFExecutor.h>
#import <Bolts/BFTask.h>

@implementation FireTVCapabilityMixin

@synthesize remoteMediaPlayer = _remoteMediaPlayer;
@synthesize defaultExecutor = _defaultExecutor;
@synthesize callbackBlockRunner = _callbackBlockRunner;

#pragma mark - Init

- (instancetype)initWithRemoteMediaPlayer:(id<RemoteMediaPlayer> __nonnull)remoteMediaPlayer
                   andCallbackBlockRunner:(id<BlockRunner> __nonnull)blockRunner {
    self = [super init];
    _remoteMediaPlayer = remoteMediaPlayer;
    _callbackBlockRunner = blockRunner;
    _defaultExecutor = [BFExecutor mainThreadExecutor];

    return self;
}

- (instancetype)initWithRemoteMediaPlayer:(id<RemoteMediaPlayer> __nonnull)remoteMediaPlayer {
    return [self initWithRemoteMediaPlayer:remoteMediaPlayer
                    andCallbackBlockRunner:[DispatchQueueBlockRunner mainQueueRunner]];
}

#pragma mark - Public Methods

- (void)continueTask:(BFTask *)task
    withSuccessBlock:(nullable SuccessBlock)success
     andFailureBlock:(nullable FailureBlock)failure {
    [self continueTask:task
  withSuccessCompleter:^(id __nullable result) {
      if (success) {
          success(result);
      }
  }
       andFailureBlock:failure];
}

- (void)continueTask:(BFTask * __nonnull)task
withSuccessCompleter:(void (^ __nonnull)(id __nullable))successCompleter
     andFailureBlock:(nullable FailureBlock)failure {
    [self continueTask:task
  withSuccessCompleter:successCompleter
        ifSuccessIsSet:YES
       andFailureBlock:failure];
}

- (void)continueTask:(BFTask * __nonnull)task
withSuccessCompleter:(void (^ __nonnull)(id __nullable))successCompleter
      ifSuccessBlock:(nullable void (^)())success
     andFailureBlock:(nullable FailureBlock)failure {
    [self continueTask:task
  withSuccessCompleter:successCompleter
        ifSuccessIsSet:(nil != success)
       andFailureBlock:failure];
}

- (nullable id)callFailureBlockWithUnsupportedError:(nullable FailureBlock)failure {
    return [self sendNotSupportedFailure:failure];
}

#pragma mark - Helpers

- (void)continueTask:(BFTask * __nonnull)task
withSuccessCompleter:(void(^ __nonnull)(id __nullable result))successCompleter
      ifSuccessIsSet:(BOOL)successIsSet
     andFailureBlock:(nullable FailureBlock)failure {
    [task continueWithExecutor:self.defaultExecutor
                     withBlock:^id(BFTask *task) {
                         if (task.error) {
                             if (failure) {
                                 failure(task.error);
                             }
                         } else {
                             if (successIsSet) {
                                 successCompleter(task.result);
                             }
                         }

                         return nil;
                     }];
}

@end
