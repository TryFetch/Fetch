//
//  FireTVServiceTests.m
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
#import "ConnectSDKDefaultPlatforms.h"
#import "DispatchQueueBlockRunner.h"
#import "FireTVDiscoveryProvider.h"
#import "FireTVMediaControl.h"
#import "FireTVMediaPlayer.h"
#import "MediaPlayer.h"
#import "SynchronousBlockRunner.h"

#import "OCMArg+ArgumentCaptor.h"

#import <AmazonFling/RemoteMediaPlayer.h>

/// Expects a @c call on the given @c mock, runs the @c call on the @c service
/// under test, and verifies the mock.
#define GENERATE_REDIRECT_TEST_BODY(mock, call) ({ \
    OCMExpect([mock call]); \
    [self.service call]; \
    OCMVerifyAll(mock); \
})

/// Expects a @c call on the given @c mock returning the given @c mockValue,
/// runs the @c call on the @c service under test, verifies it returns the
/// @c mockValue, and verifies the mock.
#define GENERATE_REDIRECT_TEST_BODY_RETURN(mock, call, mockValue) ({ \
    [OCMExpect([mock call]) andReturn:mockValue]; \
    XCTAssertEqual([self.service call], mockValue); \
    OCMVerifyAll(mock); \
})


@interface FireTVServiceTests : XCTestCase

@property (nonatomic, strong) FireTVService *service;
@property (nonatomic, strong) id /*FireTVMediaPlayer **/ playerMock;
@property (nonatomic, strong) id /*FireTVMediaControl **/ controlMock;
@property (nonatomic, strong) id /*MediaInfo **/ mediaInfoMock;
@property (nonatomic, strong) SuccessBlock success;
@property (nonatomic, strong) FailureBlock failure;
@property (nonatomic, strong) MediaPlayerDisplaySuccessBlock displaySuccess;
@property (nonatomic, strong) ServiceDescription *serviceDescription;
@property (nonatomic, strong) id /*AppStateChangeNotifier **/ stateNotifierMock;

@end

@implementation FireTVServiceTests

#pragma mark - Setup

- (void)setUp {
    [super setUp];

    self.stateNotifierMock = OCMClassMock([AppStateChangeNotifier class]);
    self.service = [[FireTVService alloc]
                    initWithAppStateChangeNotifier:self.stateNotifierMock];
    self.service.delegateBlockRunner = [SynchronousBlockRunner new];

    self.playerMock = OCMStrictClassMock([FireTVMediaPlayer class]);
    self.service.fireTVMediaPlayer = self.playerMock;

    self.controlMock = OCMStrictClassMock([FireTVMediaControl class]);
    self.service.fireTVMediaControl = self.controlMock;

    self.mediaInfoMock = OCMClassMock([MediaInfo class]);
    self.success = ^(id _) {};
    self.failure = ^(NSError *e) {};
    self.displaySuccess = ^(LaunchSession *a, id<MediaControl> b) {};
}

- (void)tearDown {
    self.serviceDescription = nil;
    self.displaySuccess = nil;
    self.mediaInfoMock = nil;
    self.failure = nil;
    self.success = nil;
    self.controlMock = nil;
    self.playerMock = nil;
    self.service = nil;
    self.stateNotifierMock = nil;

    [super tearDown];
}

#pragma mark - Lazy Properties

- (ServiceDescription *)serviceDescription {
    if (!_serviceDescription) {
        static NSString *const kUUID = @"FBA886DF-286C-4052-8F8F-7220DA1F1526";
        _serviceDescription = [ServiceDescription descriptionWithAddress:kUUID
                                                                    UUID:kUUID];
        _serviceDescription.serviceId = kConnectSDKFireTVServiceId;
        _serviceDescription.friendlyName = @"name";
        _serviceDescription.device = OCMProtocolMock(@protocol(RemoteMediaPlayer));
    }

    return _serviceDescription;
}

#pragma mark - General Instance Tests

- (void)testInstanceShouldBeCreated {
    XCTAssertNotNil(self.service, @"Instance should be created");
}

- (void)testShouldBeSubclassOfDeviceService {
    XCTAssertTrue([self.service isKindOfClass:[DeviceService class]],
                  @"FireTVService should inherit from DeviceService");
}

