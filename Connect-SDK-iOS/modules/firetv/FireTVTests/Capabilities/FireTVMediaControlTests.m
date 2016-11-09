//
//  FireTVMediaControlTests.m
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
#import "ConnectError.h"
#import "FireTVCapabilityMixin.h"
#import "SynchronousBlockRunner.h"

#import "OCMArg+ArgumentCaptor.h"
#import "XCTestCase+TaskTests.h"

#import <AmazonFling/MediaPlayerInfo.h>
#import <AmazonFling/MediaPlayerStatus.h>
#import <AmazonFling/RemoteMediaPlayer.h>

static const NSTimeInterval kTimeIntervalAccuracy = 0.0001;


@interface FireTVMediaControlTests : XCTestCase

@property (strong) FireTVMediaControl *mediaControl;
@property (strong) id /*<RemoteMediaPlayer>*/ playerMock;
@property (strong) id <RemoteMediaPlayer> playerMockCast;

@end

@implementation FireTVMediaControlTests

#pragma mark - Setup

- (void)setUp {
    [super setUp];

    self.mediaControl = [FireTVMediaControl new];
    self.playerMock = OCMStrictProtocolMock(@protocol(RemoteMediaPlayer));
    FireTVCapabilityMixin *mixin = [[FireTVCapabilityMixin alloc]
                                    initWithRemoteMediaPlayer:self.playerMock
                                    andCallbackBlockRunner:[SynchronousBlockRunner new]];
    self.playerMockCast = (id<RemoteMediaPlayer>)self.playerMock;
    self.mediaControl.capabilityMixin = mixin;
}

- (void)tearDown {
    OCMStub([self.playerMock removeStatusListener:OCMOCK_ANY]);
    self.playerMockCast = nil;
    self.playerMock = nil;
    self.mediaControl = nil;

    [super tearDown];
}

#pragma mark - General Instance Tests

- (void)testInstanceShouldBeCreated {
    XCTAssertNotNil(self.mediaControl, @"Instance should be created");
}

- (void)testInstanceShouldImplementMediaControlProtocol {
    XCTAssertTrue([self.mediaControl.class conformsToProtocol:@protocol(MediaControl)],
                  @"Instance should be a MediaControl");
}

- (void)testShouldGetRemoteMediaPlayer {
    XCTAssertEqual(self.mediaControl.capabilityMixin.remoteMediaPlayer,
                   self.playerMock,
                   @"Should return the same remoteMediaPlayer object");
}

#pragma mark - MediaControl Tests

- (void)testMediaControlShouldReturnSelf {
    XCTAssertEqual([self.mediaControl mediaControl], self.mediaControl,
                   @"mediaControl should return itself");
}

- (void)testPriorityShouldBeHigh {
    XCTAssertEqual([self.mediaControl mediaControlPriority],
                   CapabilityPriorityLevelHigh, @"The priority should be High");
}

- (void)testPlayShouldPlay {
    OCMExpect([self.playerMock play]);

    [self.mediaControl playWithSuccess:nil failure:nil];

    OCMVerifyAll(self.playerMock);
}

- (void)testPlaySuccessShouldCallPlaySuccessBlock {
    [self checkTaskSuccessOnStubRecorder:OCMExpect([self.playerMock play])
        shouldCallSuccessBlockUsingBlock:
     ^(SuccessBlock successVerifier, FailureBlock failureVerifier) {
         [self.mediaControl playWithSuccess:successVerifier
                                    failure:failureVerifier];
     }];
}

- (void)testPlayErrorShouldCallPlayFailureBlock {
    [self checkTaskErrorOnStubRecorder:OCMExpect([self.playerMock play])
      shouldCallFailureBlockUsingBlock:
     ^(SuccessBlock successVerifier, FailureBlock failureVerifier) {
         [self.mediaControl playWithSuccess:successVerifier
                                    failure:failureVerifier];
     }];
}

- (void)testPlaySuccessShouldNotCrashWithNilSuccessBlock {
    BFTask *task = [BFTask taskWithResult:nil];
    [OCMExpect([self.playerMock play]) andReturn:task];
    XCTAssertNoThrow([self.mediaControl playWithSuccess:nil failure:nil],
                     @"success nil block should be allowed");
}

- (void)testPlayErrorShouldNotCrashWithNilFailureBlock {
    BFTask *task = [self errorTask];
    [OCMExpect([self.playerMock play]) andReturn:task];
    XCTAssertNoThrow([self.mediaControl playWithSuccess:nil failure:nil],
                     @"failure nil block should be allowed");
}

- (void)testPauseShouldPause {
    OCMExpect([self.playerMockCast pause]);

    [self.mediaControl pauseWithSuccess:nil failure:nil];

    OCMVerifyAll(self.playerMock);
}

