//
//  FireTVDiscoveryProviderTests.m
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

#import "NSInvocation+ObjectGetter.h"

#import <AmazonFling/DiscoveryController.h>

#import "FireTVDiscoveryProvider_Private.h"
#import "CommonMacros.h"
#import "ConnectError.h"
#import "ConnectSDKDefaultPlatforms.h"
#import "DiscoveryProvider.h"
#import "DispatchQueueBlockRunner.h"
#import "FireTVService.h"
#import "ServiceDescription.h"
#import "SynchronousBlockRunner.h"

#import "OCMArg+ArgumentCaptor.h"

/**
 * Wrapper around OCMStub() to automatically count the number of invocations.
 * Exposes the @c callCount variable for that.
 */
#define OCMStubWithCallCount(invocation) \
    __block NSUInteger callCount = 0; \
    [OCMStub(invocation) andDo:^(NSInvocation *_) { \
        ++callCount; \
    }];

#define WaitForExpectations() ({ \
    [self waitForExpectationsWithTimeout:kDefaultAsyncTestTimeout \
                                 handler:^(NSError *error) { \
                                     XCTAssertNil(error); \
                                 }]; \
})

static NSString *const kTestUUID = @"511ECB40-879D-4EFC-AF7B-01B8BC036779";


@interface FireTVDiscoveryProviderTests : XCTestCase

@property (strong) FireTVDiscoveryProvider *provider;
@property (strong) id /*DiscoveryController **/ discoveryControllerMock;
@property (strong) id /*<DiscoveryProviderDelegate>*/ delegateMock;
@property (strong) id<BlockRunner> syncRunner;
@property (strong) id /*<RemoteMediaPlayer>*/ playerMock;

@end

@implementation FireTVDiscoveryProviderTests

#pragma mark - Setup

- (void)setUp {
    [super setUp];

    self.discoveryControllerMock = OCMClassMock([DiscoveryController class]);
    self.provider = [[FireTVDiscoveryProvider alloc]
                     initWithDiscoveryController:self.discoveryControllerMock];

    self.delegateMock = OCMProtocolMock(@protocol(DiscoveryProviderDelegate));
    self.provider.delegate = self.delegateMock;

    self.syncRunner = [SynchronousBlockRunner new];
    // using SynchronousBlockRunner by default to avoid async tests
    self.provider.delegateBlockRunner = self.syncRunner;

    self.playerMock = OCMProtocolMock(@protocol(RemoteMediaPlayer));
    [OCMStub([self.playerMock uniqueIdentifier]) andReturn:kTestUUID];
}

- (void)tearDown {
    self.playerMock = nil;
    self.syncRunner = nil;
    self.delegateMock = nil;
    self.discoveryControllerMock = nil;
    self.provider = nil;

    [super tearDown];
}

#pragma mark - General Instance Tests

- (void)testInstanceShouldBeCreated {
    XCTAssertNotNil(self.provider, @"Should be able to create a new instance");
}

- (void)testInstanceShouldBeASubclassOfDiscoveryProvider {
    XCTAssertTrue([self.provider isKindOfClass:[DiscoveryProvider class]]);
}

- (void)testCreatedInstanceShouldNotBeRunning {
    XCTAssertFalse(self.provider.isRunning,
                   @"Should not be running after creation");
}

- (void)testNilDiscoveryControllerShouldCreateRealDiscoveryController {
    XCTAssertNotNil([[FireTVDiscoveryProvider alloc]
                     initWithDiscoveryController:nil].flingDiscoveryController,
                     @"nil discoveryController should create a real object");
}

- (void)testInitShouldCreateRealDiscoveryController {
    XCTAssertNotNil([FireTVDiscoveryProvider new].flingDiscoveryController,
                     @"init should create a real object");
}

#pragma mark - Discovery Tests

- (void)testStartDiscoveryShouldOpenDiscoveryControllerWithDefaultAppId {
    [self.provider startDiscovery];
    OCMVerify([self.discoveryControllerMock searchDefaultPlayerWithListener:OCMOCK_ANY]);
}