- (void)testShouldConformToMediaPlayerProtocol {
    XCTAssertTrue([self.service.class conformsToProtocol:@protocol(MediaPlayer)],
                  @"FireTVService is a facade, it should give access to a MediaPlayer");
}

- (void)testShouldConformToMediaControlProtocol {
    XCTAssertTrue([self.service.class conformsToProtocol:@protocol(MediaControl)],
                  @"FireTVService is a facade, it should give access to a MediaControl");
}

- (void)testShouldGetFireTVMediaPlayer {
    XCTAssertEqual(self.service.fireTVMediaPlayer, self.playerMock,
                   @"Should get fireTVMediaPlayer");
}

- (void)testShouldGetFireTVMediaControl {
    XCTAssertEqual(self.service.fireTVMediaControl, self.controlMock,
                   @"Should get fireTVMediaControl");
}

- (void)testDefaultFireTVMediaPlayerShouldBeCreated {
    FireTVService *service = [FireTVService new];
    XCTAssertTrue([service.fireTVMediaPlayer isKindOfClass:[FireTVMediaPlayer class]],
                  @"Should create a real FireTVMediaPlayer");
}

- (void)testDefaultFireTVMediaControlShouldBeCreated {
    FireTVService *service = [FireTVService new];
    XCTAssertTrue([service.fireTVMediaControl isKindOfClass:[FireTVMediaControl class]],
                  @"Should create a real FireTVMediaControl");
}

- (void)testShouldThrowExceptionOnUnknownSelector {
#pragma clang diagnostic push
#pragma clang diagnostic ignored "-Wundeclared-selector"
    XCTAssertThrowsSpecificNamed([self.service performSelector:@selector(foo)],
                                 NSException,
                                 NSInvalidArgumentException,
                                 @"Should throw unrecognized selector exception");
#pragma clang diagnostic pop
}
#pragma mark - DeviceService-related Tests

- (void)testServiceShouldMapToFireTVDiscoveryProviderInDefaultPlatforms {
    NSString *serviceString = NSStringFromClass([FireTVService class]);
    NSString *discoveryProvider = kConnectSDKDefaultPlatforms[serviceString];
    XCTAssertEqualObjects(discoveryProvider,
                          NSStringFromClass([FireTVDiscoveryProvider class]),
                          @"Service should use FireTV Discovery Provider "
                          @"in the default platforms");
}

- (void)testDiscoveryParametersShouldReturnCorrectServiceId {
    XCTAssertEqualObjects([FireTVService discoveryParameters],
                          @{@"serviceId": kConnectSDKFireTVServiceId},
                          @"Discovery parameters should return FireTV service id");
}

- (void)testShouldNotRequirePairing {
    XCTAssertFalse(self.service.requiresPairing,
                   @"The service should not require pairing");
}

- (void)testShouldHaveSpecificCapabilities {
    NSSet *expectedCapabilities = [NSSet setWithObjects:
                                   kMediaPlayerDisplayImage,
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
                                   kMediaControlSeek,
                                   kMediaControlPlayState,
                                   kMediaControlPlayStateSubscribe,
                                   kMediaControlPosition,
                                   kMediaControlMetadata,
                                   nil];
    NSSet *actualCapabilities = [NSSet setWithArray:self.service.capabilities];
    XCTAssertEqualObjects(expectedCapabilities, actualCapabilities,
                          @"The MediaPlayer capabilities are incorrect");
}

- (void)testRemoteMediaPlayerShouldBeNilIfServiceDescriptionIsNil {
    XCTAssertNil(self.service.serviceDescription,
                 @"Default serviceDescription should be nil (sanity check)");
    XCTAssertNil(self.service.remoteMediaPlayer,
                 @"remoteMediaPlayer should be nil when serviceDescription is nil");
}

- (void)testRemoteMediaPlayerShouldBeSetFromServiceDescription {
    OCMStub([self.playerMock setCapabilityMixin:OCMOCK_ANY]);
    OCMStub([self.controlMock setCapabilityMixin:OCMOCK_ANY]);
    self.service.serviceDescription = self.serviceDescription;
    XCTAssertEqual(self.service.remoteMediaPlayer, self.serviceDescription.device,
                   @"The remoteMediaPlayer should be used from ServiceDescription");
}