- (void)testPauseSuccessShouldCallPauseSuccessBlock {
    [self checkTaskSuccessOnStubRecorder:OCMExpect([self.playerMockCast pause])
        shouldCallSuccessBlockUsingBlock:
     ^(SuccessBlock successVerifier, FailureBlock failureVerifier) {
         [self.mediaControl pauseWithSuccess:successVerifier
                                     failure:failureVerifier];
     }];
}

- (void)testPauseErrorShouldCallPauseFailureBlock {
    [self checkTaskErrorOnStubRecorder:OCMExpect([self.playerMockCast pause])
      shouldCallFailureBlockUsingBlock:
     ^(SuccessBlock successVerifier, FailureBlock failureVerifier) {
         [self.mediaControl pauseWithSuccess:successVerifier
                                     failure:failureVerifier];
     }];
}

- (void)testPauseSuccessShouldNotCrashWithNilSuccessBlock {
    BFTask *task = [BFTask taskWithResult:nil];
    [OCMExpect([self.playerMockCast pause]) andReturn:task];
    XCTAssertNoThrow([self.mediaControl pauseWithSuccess:nil failure:nil],
                     @"success nil block should be allowed");
}

- (void)testPauseErrorShouldNotCrashWithNilFailureBlock {
    BFTask *task = [self errorTask];
    [OCMExpect([self.playerMockCast pause]) andReturn:task];
    XCTAssertNoThrow([self.mediaControl pauseWithSuccess:nil failure:nil],
                     @"failure nil block should be allowed");
}

- (void)testStopShouldStop {
    OCMExpect([self.playerMockCast stop]);

    [self.mediaControl stopWithSuccess:nil failure:nil];

    OCMVerifyAll(self.playerMock);
}

- (void)testStopSuccessShouldCallStopSuccessBlock {
    [self checkTaskSuccessOnStubRecorder:OCMExpect([self.playerMockCast stop])
        shouldCallSuccessBlockUsingBlock:
     ^(SuccessBlock successVerifier, FailureBlock failureVerifier) {
         [self.mediaControl stopWithSuccess:successVerifier
                                    failure:failureVerifier];
     }];
}

- (void)testStopErrorShouldCallStopFailureBlock {
    [self checkTaskErrorOnStubRecorder:OCMExpect([self.playerMockCast stop])
      shouldCallFailureBlockUsingBlock:
     ^(SuccessBlock successVerifier, FailureBlock failureVerifier) {
         [self.mediaControl stopWithSuccess:successVerifier
                                    failure:failureVerifier];
     }];
}

- (void)testStopSuccessShouldNotCrashWithNilSuccessBlock {
    BFTask *task = [BFTask taskWithResult:nil];
    [OCMExpect([self.playerMockCast stop]) andReturn:task];
    XCTAssertNoThrow([self.mediaControl stopWithSuccess:nil failure:nil],
                     @"success nil block should be allowed");
}

- (void)testStopErrorShouldNotCrashWithNilFailureBlock {
    BFTask *task = [self errorTask];
    [OCMExpect([self.playerMockCast stop]) andReturn:task];
    XCTAssertNoThrow([self.mediaControl stopWithSuccess:nil failure:nil],
                     @"failure nil block should be allowed");
}

- (void)testRewindShouldReturnNotSupportedError {
    [self checkOperationShouldReturnNotSupportedErrorUsingBlock:
     ^(SuccessBlock successVerifier, FailureBlock failureVerifier) {
         [self.mediaControl rewindWithSuccess:successVerifier
                                      failure:failureVerifier];
     }];
}

- (void)testFastForwardShouldReturnNotSupportedError {
    [self checkOperationShouldReturnNotSupportedErrorUsingBlock:
     ^(SuccessBlock successVerifier, FailureBlock failureVerifier) {
         [self.mediaControl fastForwardWithSuccess:successVerifier
                                           failure:failureVerifier];
     }];
}

- (void)testSeekShouldSeekAbsolute {
    OCMExpect([self.playerMock seekToPosition:987543 andMode:ABSOLUTE]);

    [self.mediaControl seek:987.543 success:nil failure:nil];

    OCMVerifyAll(self.playerMock);
}

- (void)testSeekSuccessShouldCallSeekSuccessBlock {
    [self checkTaskSuccessOnStubRecorder:[OCMExpect([self.playerMock seekToPosition:0 andMode:0])
                                          ignoringNonObjectArgs]
        shouldCallSuccessBlockUsingBlock:
     ^(SuccessBlock successVerifier, FailureBlock failureVerifier) {
         [self.mediaControl seek:42
                         success:successVerifier
                         failure:failureVerifier];
     }];
}

- (void)testSeekErrorShouldCallSeekFailureBlock {
    [self checkTaskErrorOnStubRecorder:[OCMExpect([self.playerMock seekToPosition:0 andMode:0])
                                        ignoringNonObjectArgs]
      shouldCallFailureBlockUsingBlock:
     ^(SuccessBlock successVerifier, FailureBlock failureVerifier) {
         [self.mediaControl seek:42
                         success:successVerifier
                         failure:failureVerifier];
     }];
}