- (void)testInstanceShouldBeDiscoveryControllersDelegate {
    [self.provider startDiscovery];
    OCMVerify([self.discoveryControllerMock searchDefaultPlayerWithListener:self.provider]);
}

- (void)testStartDiscoveryShouldSetRunning {
    [self.provider startDiscovery];
    XCTAssertTrue(self.provider.isRunning,
                  @"Started provider should be running");
}

- (void)testStartAndStopDiscoveryShouldCloseDiscoveryController {
    [self.provider startDiscovery];
    [self.provider stopDiscovery];
    OCMVerify([self.discoveryControllerMock close]);
}

- (void)testStartAndStopDiscoveryShouldResetRunning {
    [self.provider startDiscovery];
    [self.provider stopDiscovery];
    XCTAssertFalse(self.provider.isRunning,
                   @"Stopped provider should not be running");
}

- (void)testStopNotRunningDiscoveryShouldNotThrowException {
    XCTAssertNoThrow([self.provider stopDiscovery],
                     @"Stopping not running discovery should be fine");
}

- (void)testStartingTwiceShouldOpenDiscoveryControllerOnce {
    OCMStubWithCallCount([self.discoveryControllerMock searchDefaultPlayerWithListener:OCMOCK_ANY]);
    [self.provider startDiscovery];
    [self.provider startDiscovery];
    XCTAssertEqual(callCount, 1,
                   @"Starting running discovery should not start it again");
}

- (void)testStoppingTwiceShouldCloseDiscoveryControllerOnce {
    OCMStubWithCallCount([self.discoveryControllerMock close]);
    [self.provider startDiscovery];
    [self.provider stopDiscovery];
    [self.provider stopDiscovery];
    XCTAssertEqual(callCount, 1,
                   @"Stopping not running discovery should close it again");
}

- (void)testStopShouldRemoveAllFoundServices {
    [self.provider startDiscovery];

    id /*<RemoteMediaPlayer>*/ player2Mock = OCMProtocolMock(@protocol(RemoteMediaPlayer));
    OCMStub([player2Mock uniqueIdentifier]).andReturn(@"ID");
    [self.provider deviceDiscovered:player2Mock];
    [self.provider deviceDiscovered:self.playerMock];

    void (^expectServiceWithUUID)(NSString *) = ^(NSString *uuid) {
        OCMExpect([self.delegateMock discoveryProvider:self.provider
                                        didLoseService:[OCMArg checkWithBlock:^BOOL(ServiceDescription *desc) {
            XCTAssertEqualObjects(desc.UUID, uuid);
            return YES;
        }]]);
    };
    expectServiceWithUUID(@"ID");
    expectServiceWithUUID(kTestUUID);

    [self.provider stopDiscovery];

    OCMVerifyAll(self.delegateMock);
}

- (void)testStopShouldNotStoreRemovedServices {
    [self.provider startDiscovery];
    [self.provider deviceDiscovered:self.playerMock];

    OCMExpect([self.delegateMock discoveryProvider:self.provider
                                    didLoseService:OCMOCK_ANY]);
    [self.provider stopDiscovery];

    [[self.delegateMock reject] discoveryProvider:OCMOCK_ANY didLoseService:OCMOCK_ANY];
    [self.provider startDiscovery];
    [self.provider stopDiscovery];

    OCMVerifyAll(self.delegateMock);
}

- (void)testPauseDiscoveryShouldCloseDiscoveryController {
    [self.provider startDiscovery];
    OCMExpect([self.discoveryControllerMock close]);
    [self.provider pauseDiscovery];
    OCMVerifyAll(self.discoveryControllerMock);
}

- (void)testPauseDiscoveryShouldResetRunning {
    [self.provider startDiscovery];
    [self.provider pauseDiscovery];
    XCTAssertFalse(self.provider.isRunning,
                   @"Paused provider should not be running");
}

- (void)testPauseDiscoveryShouldNotRemoveFoundServices {
    [self.provider startDiscovery];
    [self.provider deviceDiscovered:self.playerMock];

    [[self.delegateMock reject] discoveryProvider:OCMOCK_ANY
                                   didLoseService:OCMOCK_ANY];
    [self.provider pauseDiscovery];
    OCMVerifyAll(self.delegateMock);
}

