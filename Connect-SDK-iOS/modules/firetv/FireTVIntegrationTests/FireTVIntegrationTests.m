//
//  FireTVIntegrationTests.m
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

#import "DiscoveryManager_Private.h"
#import "FireTVDiscoveryProvider_Private.h"
#import "FireTVService.h"

static inline void runAfter(CGFloat seconds, dispatch_block_t block) {
    dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(seconds * NSEC_PER_SEC)),
                   dispatch_get_main_queue(),
                   block);
}

SpecBegin(FireTVIntegration)

describe(@"FireTVService", ^{
    __block DiscoveryManager *discoveryManager;
    __block id /*<DiscoveryManagerDelegate>*/ discoveryManagerDelegateStub;

    __block id /*DiscoveryController*/ discoveryControllerMock;
    __block id<DiscoveryListener> discoveryListener;

    __block ConnectableDevice *fireTV;
    __block id /*<RemoteMediaPlayer>*/ remoteMediaPlayerMock;

    beforeEach(^{
        discoveryManager = [DiscoveryManager new];
        discoveryManager.deviceStore = nil;

        discoveryManagerDelegateStub = OCMProtocolMock(@protocol(DiscoveryManagerDelegate));
        discoveryManager.delegate = discoveryManagerDelegateStub;

        remoteMediaPlayerMock = OCMProtocolMock(@protocol(RemoteMediaPlayer));
        OCMStub([remoteMediaPlayerMock name]).andReturn(@"Test");
        OCMStub([remoteMediaPlayerMock uniqueIdentifier]).andReturn(@"42");

        discoveryControllerMock = OCMClassMock([DiscoveryController class]);
        OCMExpect([discoveryControllerMock searchDefaultPlayerWithListener:
                   [OCMArg checkWithBlock:^BOOL(id<DiscoveryListener> listener) {
            discoveryListener = listener;
            runAfter(0.25, ^{
                [listener deviceDiscovered:remoteMediaPlayerMock];
            });
            return YES;
        }]]);

        [discoveryManager registerDeviceService:[FireTVService class]
                   withDiscoveryProviderFactory:^DiscoveryProvider *{
                       return [[FireTVDiscoveryProvider alloc]
                               initWithDiscoveryController:discoveryControllerMock];
                   }];

        waitUntil(^(DoneCallback done) {
            OCMStub([discoveryManagerDelegateStub discoveryManager:discoveryManager
                                                     didFindDevice:
                     [OCMArg checkWithBlock:^BOOL(ConnectableDevice *device) {
                fireTV = device;

                done();
                return YES;
            }]]);

            [discoveryManager startDiscovery];
        });

        expect(fireTV).notTo.beNil();
    });

    it(@"should be removed when DiscoveryManager is stopped", ^{
        waitUntil(^(DoneCallback done) {
            [OCMExpect([discoveryManagerDelegateStub discoveryManager:discoveryManager
                                                        didLoseDevice:fireTV]) andDo:^(NSInvocation *_) {
                done();
            }];

            [discoveryManager stopDiscovery];
        });
    });

    it(@"should use new remoteMediaPlayer after resuming", ^{
        /*
         DiscoveryManager registers FireTVDiscoveryProvider and starts it
         RemoteMediaPlayer is found and assigned to FireTVService
         App suspends => [DiscoveryController close] is expected
         App resumes => [DiscoveryController resume] is expected
         New RemoteMediaPlayer with the same UUID is discovered and assigned to the same FireTVService
         [MediaPlayer playMedia…] => [newRemoteMediaPlayer setMedia:…] is expected
         */
        FailureBlock testFailBlock = ^(NSError *error) {
            failure([NSString stringWithFormat:@"should not happen: %@", error]);
        };

        // eagerly initialize the mediaPlayer to make sure it will use a new
        // RemoteMediaPlayer after resuming
        id<MediaPlayer> mediaPlayer = [fireTV mediaPlayer];

        // emulate background and foreground states
        NSNotificationCenter *center = [NSNotificationCenter defaultCenter];
        UIApplication *app = [UIApplication sharedApplication];
        [center postNotificationName:UIApplicationDidEnterBackgroundNotification object:app];

        id remoteMediaPlayerMock2 = OCMProtocolMock(@protocol(RemoteMediaPlayer));
        waitUntil(^(DoneCallback done) {
            runAfter(1, ^{
                OCMStub([remoteMediaPlayerMock2 name]).andReturn([remoteMediaPlayerMock name]);
                OCMStub([remoteMediaPlayerMock2 uniqueIdentifier]).andReturn([remoteMediaPlayerMock uniqueIdentifier]);
                [[discoveryControllerMock reject] searchDefaultPlayerWithListener:OCMOCK_ANY];
                [OCMExpect([discoveryControllerMock resume]) andDo:^(NSInvocation *_) {
                    runAfter(0.25, ^{
                        [discoveryListener deviceDiscovered:remoteMediaPlayerMock2];
                    });
                }];

                [center postNotificationName:UIApplicationDidBecomeActiveNotification object:app];

                runAfter(1, ^{
                    expect([fireTV mediaPlayer]).beIdenticalTo(mediaPlayer);

                    NSURL *url = [NSURL URLWithString:@"http://127.1/"];
                    MediaInfo *mediaInfo = [[MediaInfo alloc] initWithURL:url
                                                                 mimeType:@"audio/mp3"];
                    [[[remoteMediaPlayerMock reject] ignoringNonObjectArgs] setMediaSourceToURL:OCMOCK_ANY
                                                                                       metaData:OCMOCK_ANY
                                                                                       autoPlay:NO
                                                                            andPlayInBackground:NO];
                    BFTask *task = [BFTask taskWithResult:nil];
                    [[OCMExpect([remoteMediaPlayerMock2 setMediaSourceToURL:@"http://127.1/"
                                                                   metaData:OCMOCK_NOTNIL
                                                                   autoPlay:NO
                                                        andPlayInBackground:NO]) ignoringNonObjectArgs] andReturn:task];
                    [[fireTV mediaPlayer] playMediaWithMediaInfo:mediaInfo
                                                      shouldLoop:NO
                                                         success:
                     ^(MediaLaunchObject *mediaLaunchObject) {
                         done();
                     }
                                                         failure:testFailBlock];
                });
            });
        });

        OCMVerifyAll(discoveryControllerMock);
        OCMVerifyAll(remoteMediaPlayerMock);
        OCMVerifyAll(remoteMediaPlayerMock2);
    });
});

SpecEnd