- (void)testSeekSuccessShouldNotCrashWithNilSuccessBlock {
    BFTask *task = [BFTask taskWithResult:nil];
    [[OCMExpect([self.playerMock seekToPosition:0 andMode:0]) ignoringNonObjectArgs] andReturn:task];
    XCTAssertNoThrow([self.mediaControl seek:42 success:nil failure:nil],
                     @"success nil block should be allowed");
}

- (void)testSeekErrorShouldNotCrashWithNilFailureBlock {
    BFTask *task = [self errorTask];
    [[OCMExpect([self.playerMock seekToPosition:0 andMode:0]) ignoringNonObjectArgs] andReturn:task];
    XCTAssertNoThrow([self.mediaControl seek:42 success:nil failure:nil],
                     @"failure nil block should be allowed");
}

- (void)testGetDurationShouldGetDuration {
    OCMExpect([self.playerMock getDuration]);

    [self.mediaControl getDurationWithSuccess:nil failure:nil];

    OCMVerifyAll(self.playerMock);
}

- (void)testGetDurationSuccessShouldCallGetDurationSuccessBlock {
    BFTask *task = [BFTask taskWithResult:@42530l];
    [self checkTaskSuccess:task
            onStubRecorder:OCMExpect([self.playerMock getDuration])
shouldCallSuccessBlockUsingBlock:
     ^(SuccessBlock successVerifier, FailureBlock failureVerifier) {
         [self.mediaControl getDurationWithSuccess:^(NSTimeInterval duration) {
             XCTAssertEqualWithAccuracy(duration, 42.53, kTimeIntervalAccuracy,
                                        @"the duration should be in seconds");
             successVerifier(nil);
         }
                                           failure:failureVerifier];
     }];
}

- (void)testGetDurationErrorShouldCallGetDurationFailureBlock {
    [self checkTaskErrorOnStubRecorder:OCMExpect([self.playerMock getDuration])
      shouldCallFailureBlockUsingBlock:
     ^(SuccessBlock successVerifier, FailureBlock failureVerifier) {
         [self.mediaControl getDurationWithSuccess:^(NSTimeInterval duration) {
             successVerifier(nil);
         }
                                           failure:failureVerifier];
     }];
}

- (void)testGetDurationSuccessShouldNotCrashWithNilSuccessBlock {
    BFTask *task = [BFTask taskWithResult:nil];
    [OCMExpect([self.playerMock getDuration]) andReturn:task];
    XCTAssertNoThrow([self.mediaControl getDurationWithSuccess:nil failure:nil],
                     @"success nil block should be allowed");
}

- (void)testGetDurationErrorShouldNotCrashWithNilFailureBlock {
    BFTask *task = [self errorTask];
    [OCMExpect([self.playerMock getDuration]) andReturn:task];
    XCTAssertNoThrow([self.mediaControl getDurationWithSuccess:nil failure:nil],
                     @"failure nil block should be allowed");
}

- (void)testGetPositionShouldGetPosition {
    OCMExpect([self.playerMock getPosition]);

    [self.mediaControl getPositionWithSuccess:nil failure:nil];

    OCMVerifyAll(self.playerMock);
}

- (void)testGetPositionSuccessShouldCallGetPositionSuccessBlock {
    BFTask *task = [BFTask taskWithResult:@9008765l];
    [self checkTaskSuccess:task
            onStubRecorder:OCMExpect([self.playerMock getPosition])
shouldCallSuccessBlockUsingBlock:
     ^(SuccessBlock successVerifier, FailureBlock failureVerifier) {
         [self.mediaControl getPositionWithSuccess:^(NSTimeInterval duration) {
             XCTAssertEqualWithAccuracy(duration, 9008.765, kTimeIntervalAccuracy,
                                        @"the position should be in seconds");
             successVerifier(nil);
         }
                                           failure:failureVerifier];
     }];
}

- (void)testGetPositionErrorShouldCallGetPositionFailureBlock {
    [self checkTaskErrorOnStubRecorder:OCMExpect([self.playerMock getPosition])
      shouldCallFailureBlockUsingBlock:
     ^(SuccessBlock successVerifier, FailureBlock failureVerifier) {
         [self.mediaControl getPositionWithSuccess:^(NSTimeInterval duration) {
             successVerifier(nil);
         }
                                           failure:failureVerifier];
     }];
}

- (void)testGetPositionSuccessShouldNotCrashWithNilSuccessBlock {
    BFTask *task = [BFTask taskWithResult:nil];
    [OCMExpect([self.playerMock getPosition]) andReturn:task];
    XCTAssertNoThrow([self.mediaControl getPositionWithSuccess:nil failure:nil],
                     @"success nil block should be allowed");
}

- (void)testGetPositionErrorShouldNotCrashWithNilFailureBlock {
    BFTask *task = [self errorTask];
    [OCMExpect([self.playerMock getPosition]) andReturn:task];
    XCTAssertNoThrow([self.mediaControl getPositionWithSuccess:nil failure:nil],
                     @"failure nil block should be allowed");
}