- (void)testUsingNilDeviceInServiceDescriptionShouldThrowException {
    self.serviceDescription.device = nil;
    XCTAssertThrowsSpecificNamed(self.service.serviceDescription = self.serviceDescription,
                                 NSException,
                                 NSInternalInconsistencyException,
                                 @"The RemoteMediaPlayer device cannot be nil");
}

- (void)testUsingInvalidDeviceInServiceDescriptionShouldThrowException {
    self.serviceDescription.device = [NSNull null];
    XCTAssertThrowsSpecificNamed(self.service.serviceDescription = self.serviceDescription,
                                 NSException,
                                 NSInternalInconsistencyException,
                                 @"The RemoteMediaPlayer device cannot be invalid");
}

- (void)testDefaultBlockRunnerShouldBeMainQueueRunner {
    FireTVService *service = [FireTVService new];
    XCTAssertEqualObjects(service.delegateBlockRunner,
                          [DispatchQueueBlockRunner mainQueueRunner],
                          @"Delegate blocks should run on main queue by default");
}

- (void)testShouldBeConnectable {
    XCTAssertTrue(self.service.isConnectable,
                  @"The service should be connectable even though it already "
                  @"has a device to work with");
}

- (void)testConnectShouldCallConnectionSuccessDelegate {
    id delegateMock = OCMStrictProtocolMock(@protocol(DeviceServiceDelegate));
    self.service.delegate = delegateMock;

    OCMExpect([delegateMock deviceServiceConnectionSuccess:self.service]);
    [self.service connect];
    OCMVerifyAll(delegateMock);
}

- (void)testConnectShouldSetConnected {
    [self.service connect];
    XCTAssertTrue(self.service.connected,
                  @"Service should be connected after connect");
}

- (void)testDisconnectShouldCallDisconnectedWithNoError {
    id delegateMock = OCMStrictProtocolMock(@protocol(DeviceServiceDelegate));
    self.service.delegate = delegateMock;

    OCMStub([delegateMock deviceServiceConnectionSuccess:self.service]);
    [self.service connect];

    OCMExpect([delegateMock deviceService:self.service
                    disconnectedWithError:nil]);
    OCMStub([self.controlMock unsubscribeSubscriptions]);
    [self.service disconnect];
    OCMVerifyAll(delegateMock);
}

- (void)testDisconnectShouldResetConnected {
    [self.service connect];
    OCMStub([self.controlMock unsubscribeSubscriptions]);
    [self.service disconnect];
    XCTAssertFalse(self.service.connected,
                   @"Service should not be connected after disconnect");
}

- (void)testDisconnectShouldUnsubscribeMediaControlSubscriptions {
    OCMStub([self.playerMock setCapabilityMixin:OCMOCK_ANY]);
    OCMStub([self.controlMock setCapabilityMixin:OCMOCK_ANY]);
    self.service.serviceDescription = self.serviceDescription;
    [self.service connect];

    OCMStub([self.controlMock subscribePlayStateWithSuccess:nil failure:nil]);
    [self.service subscribePlayStateWithSuccess:nil failure:nil];

    OCMExpect([self.controlMock unsubscribeSubscriptions]);
    [self.service disconnect];

    OCMVerifyAll(self.controlMock);
}

#pragma mark - MediaPlayer Tests

- (void)testMediaPlayerShouldReturnFireTVMediaPlayer {
    XCTAssertEqual([self.service mediaPlayer], self.playerMock,
                   @"Should return the fireTVMediaPlayer");
}

- (void)testMediaPlayerPriorityShouldRedirectToFireTVMediaPlayer {
    OCMExpect([self.playerMock mediaPlayerPriority]).andReturn(CapabilityPriorityLevelLow);
    XCTAssertEqual([self.service mediaPlayerPriority], CapabilityPriorityLevelLow);
    OCMVerifyAll(self.playerMock);
}

- (void)testDisplayImageShouldRedirectToFireTVMediaPlayer {
    GENERATE_REDIRECT_TEST_BODY(self.playerMock,
                                displayImageWithMediaInfo:self.mediaInfoMock
                                success:self.success
                                failure:self.failure);
}