- (void)testResumeDiscoveryShouldResumeDiscoveryController {
    [self.provider startDiscovery];
    [self.provider pauseDiscovery];

    OCMExpect([self.discoveryControllerMock resume]);
    [self.provider resumeDiscovery];
    OCMVerifyAll(self.discoveryControllerMock);
}

- (void)testResumeDiscoveryShouldSetRunning {
    [self.provider startDiscovery];
    [self.provider pauseDiscovery];

    [self.provider resumeDiscovery];
    XCTAssertTrue(self.provider.isRunning,
                  @"Resumed provider should be running");
}

#pragma mark - Delegate Callback Tests

- (void)testDefaultBlockRunnerShouldBeMainQueueRunner {
    FireTVDiscoveryProvider *provider = [FireTVDiscoveryProvider new];
    XCTAssertEqualObjects(provider.delegateBlockRunner,
                          [DispatchQueueBlockRunner mainQueueRunner],
                          @"Delegate blocks should run on main queue by default");
}

- (void)testDiscoveredDeviceShouldCallDelegateDidFindService {
    [self.provider deviceDiscovered:self.playerMock];

    OCMVerify([self.delegateMock discoveryProvider:self.provider
                                    didFindService:OCMOCK_NOTNIL]);
}

- (void)testDiscoveredNilDeviceShouldNotCallDelegateDidFindService {
    [[self.delegateMock reject] discoveryProvider:OCMOCK_ANY
                                   didFindService:OCMOCK_ANY];

    [self.provider deviceDiscovered:nil];

    OCMVerifyAll(self.delegateMock);
}

- (void)testDiscoveredDeviceShouldCallDelegateDidFindServiceOnMainThread {
    /* this test is somewhat redundant, because this behavior is tested in parts
       by:
        -testDefaultBlockRunnerShouldBeMainQueueRunner;
        -testDiscoveredDeviceShouldCallDelegateDidFindService;
        DispatchQueueBlockRunnerTests.
     */
    FireTVDiscoveryProvider *provider = [[FireTVDiscoveryProvider alloc]
                                         initWithDiscoveryController:self.discoveryControllerMock];
    provider.delegate = self.delegateMock;

    XCTestExpectation *didFindServiceIsCalled = [self expectationWithDescription:
                                                 @"service is created and passed to delegate"];
    [OCMStub([self.delegateMock discoveryProvider:provider
                                   didFindService:OCMOCK_NOTNIL]) andDo:^(NSInvocation *invocation) {
        XCTAssertTrue([NSThread isMainThread],
                      @"didFindService: should be called on main thread");
        [didFindServiceIsCalled fulfill];
    }];

    dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
        [provider deviceDiscovered:self.playerMock];
    });

    WaitForExpectations();
    OCMVerify([self.delegateMock discoveryProvider:provider
                                    didFindService:OCMOCK_NOTNIL]);
}

- (void)testServiceDescriptionShouldBePopulatedFromRemoteMediaPlayer {
    id checkBlock = [OCMArg checkWithBlock:^BOOL(ServiceDescription *desc) {
        XCTAssertEqualObjects(desc.address, kTestUUID,
                              @"The address should match the player's UUID, "
                              @"because we cannot get its IP address");
        XCTAssertEqualObjects(desc.serviceId, kConnectSDKFireTVServiceId,
                              @"The service id should be FireTV's");
        XCTAssertEqualObjects(desc.UUID, kTestUUID,
                              @"The UUID doesn't match the player's");
        XCTAssertEqualObjects(desc.friendlyName, @"Player Test",
                              @"The name doesn't match the player's");
        XCTAssertEqual(desc.device, self.playerMock,
                       @"The device should be stored as is (comparing with pointers)");

        // all the rest are unknown/unset
        XCTAssertEqual(desc.port, 0, @"The port should be 0 (unknown)");
        [@[STRING_PROPERTY(type), STRING_PROPERTY(version),
          STRING_PROPERTY(manufacturer), STRING_PROPERTY(modelName),
          STRING_PROPERTY(modelDescription), STRING_PROPERTY(modelNumber),
          STRING_PROPERTY(commandURL), STRING_PROPERTY(locationXML),
          STRING_PROPERTY(serviceList), STRING_PROPERTY(locationResponseHeaders)]
         enumerateObjectsUsingBlock:^(NSString *propName, NSUInteger idx, BOOL *stop) {
              XCTAssertNil([desc valueForKey:propName], @"The %@ is missing", propName);
          }];

        return YES;
    }];
    OCMExpect([self.delegateMock discoveryProvider:self.provider
                                    didFindService:checkBlock]);

    [OCMStub([self.playerMock name]) andReturn:@"Player Test"];
    [OCMStub([self.playerMock uniqueIdentifier]) andReturn:kTestUUID];
    [self.provider deviceDiscovered:self.playerMock];

    OCMVerifyAll(self.delegateMock);
}