- (void)testGetPlayStateShouldGetStatus {
    OCMExpect([self.playerMock getStatus]);

    [self.mediaControl getPlayStateWithSuccess:nil failure:nil];

    OCMVerifyAll(self.playerMock);
}

- (void)testGetStatusSuccessShouldCallGetPlayStateSuccessBlock {
    id statusMock = OCMStrictClassMock([MediaPlayerStatus class]);
    OCMExpect([(MediaPlayerStatus *)statusMock state]).andReturn(Playing);
    BFTask *task = [BFTask taskWithResult:statusMock];
    [self checkTaskSuccess:task
            onStubRecorder:OCMExpect([self.playerMock getStatus])
shouldCallSuccessBlockUsingBlock:
     ^(SuccessBlock successVerifier, FailureBlock failureVerifier) {
         [self.mediaControl getPlayStateWithSuccess:^(MediaControlPlayState state) {
             XCTAssertEqual(state, MediaControlPlayStatePlaying,
                            @"the play state is incorrect");
             successVerifier(nil);
         }
                                            failure:failureVerifier];
     }];
}

- (void)testGetStatusShouldCallGetPlayStateFailureBlock {
    [self checkTaskErrorOnStubRecorder:OCMExpect([self.playerMock getStatus])
      shouldCallFailureBlockUsingBlock:
     ^(SuccessBlock successVerifier, FailureBlock failureVerifier) {
         [self.mediaControl getPlayStateWithSuccess:^(MediaControlPlayState state) {
             successVerifier(nil);
         }
                                            failure:failureVerifier];
     }];
}

- (void)testGetStatusSuccessShouldNotCrashWithNilSuccessBlock {
    BFTask *task = [BFTask taskWithResult:nil];
    [OCMExpect([self.playerMock getStatus]) andReturn:task];
    XCTAssertNoThrow([self.mediaControl getPlayStateWithSuccess:nil failure:nil],
                     @"success nil block should be allowed");
}

- (void)testGetStatusErrorShouldNotCrashWithNilFailureBlock {
    BFTask *task = [self errorTask];
    [OCMExpect([self.playerMock getStatus]) andReturn:task];
    XCTAssertNoThrow([self.mediaControl getPlayStateWithSuccess:nil failure:nil],
                     @"failure nil block should be allowed");
}

- (void)testGetMediaMetaDataShouldGetMediaInfo {
    OCMExpect([self.playerMock getMediaInfo]);

    [self.mediaControl getMediaMetaDataWithSuccess:nil failure:nil];

    OCMVerifyAll(self.playerMock);
}

- (void)testGetMediaInfoSuccessShouldCallGetMediaMetaDataSuccessBlock {
    id infoMock = OCMStrictClassMock([MediaPlayerInfo class]);
    NSString *json = (@"{\"type\": \"image/png\","
                      @"\"poster\": \"http://example.com/icon.png\","
                      @"\"title\": \"Hello, <World> &]]> \\\"others'\\\\ ура ξ中]]>…\","
                      @"\"description\": \"Description…\"}");
    [OCMExpect([infoMock metadata]) andReturn:json];

    BFTask *task = [BFTask taskWithResult:infoMock];
    [self checkTaskSuccess:task
            onStubRecorder:OCMExpect([self.playerMock getMediaInfo])
shouldCallSuccessBlockUsingBlock:
     ^(SuccessBlock successVerifier, FailureBlock failureVerifier) {
         [self.mediaControl getMediaMetaDataWithSuccess:^(NSDictionary *metadata) {
             XCTAssertEqualObjects(metadata,
                                   (@{@"title": @"Hello, <World> &]]> \"others'\\ ура ξ中]]>…",
                                      @"subtitle": @"Description…",
                                      @"iconURL": @"http://example.com/icon.png"}),
                                   @"metadata is incorrect");
             successVerifier(nil);
         }
                                                failure:failureVerifier];
     }];
}

- (void)testGetMediaInfoWithoutDataSuccessShouldCallGetMediaMetaDataSuccessBlock {
    id infoMock = OCMStrictClassMock([MediaPlayerInfo class]);
    NSString *json = @"{}";
    [OCMExpect([infoMock metadata]) andReturn:json];

    BFTask *task = [BFTask taskWithResult:infoMock];
    [self checkTaskSuccess:task
            onStubRecorder:OCMExpect([self.playerMock getMediaInfo])
shouldCallSuccessBlockUsingBlock:
     ^(SuccessBlock successVerifier, FailureBlock failureVerifier) {
         [self.mediaControl getMediaMetaDataWithSuccess:^(NSDictionary *metadata) {
             XCTAssertEqualObjects(metadata, @{}, @"metadata is incorrect");
             successVerifier(nil);
         }
                                                failure:failureVerifier];
     }];
}