- (void)testPlayMediaShouldRedirectToFireTVMediaPlayer {
    GENERATE_REDIRECT_TEST_BODY(self.playerMock,
                                playMediaWithMediaInfo:self.mediaInfoMock
                                shouldLoop:YES
                                success:self.success
                                failure:self.failure);
}

- (void)testCloseMediaShouldRedirectToFireTVMediaPlayer {
    id sessionMock = OCMClassMock([LaunchSession class]);
    GENERATE_REDIRECT_TEST_BODY(self.playerMock,
                                closeMedia:sessionMock
                                success:self.success
                                failure:self.failure);
}

#pragma mark - MediaPlayer Deprecated Methods Tests

#pragma clang diagnostic push
#pragma clang diagnostic ignored "-Wdeprecated-declarations"
- (void)testDisplayImageOldShouldRedirectToFireTVMediaPlayer {
    GENERATE_REDIRECT_TEST_BODY(self.playerMock,
                                displayImage:self.mediaInfoMock
                                success:self.displaySuccess
                                failure:self.failure);
}

- (void)testDisplayImageWithManyParametersShouldRedirectToFireTVMediaPlayer {
    id urlMock = OCMClassMock([NSURL class]);
    id iconUrlMock = OCMClassMock([NSURL class]);
    GENERATE_REDIRECT_TEST_BODY(self.playerMock,
                                displayImage:urlMock
                                iconURL:iconUrlMock
                                title:@"Title"
                                description:@"Description"
                                mimeType:@"mime"
                                success:self.displaySuccess
                                failure:self.failure);
}

- (void)testPlayMediaOldShouldRedirectToFireTVMediaPlayer {
    GENERATE_REDIRECT_TEST_BODY(self.playerMock,
                                playMedia:self.mediaInfoMock
                                shouldLoop:YES
                                success:self.displaySuccess
                                failure:self.failure);
}

- (void)testPlayMediaWithManyParametersShouldRedirectToFireTVMediaPlayer {
    id urlMock = OCMClassMock([NSURL class]);
    id iconUrlMock = OCMClassMock([NSURL class]);
    GENERATE_REDIRECT_TEST_BODY(self.playerMock,
                                playMedia:urlMock
                                iconURL:iconUrlMock
                                title:@"Title"
                                description:@"Description"
                                mimeType:@"mint"
                                shouldLoop:YES
                                success:self.displaySuccess
                                failure:self.failure);
}
#pragma clang diagnostic pop

#pragma mark - MediaControl Tests

- (void)testMediaControlShouldReturnFireTVMediaControl {
    XCTAssertEqual([self.service mediaControl], self.controlMock,
                   @"Should return the fireTVMediaControl");
}

- (void)testMediaControlPriorityShouldRedirectToFireTVMediaControl {
    OCMExpect([self.controlMock mediaControlPriority]).andReturn(CapabilityPriorityLevelLow);
    XCTAssertEqual([self.service mediaControlPriority], CapabilityPriorityLevelLow);
    OCMVerifyAll(self.controlMock);
}

- (void)testPlayShouldRedirectToFireTVMediaControl {
    GENERATE_REDIRECT_TEST_BODY(self.controlMock,
                                playWithSuccess:self.success
                                failure:self.failure);
}

- (void)testPauseShouldRedirectToFireTVMediaControl {
    GENERATE_REDIRECT_TEST_BODY(self.controlMock,
                                pauseWithSuccess:self.success
                                failure:self.failure);
}

- (void)testStopShouldRedirectToFireTVMediaControl {
    GENERATE_REDIRECT_TEST_BODY(self.controlMock,
                                stopWithSuccess:self.success
                                failure:self.failure);
}

- (void)testRewindShouldRedirectToFireTVMediaControl {
    GENERATE_REDIRECT_TEST_BODY(self.controlMock,
                                rewindWithSuccess:self.success
                                failure:self.failure);
}

- (void)testFastForwardShouldRedirectToFireTVMediaControl {
    GENERATE_REDIRECT_TEST_BODY(self.controlMock,
                                fastForwardWithSuccess:self.success
                                failure:self.failure);
}

