//
//  FireTVAcceptanceTests.m
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

#import "DiscoveryManager.h"
#import "FireTVDiscoveryProvider.h"
#import "FireTVService.h"

#import "OCMArg+ArgumentCaptor.h"
#import "OCMStubRecorder+SpectaAsync.h"

#pragma mark - Environment-specific constants

static NSString *const kExpectedFireTVName = @"Connect's Fire TV";

static NSString *const kAudioURL = @"http://ec2-54-201-108-205.us-west-2.compute.amazonaws.com/samples/media/symphony.mp3";
static NSString *const kAlbumArtURL = @"http://ec2-54-201-108-205.us-west-2.compute.amazonaws.com/samples/media/earth-our-home2.jpg";

#pragma mark -

static inline void runAfter(CGFloat seconds, dispatch_block_t block) {
    dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(seconds * NSEC_PER_SEC)),
                   dispatch_get_main_queue(),
                   block);
}

SpecBegin(FireTVAcceptance)

describe(@"ConnectSDK", ^{
    __block DiscoveryManager *manager;
    __block ConnectableDevice *fireTV;

    beforeAll(^{
        manager = [DiscoveryManager new];
        manager.deviceStore = nil;

        id delegateStub = OCMProtocolMock(@protocol(DiscoveryManagerDelegate));
        manager.delegate = delegateStub;

        [manager registerDeviceService:[FireTVService class]
                         withDiscovery:[FireTVDiscoveryProvider class]];

        /* unfortunately, only the first created Fling SDK's DiscoveryController
         object is able to discover devices, so we'll have to discover it once
         and keep between tests */
        waitUntil(^(DoneCallback done) {
            OCMStub([delegateStub discoveryManager:manager
                                     didFindDevice:
                     [OCMArg checkWithBlock:^BOOL(ConnectableDevice *device) {
                expect([NSThread isMainThread]).to.beTruthy();
                fireTV = device;

                done();
                return YES;
            }]]);

            [manager startDiscovery];
        });

        delegateStub = nil;
    });

    it(@"should discover FireTV device in the network", ^{
        expect(fireTV.friendlyName).equal(kExpectedFireTVName);
        expect(fireTV.id).notTo.beNil();
        expect(fireTV.address).notTo.beNil();

        expect([fireTV serviceWithName:kConnectSDKFireTVServiceId]).notTo.beNil();
    });

    context(@"after FireTV device is connected", ^{
        __block const FailureBlock testFailBlock = ^(NSError *error) {
                failure([NSString stringWithFormat:@"should not happen: %@",
                         error]);
            };
        /// Subscription used within a test, if any.
        __block ServiceSubscription *subscription;

        static const NSTimeInterval kDefaultAsyncSpecTimeout = 10.0;
        static const NSTimeInterval kDefaultCallbackWaitTime = 3.0;
        static const NSTimeInterval kPreCloseTime = 0.5 * NSEC_PER_SEC;

        beforeAll(^{
            expect(fireTV).notTo.beNil();

            id deviceDelegate = OCMProtocolMock(@protocol(ConnectableDeviceDelegate));
            fireTV.delegate = deviceDelegate;
            waitUntil(^(DoneCallback done) {
                [OCMStub([deviceDelegate connectableDeviceReady:fireTV]) andDoneWaiting:done];
                [fireTV connect];
            });
        });

        beforeEach(^{
            // this timeout is global, so one test's timeout impacts others
            // we reset it here
            setAsyncSpecTimeout(kDefaultAsyncSpecTimeout);
        });

        it(@"should get play state after subscription", ^{
            setAsyncSpecTimeout(kDefaultCallbackWaitTime);
            waitUntil(^(DoneCallback done) {
                subscription = [[fireTV mediaControl]
                                subscribePlayStateWithSuccess:^(MediaControlPlayState playState) {
                                    expect([NSThread isMainThread]).beTruthy();

                                    done();
                                }
                                failure:testFailBlock];
            });

        });

        it(@"should set and get video metadata", ^{
            NSURL *url = [NSURL URLWithString:kAudioURL];
            MediaInfo *mediaInfo = [[MediaInfo alloc] initWithURL:url
                                                         mimeType:@"audio/mp3"];
            mediaInfo.title = @"Hello, <World> &]]> \"others'\\ ура ξ中]]>…";
            mediaInfo.description = @"Something else…";
            NSURL *albumArtURL = [NSURL URLWithString:kAlbumArtURL];
            ImageInfo *imageInfo = [[ImageInfo alloc] initWithURL:albumArtURL
                                                             type:ImageTypeAlbumArt];
            [mediaInfo addImage:imageInfo];

            waitUntil(^(DoneCallback done) {
                [[fireTV mediaPlayer] playMediaWithMediaInfo:mediaInfo
                                                  shouldLoop:NO
                                                     success:
                 ^(MediaLaunchObject *mediaLaunchObject) {
                     [mediaLaunchObject.mediaControl getMediaMetaDataWithSuccess:^(id responseObject) {
                         expect(responseObject).
                         equal(@{@"title": @"Hello, <World> &]]> \"others'\\ ура ξ中]]>…",
                                 @"subtitle": @"Something else…",
                                 @"iconURL": kAlbumArtURL});

                         // the player doesn't have time to handle close
                         // sometimes, so we're waiting for a while
                         dispatch_after(dispatch_time(DISPATCH_TIME_NOW, kPreCloseTime),
                                        dispatch_get_main_queue(),
                                        ^{
                                            [mediaLaunchObject.mediaControl stopWithSuccess:^(id responseObject) {
                                                done();
                                            }
                                                                                    failure:testFailBlock];
                                        });
                     }
                                                                         failure:testFailBlock];
                 }
                                                     failure:testFailBlock];
            });
        });

        it(@"should display photo", ^{
            NSURL *url = [NSURL URLWithString:kAlbumArtURL];
            MediaInfo *mediaInfo = [[MediaInfo alloc] initWithURL:url
                                                         mimeType:@"image/jpg"];
            mediaInfo.title = @"Test Image";
            mediaInfo.description = @"Description";
            ImageInfo *imageInfo = [[ImageInfo alloc] initWithURL:url
                                                             type:ImageTypeAlbumArt];
            [mediaInfo addImage:imageInfo];

            waitUntil(^(DoneCallback done) {
                [[fireTV mediaPlayer] displayImageWithMediaInfo:mediaInfo
                                                        success:
                 ^(MediaLaunchObject *mediaLaunchObject) {
                     dispatch_after(dispatch_time(DISPATCH_TIME_NOW, kPreCloseTime),
                                    dispatch_get_main_queue(),
                                    ^{
                                        [mediaLaunchObject.mediaControl stopWithSuccess:^(id responseObject) {
                                            done();
                                        }
                                                                                failure:testFailBlock];
                                    });
                 }
                                                        failure:testFailBlock];
            });
        });

        it(@"should get play state notifications", ^{
            waitUntil(^(DoneCallback done) {
                NSURL *url = [NSURL URLWithString:kAudioURL];
                MediaInfo *mediaInfo = [[MediaInfo alloc] initWithURL:url
                                                             mimeType:@"audio/mp3"];
                [[fireTV mediaPlayer] playMediaWithMediaInfo:mediaInfo
                                                  shouldLoop:NO
                                                     success:
                 ^(MediaLaunchObject *mediaLaunchObject) {
                     subscription = [mediaLaunchObject.mediaControl
                                     subscribePlayStateWithSuccess:^(MediaControlPlayState playState) {
                                         if (MediaControlPlayStatePlaying == playState) {
                                             done();
                                         }
                                     }
                                     failure:testFailBlock];
                 }
                                                     failure:testFailBlock];
            });

            waitUntil(^(DoneCallback done) {
                [[fireTV mediaControl] stopWithSuccess:^(id responseObject) {
                    done();
                }
                                               failure:testFailBlock];
            });
        });

        it(@"should get play state notifications after foregrounding", ^{
            NSNotificationCenter *center = [NSNotificationCenter defaultCenter];
            UIApplication *app = [UIApplication sharedApplication];
            [center postNotificationName:UIApplicationDidEnterBackgroundNotification object:app];

            setAsyncSpecTimeout(kDefaultAsyncSpecTimeout + 5);
            waitUntil(^(DoneCallback done) {
                runAfter(2, ^{
                    [center postNotificationName:UIApplicationDidBecomeActiveNotification object:app];

                    runAfter(2, ^{
                        NSURL *url = [NSURL URLWithString:kAudioURL];
                        MediaInfo *mediaInfo = [[MediaInfo alloc] initWithURL:url
                                                                     mimeType:@"audio/mp3"];
                        [[fireTV mediaPlayer] playMediaWithMediaInfo:mediaInfo
                                                          shouldLoop:NO
                                                             success:
                         ^(MediaLaunchObject *mediaLaunchObject) {
                             subscription = [mediaLaunchObject.mediaControl subscribePlayStateWithSuccess:^(MediaControlPlayState playState) {
                                 if (MediaControlPlayStatePlaying == playState) {
                                     done();
                                 }
                             }
                                                                                         failure:testFailBlock];
                                                             }
                                                             failure:testFailBlock];
                    });
                });
            });

            waitUntil(^(DoneCallback done) {
                [[fireTV mediaControl] stopWithSuccess:^(id responseObject) {
                    done();
                }
                                               failure:testFailBlock];
            });
        });

        pending(@"should still get play state notifications after foregrounding", ^{
            // unfortunately, this test doesn't work; most likely, because real
            // suspending terminates network connections, which we cannot do
            // programmatically in tests

            waitUntil(^(DoneCallback done) {
                subscription = [[fireTV mediaControl] subscribePlayStateWithSuccess:^(MediaControlPlayState playState) {
                    if (MediaControlPlayStatePlaying == playState) {
                        done();
                    }
                }
                                                                            failure:testFailBlock];

                NSNotificationCenter *center = [NSNotificationCenter defaultCenter];
                UIApplication *app = [UIApplication sharedApplication];
                [center postNotificationName:UIApplicationDidEnterBackgroundNotification object:app];

                runAfter(2, ^{
                    [center postNotificationName:UIApplicationDidBecomeActiveNotification object:app];

                    runAfter(2, ^{
                        expect(subscription.isSubscribed).beTruthy();

                        NSURL *url = [NSURL URLWithString:kAudioURL];
                        MediaInfo *mediaInfo = [[MediaInfo alloc] initWithURL:url
                                                                     mimeType:@"audio/mp3"];
                        [[fireTV mediaPlayer] playMediaWithMediaInfo:mediaInfo
                                                          shouldLoop:NO
                                                             success:nil
                                                             failure:testFailBlock];
                    });
                });
            });

            waitUntil(^(DoneCallback done) {
                [[fireTV mediaControl] stopWithSuccess:^(id responseObject) {
                    done();
                }
                                               failure:testFailBlock];
            });
        });

        afterEach(^{
            [subscription unsubscribe];
            subscription = nil;

            // adds a small delay between tests, getting them more reliable when
            // using real Fling SDK and FireTV device
            [[NSRunLoop mainRunLoop] runUntilDate:[NSDate dateWithTimeIntervalSinceNow:3.0]];
        });

        afterAll(^{
            [fireTV disconnect];
            fireTV = nil;
        });
    });

    afterAll(^{
        /* FireTV subscriptions don't work if we stop discovery before, so
         stopping it here at the end */
        [manager stopDiscovery];
        manager = nil;
    });
});

SpecEnd