- (void)testGetMediaInfoShouldCallGetMediaMetaDataFailureBlock {
    [self checkTaskErrorOnStubRecorder:OCMExpect([self.playerMock getMediaInfo])
      shouldCallFailureBlockUsingBlock:
     ^(SuccessBlock successVerifier, FailureBlock failureVerifier) {
         [self.mediaControl getMediaMetaDataWithSuccess:successVerifier
                                                failure:failureVerifier];
     }];
}

- (void)testGetMediaInfoSuccessShouldNotCrashWithNilSuccessBlock {
    id playerInfoMock = OCMClassMock([MediaPlayerInfo class]);
    [OCMStub([playerInfoMock metadata]) andReturn:@"{}"];
    BFTask *task = [BFTask taskWithResult:playerInfoMock];
    [OCMExpect([self.playerMock getMediaInfo]) andReturn:task];
    XCTAssertNoThrow([self.mediaControl getMediaMetaDataWithSuccess:nil failure:nil],
                     @"success nil block should be allowed");
}

- (void)testGetMediaInfoErrorShouldNotCrashWithNilFailureBlock {
    BFTask *task = [self errorTask];
    [OCMExpect([self.playerMock getMediaInfo]) andReturn:task];
    XCTAssertNoThrow([self.mediaControl getMediaMetaDataWithSuccess:nil failure:nil],
                     @"failure nil block should be allowed");
}

- (void)testSubscribeMediaInfoShouldReturnNotSupportedError {
    [self checkOperationShouldReturnNotSupportedErrorUsingBlock:
     ^(SuccessBlock successVerifier, FailureBlock failureVerifier) {
         [self.mediaControl subscribeMediaInfoWithSuccess:successVerifier
                                                  failure:failureVerifier];
     }];
}

- (void)testSubscribeMediaInfoShouldReturnNil {
    XCTAssertNil([self.mediaControl subscribeMediaInfoWithSuccess:nil
                                                          failure:nil],
                 @"media info subscription is not supported");
}

#pragma mark - PlayState Subscription Tests

- (void)testSubscribePlayStateShouldAddStatusListener {
    OCMExpect([self.playerMock addStatusListener:OCMOCK_NOTNIL]);
    OCMStub([self.playerMock getStatus]);

    [self.mediaControl subscribePlayStateWithSuccess:nil failure:nil];

    OCMVerifyAll(self.playerMock);
}

- (void)testSubscribePlayStateTwiceShouldAddStatusListenerOnce {
    __block NSUInteger callCount = 0;
    [OCMExpect([self.playerMock addStatusListener:OCMOCK_NOTNIL]) andDo:^(NSInvocation *_) {
        ++callCount;
    }];
    OCMStub([self.playerMock getStatus]);

    [self.mediaControl subscribePlayStateWithSuccess:nil failure:nil];
    [self.mediaControl subscribePlayStateWithSuccess:nil failure:nil];
    XCTAssertEqual(callCount, 1, @"status listener should be added once");
}

- (void)testSubscribePlayStateShouldReturnSubscription {
    OCMStub([self.playerMock addStatusListener:OCMOCK_NOTNIL]);
    OCMStub([self.playerMock getStatus]);
    ServiceSubscription *subscription = [self.mediaControl subscribePlayStateWithSuccess:nil
                                                                                 failure:nil];
    XCTAssertNotNil(subscription, @"subscription should not be nil");
    XCTAssertFalse(subscription.isSubscribed, @"should not be subscribed yet");
}

- (void)testSubscribePlayStateTwiceShouldReturnTheSameSubscription {
    OCMStub([self.playerMock addStatusListener:OCMOCK_NOTNIL]);
    OCMStub([self.playerMock getStatus]);
    ServiceSubscription *subscription0 = [self.mediaControl subscribePlayStateWithSuccess:nil
                                                                                  failure:nil];
    ServiceSubscription *subscription1 = [self.mediaControl subscribePlayStateWithSuccess:nil
                                                                                  failure:nil];
    XCTAssertEqual(subscription0, subscription1,
                   @"The subscription should be the same object");
}

- (void)testAddStatusListenerSuccessShouldSetSubscriptionSubscribed {
    BFTask *task = [BFTask taskWithResult:nil];
    [OCMExpect([self.playerMock addStatusListener:OCMOCK_NOTNIL]) andReturn:task];
    OCMStub([self.playerMock getStatus]);

    ServiceSubscription *subscription = [self.mediaControl subscribePlayStateWithSuccess:nil
                                                                                 failure:nil];
    XCTAssertTrue(subscription.isSubscribed, @"should be subscribed");
}

- (void)testAddStatusListenerErrorShouldCallSubscriptionFailureBlock {
    OCMStub([self.playerMock getStatus]);
    [self checkTaskErrorOnStubRecorder:OCMExpect([self.playerMock addStatusListener:OCMOCK_NOTNIL])
      shouldCallFailureBlockUsingBlock:
     ^(SuccessBlock successVerifier, FailureBlock failureVerifier) {
         [self.mediaControl subscribePlayStateWithSuccess:^(MediaControlPlayState playState) {
             successVerifier(nil);
         }
                                                  failure:failureVerifier];
     }];
}