- (void)testSeekShouldRedirectToFireTVMediaControl {
    GENERATE_REDIRECT_TEST_BODY(self.controlMock,
                                seek:42
                                success:self.success
                                failure:self.failure);
}

- (void)testGetDurationShouldRedirectToFireTVMediaControl {
    MediaDurationSuccessBlock success = ^(NSTimeInterval _) {};
    GENERATE_REDIRECT_TEST_BODY(self.controlMock,
                                getDurationWithSuccess:success
                                failure:self.failure);
}

- (void)testGetPositionShouldRedirectToFireTVMediaControl {
    MediaDurationSuccessBlock success = ^(NSTimeInterval _) {};
    GENERATE_REDIRECT_TEST_BODY(self.controlMock,
                                getPositionWithSuccess:success
                                failure:self.failure);
}

- (void)testGetMediaMetadataShouldRedirectToFireTVMediaControl {
    GENERATE_REDIRECT_TEST_BODY(self.controlMock,
                                getMediaMetaDataWithSuccess:self.success
                                failure:self.failure);
}

- (void)testGetPlayStateShouldRedirectToFireTVMediaControl {
    MediaPlayStateSuccessBlock success = ^(MediaControlPlayState _) {};
    GENERATE_REDIRECT_TEST_BODY(self.controlMock,
                                getPlayStateWithSuccess:success
                                failure:self.failure);
}

- (void)testSubscribePlayStateShouldRedirectToFireTVMediaControl {
    id subscriptionMock = OCMStrictClassMock([ServiceSubscription class]);
    MediaPlayStateSuccessBlock success = ^(MediaControlPlayState _) {};
    GENERATE_REDIRECT_TEST_BODY_RETURN(self.controlMock,
                                       subscribePlayStateWithSuccess:success
                                       failure:self.failure,
                                       subscriptionMock);
}

- (void)testSubscribeMediaInfoStateShouldRedirectToFireTVMediaControl {
    id subscriptionMock = OCMStrictClassMock([ServiceSubscription class]);
    GENERATE_REDIRECT_TEST_BODY_RETURN(self.controlMock,
                                       subscribeMediaInfoWithSuccess:self.success
                                       failure:self.failure,
                                       subscriptionMock);
}

#pragma mark - UIApplication State Change Tests

- (void)testDefaultStateNotifierShouldBeCreated {
    FireTVService *service = [FireTVService new];
    XCTAssertNotNil(service.appStateChangeNotifier,
                    @"a real AppStateChangeNotifier should be created");
}

- (void)testConnectShouldStartListeningStateNotifier {
    OCMExpect([self.stateNotifierMock startListening]);
    [self.service connect];
    OCMVerifyAll(self.stateNotifierMock);
}

- (void)testDisconnectShouldStopListeningStateNotifier {
    OCMStub([self.controlMock unsubscribeSubscriptions]);
    OCMExpect([self.stateNotifierMock stopListening]);
    [self.service connect];
    [self.service disconnect];
    OCMVerifyAll(self.stateNotifierMock);
}

- (void)testBackgroundingShouldPauseSubscriptions {
    AppStateChangeBlock backgroundStateBlock;
    OCMExpect([self.stateNotifierMock setDidBackgroundBlock:
               [OCMArg captureBlockTo:&backgroundStateBlock]]);

    self.service = [[FireTVService alloc]
                    initWithAppStateChangeNotifier:self.stateNotifierMock];
    self.service.fireTVMediaControl = self.controlMock;

    OCMExpect([self.controlMock pauseSubscriptions]);
    backgroundStateBlock();
    OCMVerifyAll(self.controlMock);
}

- (void)testForegroundingShouldResumeSubscriptions {
    AppStateChangeBlock foregroundStateBlock;
    OCMExpect([self.stateNotifierMock setDidForegroundBlock:
               [OCMArg captureBlockTo:&foregroundStateBlock]]);

    self.service = [[FireTVService alloc]
                    initWithAppStateChangeNotifier:self.stateNotifierMock];
    self.service.fireTVMediaControl = self.controlMock;

    OCMExpect([self.controlMock resumeSubscriptions]);
    foregroundStateBlock();
    OCMVerifyAll(self.controlMock);
}

@end