- (void)testDiscoveredAndLostDeviceShouldCallDelegateDidLoseService {
    [self.provider deviceDiscovered:self.playerMock];
    [self.provider deviceLost:self.playerMock];

    OCMVerify([self.delegateMock discoveryProvider:self.provider
                                    didLoseService:OCMOCK_NOTNIL]);
}

- (void)testDiscoveredAndLostDeviceShouldCallDelegateDidLoseServiceWithEqualServiceDescription {
    OCMExpect([self.delegateMock discoveryProvider:self.provider
                                    didFindService:[OCMArg checkWithBlock:^BOOL(ServiceDescription *sd) {
        ServiceDescription *foundServiceDescription = sd;
        OCMExpect([self.delegateMock discoveryProvider:self.provider
                                        didLoseService:foundServiceDescription]);
        return YES;
    }]]);

    [self.provider deviceDiscovered:self.playerMock];
    [self.provider deviceLost:self.playerMock];

    OCMVerifyAll(self.delegateMock);
}

- (void)testDiscoveredAndLostNilDeviceShouldNotCallDelegateDidLoseService {
    [[self.delegateMock reject] discoveryProvider:OCMOCK_ANY
                                   didLoseService:OCMOCK_ANY];

    [self.provider deviceDiscovered:self.playerMock];
    [self.provider deviceLost:nil];

    OCMVerifyAll(self.delegateMock);
}

- (void)testLostDeviceShouldNotCallDelegateDidLoseService {
    [[self.delegateMock reject] discoveryProvider:OCMOCK_ANY
                                   didLoseService:OCMOCK_ANY];

    [self.provider deviceLost:self.playerMock];

    OCMVerifyAll(self.delegateMock);
}

- (void)testDiscoveryFailureShouldCallDelegateDidFailWithError {
    [self.provider discoveryFailure];

    OCMVerify([self.delegateMock discoveryProvider:self.provider
                                  didFailWithError:OCMOCK_ANY]);
}

- (void)testDiscoveryFailureShouldHaveGenericError {
    OCMExpect([self.delegateMock discoveryProvider:self.provider
                                  didFailWithError:[OCMArg checkWithBlock:^BOOL(NSError *error) {
        XCTAssertEqualObjects(error.domain, ConnectErrorDomain, @"The error domain should be SDK's");
        XCTAssertEqual(error.code, ConnectStatusCodeError,
                       @"The error should be generic because we get no error in discoveryFailure");
        return YES;
    }]]);

    [self.provider discoveryFailure];

    OCMVerifyAll(self.delegateMock);
}

#pragma mark - Service-related Tests

- (void)testFireTVServiceIdShouldBeFireTV {
    XCTAssertEqualObjects(kConnectSDKFireTVServiceId, @"FireTV",
                          @"The service ID is incorrect");
}

- (void)testDefaultPlatformsShouldIncludeFireTVDiscoveryProvider {
    XCTAssertNotEqual([[kConnectSDKDefaultPlatforms allValues]
                       indexOfObject:NSStringFromClass([FireTVDiscoveryProvider class])],
                      NSNotFound,
                      @"The discovery provider should be in the default platforms");
}

@end