- (void)testAddStatusListenerErrorShouldNotCrashWithNilFailureBlock {
    BFTask *task = [self errorTask];
    [OCMExpect([self.playerMockCast addStatusListener:OCMOCK_ANY]) andReturn:task];
    OCMStub([self.playerMock getStatus]);
    XCTAssertNoThrow([self.mediaControl subscribePlayStateWithSuccess:nil failure:nil],
                     @"failure nil block should be allowed");
}

- (void)testOnStatusChangeShouldCallSubscriptionSuccessBlock {
    OCMStub([self.playerMock getStatus]);
    [self checkTaskSuccessOnStubRecorder:nil
        shouldCallSuccessBlockUsingBlock:
     ^(SuccessBlock successVerifier, FailureBlock failureVerifier) {
         id<MediaPlayerStatusListener> statusListener;
         BFTask *task = [BFTask taskWithResult:nil];
         [OCMExpect([self.playerMock addStatusListener:[OCMArg captureTo:&statusListener]])
          andReturn:task];

         [self.mediaControl subscribePlayStateWithSuccess:^(MediaControlPlayState playState) {
             XCTAssertEqual(playState, MediaControlPlayStateFinished,
                            @"play state is incorrect");
             successVerifier(nil);
         }
                                                  failure:failureVerifier];

         id statusMock = OCMStrictClassMock([MediaPlayerStatus class]);
         OCMExpect([(MediaPlayerStatus *)statusMock state]).andReturn(Finished);
         [statusListener onStatusChange:statusMock positionChangedTo:0];

         OCMVerifyAll(statusMock);
     }];
}

- (void)testTheSameOnStatusChangeShouldCallSubscriptionSuccessBlockOnce {
    OCMStub([self.playerMock getStatus]);
    [self checkTaskSuccessOnStubRecorder:nil
        shouldCallSuccessBlockUsingBlock:
     ^(SuccessBlock successVerifier, FailureBlock failureVerifier) {
         id<MediaPlayerStatusListener> statusListener;
         BFTask *task = [BFTask taskWithResult:nil];
         [OCMExpect([self.playerMock addStatusListener:[OCMArg captureTo:&statusListener]])
          andReturn:task];

         __block NSUInteger callCount = 0;
         [self.mediaControl subscribePlayStateWithSuccess:^(MediaControlPlayState playState) {
             ++callCount;
             XCTAssertEqual(playState, MediaControlPlayStateFinished,
                            @"play state is incorrect");
             successVerifier(nil);
         }
                                                  failure:failureVerifier];

         id statusMock = OCMStrictClassMock([MediaPlayerStatus class]);
         OCMExpect([(MediaPlayerStatus *)statusMock state]).andReturn(Finished);
         OCMExpect([(MediaPlayerStatus *)statusMock state]).andReturn(Finished);
         [statusListener onStatusChange:statusMock positionChangedTo:0];
         [statusListener onStatusChange:statusMock positionChangedTo:0];

         XCTAssertEqual(callCount, 1, @"The duplicated state should not pass");
         OCMVerifyAll(statusMock);
     }];
}

- (void)testPlayStateShouldBeDeduplicated {
    OCMStub([self.playerMock getStatus]);
    [self checkTaskSuccessOnStubRecorder:nil
        shouldCallSuccessBlockUsingBlock:
     ^(SuccessBlock successVerifier, FailureBlock failureVerifier) {
         id<MediaPlayerStatusListener> statusListener;
         BFTask *task = [BFTask taskWithResult:nil];
         [OCMExpect([self.playerMock addStatusListener:[OCMArg captureTo:&statusListener]])
          andReturn:task];

         __block NSUInteger callCount = 0;
         NSArray *expectedStates = @[@(MediaControlPlayStatePlaying),
                                     @(MediaControlPlayStatePaused),
                                     @(MediaControlPlayStateFinished)];
         [self.mediaControl subscribePlayStateWithSuccess:^(MediaControlPlayState playState) {
             XCTAssertEqual(playState, [expectedStates[callCount] integerValue],
                            @"play state is incorrect");
             ++callCount;
             successVerifier(nil);
         }
                                                  failure:failureVerifier];

         id statusMock = OCMStrictClassMock([MediaPlayerStatus class]);
         [@[@(Playing), @(Playing), @(Paused), @(Paused), @(Finished)]
          enumerateObjectsUsingBlock:^(NSNumber *stateNumber, NSUInteger idx, BOOL *stop) {
              enum MediaState state = (enum MediaState)[stateNumber integerValue];
              OCMExpect([(MediaPlayerStatus *)statusMock state]).andReturn(state);
              [statusListener onStatusChange:statusMock positionChangedTo:0];
          }];

         OCMVerifyAll(statusMock);
     }];
}

- (void)testOnStatusChangeShouldCallSubscriptionSuccessBlockOnMainThread {
    OCMStub([self.playerMock getStatus]);
    id statusMock = OCMStrictClassMock([MediaPlayerStatus class]);

    // use the default main thread block runner
    FireTVCapabilityMixin *mixin = [[FireTVCapabilityMixin alloc]
                                    initWithRemoteMediaPlayer:self.playerMock];
    self.mediaControl.capabilityMixin = mixin;

    [self checkTaskSuccessOnStubRecorder:nil
   shouldAsyncCallSuccessBlockUsingBlock:
     ^(SuccessBlock successVerifier, FailureBlock failureVerifier) {
         id<MediaPlayerStatusListener> statusListener;
         BFTask *task = [BFTask taskWithResult:nil];
         [OCMExpect([self.playerMock addStatusListener:[OCMArg captureTo:&statusListener]])
          andReturn:task];

         [self.mediaControl subscribePlayStateWithSuccess:^(MediaControlPlayState playState) {
             XCTAssertTrue([NSThread isMainThread], @"Should be called on main thread");
             XCTAssertEqual(playState, MediaControlPlayStateUnknown,
                            @"play state is incorrect");
             successVerifier(nil);
         }
                                                  failure:failureVerifier];

         dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
             OCMExpect([(MediaPlayerStatus *)statusMock state]).andReturn(ReadyToPlay);
             [statusListener onStatusChange:statusMock positionChangedTo:0];
         });
     }];

    OCMVerifyAll(statusMock);
}

- (void)testSubscribingShouldCallSubscriptionSuccessBlockWithCurrentValue {
    id statusMock = OCMStrictClassMock([MediaPlayerStatus class]);
    OCMExpect([(MediaPlayerStatus *)statusMock state]).andReturn(NoMedia);
    BFTask *getStatusTask = [BFTask taskWithResult:statusMock];
    [self checkTaskSuccess:getStatusTask
            onStubRecorder:OCMExpect([self.playerMockCast getStatus])
shouldCallSuccessBlockUsingBlock:
     ^(SuccessBlock successVerifier, FailureBlock failureVerifier) {
         id<MediaPlayerStatusListener> statusListener;
         BFTask *task = [BFTask taskWithResult:nil];
         [OCMExpect([self.playerMock addStatusListener:[OCMArg captureTo:&statusListener]]) andReturn:task];

         [self.mediaControl subscribePlayStateWithSuccess:^(MediaControlPlayState playState) {
             XCTAssertEqual(playState, MediaControlPlayStateIdle,
                           @"should call success after subscription");
             successVerifier(nil);
         }
                                              failure:failureVerifier];

         OCMVerifyAll(self.playerMock);
     }];
}

- (void)testSubscribingTwiceShouldCallLatestSubscriptionSuccessBlocksWithCurrentValue {
    id statusMock = OCMStrictClassMock([MediaPlayerStatus class]);
    OCMExpect([(MediaPlayerStatus *)statusMock state]).andReturn(NoMedia);
    OCMExpect([(MediaPlayerStatus *)statusMock state]).andReturn(PreparingMedia);
    BFTask *getStatusTask = [BFTask taskWithResult:statusMock];
    [self checkTaskSuccess:getStatusTask
            onStubRecorder:OCMExpect([self.playerMockCast getStatus])
shouldCallSuccessBlockUsingBlock:
     ^(SuccessBlock successVerifier, FailureBlock failureVerifier) {
         id<MediaPlayerStatusListener> statusListener;
         BFTask *task = [BFTask taskWithResult:nil];
         [OCMExpect([self.playerMock addStatusListener:[OCMArg captureTo:&statusListener]]) andReturn:task];

         [self.mediaControl subscribePlayStateWithSuccess:^(MediaControlPlayState playState) {
             XCTAssertEqual(playState, MediaControlPlayStateIdle,
                           @"should call success after subscription");
             successVerifier(nil);
         }
                                                  failure:failureVerifier];

         [self checkTaskSuccess:getStatusTask
                 onStubRecorder:OCMExpect([self.playerMockCast getStatus])
shouldCallSuccessBlockUsingBlock:
          ^(SuccessBlock successVerifier, FailureBlock failureVerifier) {
              [self.mediaControl subscribePlayStateWithSuccess:^(MediaControlPlayState playState) {
                  // and we don't expect the first success to be called
                  XCTAssertEqual(playState, MediaControlPlayStateBuffering,
                                 @"should call second subscription's success");
                  successVerifier(nil);
              }
                                                       failure:failureVerifier];
          }];

         OCMVerifyAll(self.playerMock);
     }];
}

- (void)testOnStatusChangeSuccessShouldNotCrashWithNilSuccessBlock {
    id<MediaPlayerStatusListener> statusListener;
    OCMExpect([self.playerMock addStatusListener:[OCMArg captureTo:&statusListener]]);
    OCMStub([self.playerMock getStatus]);

    [self.mediaControl subscribePlayStateWithSuccess:nil failure:nil];

    id statusMock = OCMStrictClassMock([MediaPlayerStatus class]);
    OCMExpect([(MediaPlayerStatus *)statusMock state]).andReturn(Finished);
    XCTAssertNoThrow([statusListener onStatusChange:statusMock positionChangedTo:0],
                     @"success nil block should be allowed");
}

- (void)testUnsubscribeMethodShouldRemoveStatusListener {
    BFTask *task = [BFTask taskWithResult:nil];
    [OCMStub([self.playerMock addStatusListener:OCMOCK_NOTNIL]) andReturn:task];
    OCMStub([self.playerMock getStatus]);
    ServiceSubscription *subscription = [self.mediaControl subscribePlayStateWithSuccess:nil
                                                                                 failure:nil];

    OCMExpect([self.playerMock removeStatusListener:OCMOCK_NOTNIL]);
    [subscription unsubscribe];

    XCTAssertFalse(subscription.isSubscribed,
                   @"the subscription shouldn't be subscribed anymore");
    OCMVerifyAll(self.playerMock);
}

- (void)testUnsubscribeSubscriptionsShouldRemoveStatusListener {
    BFTask *task = [BFTask taskWithResult:nil];
    id<MediaPlayerStatusListener> statusListener;
    [OCMStub([self.playerMock addStatusListener:[OCMArg captureTo:&statusListener]]) andReturn:task];
    OCMStub([self.playerMock getStatus]);
    ServiceSubscription *subscription = [self.mediaControl subscribePlayStateWithSuccess:nil
                                                                                 failure:nil];

    OCMExpect([self.playerMock removeStatusListener:statusListener]);
    [self.mediaControl unsubscribeSubscriptions];

    XCTAssertFalse(subscription.isSubscribed,
                   @"the subscription shouldn't be subscribed anymore");
    OCMVerifyAll(self.playerMock);
}

- (void)testUnsubscribeNotSubscribedSubscriptionsShouldNotRemoveStatusListener {
    [self.mediaControl unsubscribeSubscriptions];
    OCMVerifyAll(self.playerMock);
}

- (void)testPauseSubscriptionsShouldRemoveStatusListener {
    BFTask *task = [BFTask taskWithResult:nil];
    id<MediaPlayerStatusListener> statusListener;
    [OCMStub([self.playerMock addStatusListener:[OCMArg captureTo:&statusListener]]) andReturn:task];
    OCMStub([self.playerMock getStatus]);
    ServiceSubscription *subscription = [self.mediaControl subscribePlayStateWithSuccess:nil
                                                                                 failure:nil];

    OCMExpect([self.playerMock removeStatusListener:statusListener]);
    [self.mediaControl pauseSubscriptions];

    XCTAssertTrue(subscription.isSubscribed,
                  @"the subscription should still be subscribed");
    OCMVerifyAll(self.playerMock);
}

- (void)testResumeSubscriptionsShouldAddStatusListener {
    BFTask *task = [BFTask taskWithResult:nil];
    id<MediaPlayerStatusListener> statusListener;
    [OCMExpect([self.playerMock addStatusListener:[OCMArg captureTo:&statusListener]]) andReturn:task];
    OCMStub([self.playerMock getStatus]);
    ServiceSubscription *subscription = [self.mediaControl subscribePlayStateWithSuccess:nil
                                                                                 failure:nil];

    OCMExpect([self.playerMock removeStatusListener:statusListener]);
    [self.mediaControl pauseSubscriptions];

    OCMExpect([self.playerMock addStatusListener:statusListener]);
    [self.mediaControl resumeSubscriptions];

    XCTAssertTrue(subscription.isSubscribed,
                  @"the subscription should still be subscribed");
    OCMVerifyAll(self.playerMock);
}

#pragma mark - MediaState to MediaControlPlayState Tests

- (void)testShouldConvertMediaStateToProperPlayState {
    NSDictionary *expectedMappings = @{@(NoMedia): @(MediaControlPlayStateIdle),
                                       @(PreparingMedia): @(MediaControlPlayStateBuffering),
                                       @(ReadyToPlay): @(MediaControlPlayStateUnknown),
                                       @(Playing): @(MediaControlPlayStatePlaying),
                                       @(Paused): @(MediaControlPlayStatePaused),
                                       @(Seeking): @(MediaControlPlayStateUnknown),
                                       @(Finished): @(MediaControlPlayStateFinished),
                                       @(Error): @(MediaControlPlayStateUnknown),
                                       @(-1): @(MediaControlPlayStateUnknown)};
    [expectedMappings enumerateKeysAndObjectsUsingBlock:^(NSNumber *mediaState,
                                                          NSNumber *playState,
                                                          BOOL *stop) {
        enum MediaState mediaStateValue = (enum MediaState)[mediaState integerValue];
        XCTAssertEqual([self.mediaControl playStateForMediaState:mediaStateValue],
                       (MediaControlPlayState)[playState integerValue],
                       @"Conversion is incorrect");
    }];
}

@end
