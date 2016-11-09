//
//  FireTVMediaPlayerTests.m
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

#import "FireTVMediaPlayer.h"
#import "FireTVCapabilityMixin.h"
#import "FireTVMediaControl.h"
#import "FireTVService.h"
#import "SubtitleInfo.h"

#import "XCTestCase+TaskTests.h"

#import <AmazonFling/RemoteMediaPlayer.h>

typedef void(^VoidActionBlock)(void);

static NSString *const kMixedTitle = @"Hello, <World> &]]> \"others'\\ ура ξ中]]>…";

@interface FireTVMediaPlayerTests : XCTestCase

@property (strong) FireTVMediaPlayer *mediaPlayer;
@property (strong) id /*<RemoteMediaPlayer>*/ playerMock;
@property (strong) id <RemoteMediaPlayer> playerMockCast;
@property (strong) NSURL *testURL;
@property (nonatomic, strong) MediaInfo *audioInfo;
@property (nonatomic, strong) MediaInfo *imageInfo;
@property (strong) id /*FireTVService**/ serviceMock;

@end

@implementation FireTVMediaPlayerTests

#pragma mark - Setup

- (void)setUp {
    [super setUp];

    self.mediaPlayer = [FireTVMediaPlayer new];
    self.playerMock = OCMStrictProtocolMock(@protocol(RemoteMediaPlayer));
    self.playerMockCast = (id<RemoteMediaPlayer>)self.playerMock;
    FireTVCapabilityMixin *mixin = [[FireTVCapabilityMixin alloc]
                                    initWithRemoteMediaPlayer:self.playerMock];
    self.mediaPlayer.capabilityMixin = mixin;
    self.serviceMock = OCMStrictClassMock([FireTVService class]);
    self.mediaPlayer.service = self.serviceMock;

    self.testURL = [NSURL URLWithString:@"http://example.com/"];
}

- (void)tearDown {
    self.serviceMock = nil;
    self.testURL = nil;
    self.playerMock = nil;
    self.mediaPlayer = nil;

    [super tearDown];
}

#pragma mark - Lazy Properties

- (MediaInfo *)audioInfo {
    if (!_audioInfo) {
        _audioInfo = [[MediaInfo alloc] initWithURL:self.testURL
                                           mimeType:@"audio/ogg"];
        _audioInfo.title = kMixedTitle;
        _audioInfo.description = @"Description…";
        NSURL *imageURL = [NSURL URLWithString:@"http://example.com/image"];
        [_audioInfo addImage:[[ImageInfo alloc] initWithURL:imageURL
                                                       type:ImageTypeThumb]];
    }

    return _audioInfo;
}

- (MediaInfo *)imageInfo {
    if (!_imageInfo) {
        _imageInfo = [[MediaInfo alloc] initWithURL:self.testURL
                                           mimeType:@"image/png"];
        _imageInfo.title = kMixedTitle;
        _imageInfo.description = @"Description…";
        NSURL *imageURL = [NSURL URLWithString:@"http://example.com/image"];
        [_imageInfo addImage:[[ImageInfo alloc] initWithURL:imageURL
                                                       type:ImageTypeThumb]];
    }

    return _imageInfo;
}

#pragma mark - General Instance Tests

- (void)testInstanceShouldBeCreated {
    XCTAssertNotNil(self.mediaPlayer, @"Instance should be created");
}

- (void)testInstanceShouldImplementMediaPlayerProtocol {
    XCTAssertTrue([self.mediaPlayer.class conformsToProtocol:@protocol(MediaPlayer)],
                  @"Instance should be a MediaPlayer");
}

- (void)testShouldGetRemoteMediaPlayer {
    XCTAssertEqual(self.mediaPlayer.capabilityMixin.remoteMediaPlayer,
                   self.playerMock,
                   @"Should return the same remoteMediaPlayer object");
}

- (void)testShouldGetService {
    XCTAssertEqual(self.mediaPlayer.service, self.serviceMock,
                   @"Should return the same service object");
}

#pragma mark - MediaPlayer Tests

- (void)testMediaPlayerShouldReturnSelf {
    XCTAssertEqual([self.mediaPlayer mediaPlayer], self.mediaPlayer,
                   @"mediaPlayer should return itself");
}

- (void)testPriorityShouldBeHigh {
    XCTAssertEqual([self.mediaPlayer mediaPlayerPriority],
                   CapabilityPriorityLevelHigh, @"The priority should be High");
}


- (void)testDisplayImageShouldSetMediaSourceAndAutoplay {
    [self checkDisplayImageShouldSetMediaSourceAndAutoplayUsingBlock:^{
         [self.mediaPlayer displayImageWithMediaInfo:self.imageInfo
                                             success:nil
                                             failure:nil];
    }];
}

- (void)testDisplayImageWithoutImageInfoAndTitleShouldSetMediaSourceAndAutoplay {
    MediaInfo *imageInfo = [[MediaInfo alloc] initWithURL:self.imageInfo.url
                                                 mimeType:self.imageInfo.mimeType];
    NSDictionary *metadata = @{@"type": imageInfo.mimeType,
                               @"noreplay": @YES};

    [self checkMediaShouldSetMediaSourceAndAutoplayUsingBlock:^{
        [self.mediaPlayer displayImageWithMediaInfo:imageInfo
                                            success:nil
                                            failure:nil];
    }
                                           andIncludeMetadata:metadata];
}

- (void)testSetMediaSourceSuccessShouldCallDisplayImageSuccessBlock {
    [self checkSetMediaSourceSuccessShouldCallMediaSuccessUsingBlock:
     ^(SuccessBlock successVerifier, FailureBlock failureVerifier) {
         [self.mediaPlayer displayImageWithMediaInfo:self.imageInfo
                                             success:successVerifier
                                             failure:failureVerifier];
     }];
}

- (void)testSetMediaSourceErrorShouldCallDisplayImageErrorBlock {
    [self checkSetMediaSourceErrorShouldCallMediaErrorBlockUsingBlock:
     ^(SuccessBlock successVerifier, FailureBlock failureVerifier) {
         [self.mediaPlayer displayImageWithMediaInfo:self.imageInfo
                                             success:successVerifier
                                             failure:failureVerifier];
     }];
}

- (void)testSetMediaSourceSuccessShouldNotCrashDisplayImageWithNilSuccessBlock {
    BFTask *task = [BFTask taskWithResult:nil];
    OCMStub([self.serviceMock fireTVMediaControl]);
    [OCMExpect([self.playerMock setMediaSourceToURL:OCMOCK_ANY
                                           metaData:OCMOCK_ANY
                                           autoPlay:YES
                                andPlayInBackground:NO])
     andReturn:task];
    XCTAssertNoThrow([self.mediaPlayer displayImageWithMediaInfo:self.imageInfo
                                                         success:nil
                                                         failure:nil],
                     @"success nil block should be allowed");
}

- (void)testSetMediaSourceErrorShouldNotCrashDisplayImageWithNilFailureBlock {
    BFTask *task = [self errorTask];
    [OCMExpect([self.playerMock setMediaSourceToURL:OCMOCK_ANY
                                           metaData:OCMOCK_ANY
                                           autoPlay:YES
                                andPlayInBackground:NO])
     andReturn:task];
    XCTAssertNoThrow([self.mediaPlayer displayImageWithMediaInfo:self.imageInfo
                                                         success:nil
                                                         failure:nil],
                     @"failure nil block should be allowed");
}

- (void)testPlayMediaShouldSetMediaSourceAndAutoplay {
    [self checkPlayMediaShouldSetMediaSourceAndAutoplayUsingBlock:^{
        [self.mediaPlayer playMediaWithMediaInfo:self.audioInfo
                                      shouldLoop:NO
                                         success:nil
                                         failure:nil];
    }];
}

- (void)testPlayMediaWithoutImageInfoAndTitleShouldSetMediaSourceAndAutoplay {
    MediaInfo *audioInfo = [[MediaInfo alloc] initWithURL:self.audioInfo.url
                                                 mimeType:self.audioInfo.mimeType];
    NSDictionary *metadata = @{@"type": audioInfo.mimeType,
                               @"noreplay": @YES};

    [self checkMediaShouldSetMediaSourceAndAutoplayUsingBlock:^{
        [self.mediaPlayer playMediaWithMediaInfo:audioInfo
                                      shouldLoop:NO
                                         success:nil
                                         failure:nil];
    }
                                          andIncludeMetadata:metadata];
}

- (void)testSetMediaSourceSuccessShouldCallPlayMediaSuccessBlock {
    [self checkSetMediaSourceSuccessShouldCallMediaSuccessUsingBlock:
     ^(SuccessBlock successVerifier, FailureBlock failureVerifier) {
         [self.mediaPlayer playMediaWithMediaInfo:self.audioInfo
                                       shouldLoop:NO
                                          success:successVerifier
                                          failure:failureVerifier];
     }];
}

- (void)testSetMediaSourceErrorShouldCallPlayMediaErrorBlock {
    [self checkSetMediaSourceErrorShouldCallMediaErrorBlockUsingBlock:
     ^(SuccessBlock successVerifier, FailureBlock failureVerifier) {
         [self.mediaPlayer playMediaWithMediaInfo:self.audioInfo
                                       shouldLoop:NO
                                          success:successVerifier
                                          failure:failureVerifier];
     }];
}

- (void)testSetMediaSourceSuccessShouldNotCrashPlayMediaWithNilSuccessBlock {
    BFTask *task = [BFTask taskWithResult:nil];
    [OCMExpect([self.playerMock setMediaSourceToURL:OCMOCK_ANY
                                           metaData:OCMOCK_ANY
                                           autoPlay:YES
                                andPlayInBackground:NO])
     andReturn:task];
    OCMStub([self.serviceMock fireTVMediaControl]);
    XCTAssertNoThrow([self.mediaPlayer playMediaWithMediaInfo:self.audioInfo
                                                   shouldLoop:NO
                                                      success:nil
                                                      failure:nil],
                     @"success nil block should be allowed");
}

- (void)testSetMediaSourceErrorShouldNotCrashPlayMediaWithNilFailureBlock {
    BFTask *task = [self errorTask];
    [OCMExpect([self.playerMock setMediaSourceToURL:OCMOCK_ANY
                                           metaData:OCMOCK_ANY
                                           autoPlay:YES
                                andPlayInBackground:NO])
     andReturn:task];
    OCMStub([self.serviceMock fireTVMediaControl]);
    XCTAssertNoThrow([self.mediaPlayer playMediaWithMediaInfo:self.audioInfo
                                                   shouldLoop:NO
                                                      success:nil
                                                      failure:nil],
                     @"failure nil block should be allowed");
}

- (void)testCloseMediaShouldStop {
    OCMExpect([self.playerMockCast stop]);

    id sessionMock = OCMStrictClassMock([LaunchSession class]);
    [self.mediaPlayer closeMedia:sessionMock
                         success:nil
                         failure:nil];

    OCMVerifyAll(self.playerMock);
}

- (void)testStopSuccessShouldCallCloseSuccessBlock {
    id sessionMock = OCMStrictClassMock([LaunchSession class]);
    [self checkTaskSuccessOnStubRecorder:OCMExpect([self.playerMockCast stop])
        shouldCallSuccessBlockUsingBlock:^(SuccessBlock successVerifier, FailureBlock failureVerifier) {
            [self.mediaPlayer closeMedia:sessionMock
                                 success:successVerifier
                                 failure:failureVerifier];
        }];
}

- (void)testStopErrorShouldCallCloseErrorBlock {
    id sessionMock = OCMStrictClassMock([LaunchSession class]);
    [self checkTaskErrorOnStubRecorder:OCMExpect([self.playerMockCast stop])
      shouldCallFailureBlockUsingBlock:
     ^(SuccessBlock successVerifier, FailureBlock failureVerifier) {
         [self.mediaPlayer closeMedia:sessionMock
                              success:successVerifier
                              failure:failureVerifier];
     }];
}

- (void)testStopSuccessShouldNotCrashWithNilSuccessBlock {
    id sessionMock = OCMStrictClassMock([LaunchSession class]);
    BFTask *task = [BFTask taskWithResult:nil];
    [OCMExpect([self.playerMockCast stop]) andReturn:task];
    XCTAssertNoThrow([self.mediaPlayer closeMedia:sessionMock
                                          success:nil
                                          failure:nil],
                     @"success nil block should be allowed");
}

- (void)testStopErrorShouldNotCrashWithNilFailureBlock {
    id sessionMock = OCMStrictClassMock([LaunchSession class]);
    BFTask *task = [self errorTask];
    [OCMExpect([self.playerMockCast stop]) andReturn:task];
    XCTAssertNoThrow([self.mediaPlayer closeMedia:sessionMock
                                          success:nil
                                          failure:nil],
                     @"failure nil block should be allowed");
}

#pragma mark - Subtitles Support Tests

- (void)testPlayVideoWithSubtitlesRequestShouldContainOneTrack {
    [self checkPlayMediaWithSubtitles:[self mediaInfoWithSubtitle]
               metadataShouldPassTest:^(NSDictionary *metadata) {
                   NSArray *tracks = metadata[@"tracks"];
                   XCTAssertEqual(tracks.count, 1);
               }];
}

- (void)testPlayVideoWithSubtitlesRequestShouldContainTrackSrc {
    MediaInfo *mediaInfo = [self mediaInfoWithSubtitle];
    [self checkPlayMediaWithSubtitles:mediaInfo
               metadataShouldPassTest:^(NSDictionary *metadata) {
                   NSDictionary *track = [metadata[@"tracks"] firstObject];
                   XCTAssertEqualObjects(track[@"src"],
                                         mediaInfo.subtitleInfo.url.absoluteString);
               }];
}

- (void)testPlayVideoWithSubtitlesRequestTrackKindShouldBeSubtitles {
    MediaInfo *mediaInfo = [self mediaInfoWithSubtitle];
    [self checkPlayMediaWithSubtitles:mediaInfo
               metadataShouldPassTest:^(NSDictionary *metadata) {
                   NSDictionary *track = [metadata[@"tracks"] firstObject];
                   XCTAssertEqualObjects(track[@"kind"], @"subtitles");
               }];
}

- (void)testPlayVideoWithSubtitlesRequestShouldContainTrackSrcLang {
    MediaInfo *mediaInfo = [self mediaInfoWithSubtitle];
    [self checkPlayMediaWithSubtitles:mediaInfo
               metadataShouldPassTest:^(NSDictionary *metadata) {
                   NSDictionary *track = [metadata[@"tracks"] firstObject];
                   XCTAssertEqualObjects(track[@"srclang"],
                                         mediaInfo.subtitleInfo.language);
               }];
}

- (void)testPlayVideoWithSubtitlesRequestShouldContainTrackLabel {
    MediaInfo *mediaInfo = [self mediaInfoWithSubtitle];
    [self checkPlayMediaWithSubtitles:mediaInfo
               metadataShouldPassTest:^(NSDictionary *metadata) {
                   NSDictionary *track = [metadata[@"tracks"] firstObject];
                   XCTAssertEqualObjects(track[@"label"],
                                         mediaInfo.subtitleInfo.label);
               }];
}

- (void)testPlayVideoWithoutSubtitlesRequestShouldNotContainTracks {
    [self checkPlayMediaWithSubtitles:self.audioInfo
               metadataShouldPassTest:^(NSDictionary *metadata) {
                   NSArray *tracks = metadata[@"tracks"];
                   XCTAssertNil(tracks);
               }];
}

- (void)testPlayVideoWithSubtitlesWithoutLanguageRequestShouldContainEmptyTrackSrcLang {
    // because "srclang" is required
    MediaInfo *mediaInfo = [self mediaInfoWithSubtitleLanguage:nil label:@"Test"];
    [self checkPlayMediaWithSubtitles:mediaInfo
               metadataShouldPassTest:^(NSDictionary *metadata) {
                   NSDictionary *track = [metadata[@"tracks"] firstObject];
                   XCTAssertEqualObjects(track[@"srclang"], @"");
               }];
}

- (void)testPlayVideoWithSubtitlesWithoutLabelRequestShouldContainEmptyTrackLabel {
    // because "label" is required
    MediaInfo *mediaInfo = [self mediaInfoWithSubtitleLanguage:@"en" label:nil];
    [self checkPlayMediaWithSubtitles:mediaInfo
               metadataShouldPassTest:^(NSDictionary *metadata) {
                   NSDictionary *track = [metadata[@"tracks"] firstObject];
                   XCTAssertEqualObjects(track[@"label"], @"");
               }];
}

#pragma mark - MediaPlayer Deprecated Method Tests

#pragma clang diagnostic push
#pragma clang diagnostic ignored "-Wdeprecated-declarations"
- (void)testDisplayImageOldShouldSetMediaSourceAndAutoplay {
    [self checkDisplayImageShouldSetMediaSourceAndAutoplayUsingBlock:^{
         [self.mediaPlayer displayImage:self.imageInfo
                                success:nil
                                failure:nil];
     }];
}

- (void)testSetMediaSourceSuccessShouldCallDisplayImageOldSuccessBlock {
    [self checkSetMediaSourceSuccessShouldCallMediaSuccessUsingBlock:
     ^(SuccessBlock successVerifier, FailureBlock failureVerifier) {
        [self.mediaPlayer displayImage:self.imageInfo
                               success:^(LaunchSession *launchSession, id<MediaControl> mediaControl) {
                                   MediaLaunchObject *object = [[MediaLaunchObject alloc]
                                                                initWithLaunchSession:launchSession
                                                                andMediaControl:mediaControl];
                                   successVerifier(object);
                               }
                               failure:failureVerifier];
    }];
}

- (void)testSetMediaSourceErrorShouldCallDisplayImageOldErrorBlock {
    [self checkSetMediaSourceErrorShouldCallMediaErrorBlockUsingBlock:
     ^(SuccessBlock successVerifier, FailureBlock failureVerifier) {
         [self.mediaPlayer displayImage:self.imageInfo
                                success:^(LaunchSession *launchSession, id<MediaControl> mediaControl) {
                                    MediaLaunchObject *object = [[MediaLaunchObject alloc]
                                                                 initWithLaunchSession:launchSession
                                                                 andMediaControl:mediaControl];
                                    successVerifier(object);
                                }
                                failure:failureVerifier];
     }];
}

- (void)testSetMediaSourceSuccessShouldNotCrashDisplayImageOldWithNilSuccessBlock {
    BFTask *task = [BFTask taskWithResult:nil];
    [OCMExpect([self.playerMock setMediaSourceToURL:OCMOCK_ANY
                                           metaData:OCMOCK_ANY
                                           autoPlay:YES
                                andPlayInBackground:NO])
     andReturn:task];
    OCMStub([self.serviceMock fireTVMediaControl]);
    XCTAssertNoThrow([self.mediaPlayer displayImage:self.imageInfo
                                            success:nil
                                            failure:nil],
                     @"success nil block should be allowed");
}

- (void)testSetMediaSourceErrorShouldNotCrashDisplayImageOldWithNilFailureBlock {
    BFTask *task = [self errorTask];
    [OCMExpect([self.playerMock setMediaSourceToURL:OCMOCK_ANY
                                           metaData:OCMOCK_ANY
                                           autoPlay:YES
                                andPlayInBackground:NO])
     andReturn:task];
    XCTAssertNoThrow([self.mediaPlayer displayImage:self.imageInfo
                                            success:nil
                                            failure:nil],
                     @"failure nil block should be allowed");
}

- (void)testDisplayImageWithManyParametersShouldSetMediaSourceAndAutoplay {
    [self checkDisplayImageShouldSetMediaSourceAndAutoplayUsingBlock:^{
         [self.mediaPlayer displayImage:self.testURL
                                iconURL:[self.imageInfo.images[0] url]
                                  title:self.imageInfo.title
                            description:self.imageInfo.description
                               mimeType:self.imageInfo.mimeType
                                success:nil
                                failure:nil];
     }];
}

- (void)testSetMediaSourceSuccessShouldCallDisplayImageWithManyParametersSuccessBlock {
    [self checkSetMediaSourceSuccessShouldCallMediaSuccessUsingBlock:
     ^(SuccessBlock successVerifier, FailureBlock failureVerifier) {
         [self.mediaPlayer displayImage:self.testURL
                                iconURL:[self.imageInfo.images[0] url]
                                  title:self.imageInfo.title
                            description:self.imageInfo.description
                               mimeType:self.imageInfo.mimeType
                                success:^(LaunchSession *launchSession, id<MediaControl> mediaControl) {
                                    MediaLaunchObject *object = [[MediaLaunchObject alloc]
                                                                 initWithLaunchSession:launchSession
                                                                 andMediaControl:mediaControl];
                                    successVerifier(object);
                                }
                                failure:failureVerifier];
    }];
}

- (void)testSetMediaSourceErrorShouldCallDisplayImageWithManyParametersErrorBlock {
    [self checkSetMediaSourceErrorShouldCallMediaErrorBlockUsingBlock:
     ^(SuccessBlock successVerifier, FailureBlock failureVerifier) {
         [self.mediaPlayer displayImage:self.testURL
                                iconURL:[self.imageInfo.images[0] url]
                                  title:self.imageInfo.title
                            description:self.imageInfo.description
                               mimeType:self.imageInfo.mimeType
                                success:^(LaunchSession *launchSession, id<MediaControl> mediaControl) {
                                    MediaLaunchObject *object = [[MediaLaunchObject alloc]
                                                                 initWithLaunchSession:launchSession
                                                                 andMediaControl:mediaControl];
                                    successVerifier(object);
                                }
                                failure:failureVerifier];
     }];
}

- (void)testSetMediaSourceSuccessShouldNotCrashDisplayImageWithManyParametersWithNilSuccessBlock {
    BFTask *task = [BFTask taskWithResult:nil];
    [OCMExpect([self.playerMock setMediaSourceToURL:OCMOCK_ANY
                                           metaData:OCMOCK_ANY
                                           autoPlay:YES
                                andPlayInBackground:NO])
     andReturn:task];
    OCMStub([self.serviceMock fireTVMediaControl]);
    XCTAssertNoThrow([self.mediaPlayer displayImage:self.testURL
                                            iconURL:[self.imageInfo.images[0] url]
                                              title:self.imageInfo.title
                                        description:self.imageInfo.description
                                           mimeType:self.imageInfo.mimeType
                                            success:nil
                                            failure:nil],
                     @"success nil block should be allowed");
}

- (void)testSetMediaSourceErrorShouldNotCrashDisplayImageWithManyParametersWithNilFailureBlock {
    BFTask *task = [self errorTask];
    [OCMExpect([self.playerMock setMediaSourceToURL:OCMOCK_ANY
                                           metaData:OCMOCK_ANY
                                           autoPlay:YES
                                andPlayInBackground:NO])
     andReturn:task];
    XCTAssertNoThrow([self.mediaPlayer displayImage:self.testURL
                                            iconURL:[self.imageInfo.images[0] url]
                                              title:self.imageInfo.title
                                        description:self.imageInfo.description
                                           mimeType:self.imageInfo.mimeType
                                            success:nil
                                            failure:nil],
                     @"failure nil block should be allowed");
}

- (void)testPlayMediaOldShouldSetMediaSourceAndAutoplay {
    [self checkPlayMediaShouldSetMediaSourceAndAutoplayUsingBlock:^{
        [self.mediaPlayer playMedia:self.audioInfo
                         shouldLoop:NO
                            success:nil
                            failure:nil];
    }];
}

- (void)testSetMediaSourceSuccessShouldCallPlayMediaOldSuccessBlock {
    [self checkSetMediaSourceSuccessShouldCallMediaSuccessUsingBlock:
     ^(SuccessBlock successVerifier, FailureBlock failureVerifier) {
        [self.mediaPlayer playMedia:self.audioInfo
                         shouldLoop:NO
                            success:^(LaunchSession *launchSession, id<MediaControl> mediaControl) {
                                MediaLaunchObject *object = [[MediaLaunchObject alloc]
                                                             initWithLaunchSession:launchSession
                                                             andMediaControl:mediaControl];
                                successVerifier(object);
                            }
                            failure:failureVerifier];
    }];
}

- (void)testSetMediaSourceErrorShouldCallPlayMediaOldErrorBlock {
    [self checkSetMediaSourceErrorShouldCallMediaErrorBlockUsingBlock:
     ^(SuccessBlock successVerifier, FailureBlock failureVerifier) {
         [self.mediaPlayer playMedia:self.audioInfo
                          shouldLoop:NO
                             success:^(LaunchSession *launchSession, id<MediaControl> mediaControl) {
                                MediaLaunchObject *object = [[MediaLaunchObject alloc]
                                                             initWithLaunchSession:launchSession
                                                             andMediaControl:mediaControl];
                                successVerifier(object);
                             }
                             failure:failureVerifier];
     }];
}

- (void)testSetMediaSourceSuccessShouldNotCrashPlayMediaOldWithNilSuccessBlock {
    BFTask *task = [BFTask taskWithResult:nil];
    [OCMExpect([self.playerMock setMediaSourceToURL:OCMOCK_ANY
                                           metaData:OCMOCK_ANY
                                           autoPlay:YES
                                andPlayInBackground:NO])
     andReturn:task];
    OCMStub([self.serviceMock fireTVMediaControl]);
    XCTAssertNoThrow([self.mediaPlayer playMedia:self.audioInfo
                                      shouldLoop:NO
                                         success:nil
                                         failure:nil],
                     @"success nil block should be allowed");
}

- (void)testSetMediaSourceErrorShouldNotCrashPlayMediaOldWithNilFailureBlock {
    BFTask *task = [self errorTask];
    [OCMExpect([self.playerMock setMediaSourceToURL:OCMOCK_ANY
                                           metaData:OCMOCK_ANY
                                           autoPlay:YES
                                andPlayInBackground:NO])
     andReturn:task];
    XCTAssertNoThrow([self.mediaPlayer playMedia:self.audioInfo
                                      shouldLoop:NO
                                         success:nil
                                         failure:nil],
                     @"failure nil block should be allowed");
}

- (void)testPlayMediaWithManyParametersShouldSetMediaSourceAndAutoplay {
    [self checkPlayMediaShouldSetMediaSourceAndAutoplayUsingBlock:^{
        [self.mediaPlayer playMedia:self.testURL
                            iconURL:[self.audioInfo.images[0] url]
                              title:self.audioInfo.title
                        description:self.audioInfo.description
                           mimeType:self.audioInfo.mimeType
                         shouldLoop:NO
                            success:nil
                            failure:nil];
    }];
}

- (void)testSetMediaSourceSuccessShouldCallPlayMediaWithManyParametersSuccessBlock {
    [self checkSetMediaSourceSuccessShouldCallMediaSuccessUsingBlock:
     ^(SuccessBlock successVerifier, FailureBlock failureVerifier) {
         [self.mediaPlayer playMedia:self.testURL
                             iconURL:[self.audioInfo.images[0] url]
                               title:self.audioInfo.title
                         description:self.audioInfo.description
                            mimeType:self.audioInfo.mimeType
                          shouldLoop:NO
                             success:^(LaunchSession *launchSession, id<MediaControl> mediaControl) {
                                 MediaLaunchObject *object = [[MediaLaunchObject alloc]
                                                              initWithLaunchSession:launchSession
                                                              andMediaControl:mediaControl];
                                 successVerifier(object);
                             }
                             failure:failureVerifier];
     }];
}

- (void)testSetMediaSourceErrorShouldCallPlayMediaWithManyParametersErrorBlock {
    [self checkSetMediaSourceErrorShouldCallMediaErrorBlockUsingBlock:
     ^(SuccessBlock successVerifier, FailureBlock failureVerifier) {
         [self.mediaPlayer playMedia:self.testURL
                             iconURL:[self.audioInfo.images[0] url]
                               title:self.audioInfo.title
                         description:self.audioInfo.description
                            mimeType:self.audioInfo.mimeType
                          shouldLoop:NO
                             success:^(LaunchSession *launchSession, id<MediaControl> mediaControl) {
                                 MediaLaunchObject *object = [[MediaLaunchObject alloc]
                                                              initWithLaunchSession:launchSession
                                                              andMediaControl:mediaControl];
                                 successVerifier(object);
                             }
                             failure:failureVerifier];
     }];
}

- (void)testSetMediaSourceSuccessShouldNotCrashPlayMediaWithManyParametersWithNilSuccessBlock {
    BFTask *task = [BFTask taskWithResult:nil];
    [OCMExpect([self.playerMock setMediaSourceToURL:OCMOCK_ANY
                                           metaData:OCMOCK_ANY
                                           autoPlay:YES
                                andPlayInBackground:NO])
     andReturn:task];
    OCMStub([self.serviceMock fireTVMediaControl]);
    XCTAssertNoThrow([self.mediaPlayer playMedia:self.testURL
                                         iconURL:[self.audioInfo.images[0] url]
                                           title:self.audioInfo.title
                                     description:self.audioInfo.description
                                        mimeType:self.audioInfo.mimeType
                                      shouldLoop:NO
                                         success:nil
                                         failure:nil],
                     @"success nil block should be allowed");
}

- (void)testSetMediaSourceErrorShouldNotCrashPlayMediaWithManyParametersWithNilFailureBlock {
    BFTask *task = [self errorTask];
    [OCMExpect([self.playerMock setMediaSourceToURL:OCMOCK_ANY
                                           metaData:OCMOCK_ANY
                                           autoPlay:YES
                                andPlayInBackground:NO])
     andReturn:task];
    XCTAssertNoThrow([self.mediaPlayer playMedia:self.testURL
                                         iconURL:[self.audioInfo.images[0] url]
                                           title:self.audioInfo.title
                                     description:self.audioInfo.description
                                        mimeType:self.audioInfo.mimeType
                                      shouldLoop:NO
                                         success:nil
                                         failure:nil],
                     @"failure nil block should be allowed");
}
#pragma clang diagnostic pop

#pragma mark - Helpers

- (void)checkDisplayImageShouldSetMediaSourceAndAutoplayUsingBlock:(VoidActionBlock)block {
    // from self.imageInfo
    NSDictionary *metadata = @{@"type": @"image/png",
                               @"title": kMixedTitle,
                               @"description": @"Description…",
                               @"poster": @"http://example.com/image",
                               @"noreplay": @YES};
    [self checkMediaShouldSetMediaSourceAndAutoplayUsingBlock:block
                                           andIncludeMetadata:metadata];
}

- (void)checkPlayMediaShouldSetMediaSourceAndAutoplayUsingBlock:(VoidActionBlock)block {
    // from self.audioInfo
    NSDictionary *metadata = @{@"type": @"audio/ogg",
                               @"title": kMixedTitle,
                               @"description": @"Description…",
                               @"poster": @"http://example.com/image",
                               @"noreplay": @YES};
    [self checkMediaShouldSetMediaSourceAndAutoplayUsingBlock:block
                                           andIncludeMetadata:metadata];
}

- (void)checkMediaShouldSetMediaSourceAndAutoplayUsingBlock:(VoidActionBlock)block
                                         andIncludeMetadata:(NSDictionary *)expectedMetadata {
    [self checkMediaShouldSetMediaSourceAndAutoplayUsingBlock:block
                                 andMetadataVerificationBlock:^(NSDictionary *metadata) {
                                     [self assertDictionary:metadata
                                         isASubdictionaryOf:expectedMetadata];
                                 }];
}

- (void)checkMediaShouldSetMediaSourceAndAutoplayUsingBlock:(VoidActionBlock)block
                               andMetadataVerificationBlock:(void (^)(NSDictionary *metadata))checkBlock {
    BOOL(^metadataCheckBlock)(NSString *json) = ^(NSString *json) {
        NSData *data = [json dataUsingEncoding:NSUTF8StringEncoding];
        NSDictionary *metadata = [NSJSONSerialization JSONObjectWithData:data
                                                                 options:0
                                                                   error:nil];
        checkBlock(metadata);

        return YES;
    };

    OCMExpect([self.playerMock setMediaSourceToURL:self.testURL.absoluteString
                                          metaData:[OCMArg checkWithBlock:metadataCheckBlock]
                                          autoPlay:YES
                               andPlayInBackground:NO]);

    block();

    OCMVerifyAll(self.playerMock);
}

- (void)checkSetMediaSourceSuccessShouldCallMediaSuccessUsingBlock:(ActionBlock)block {
    id mediaControlMock = OCMStrictClassMock([FireTVMediaControl class]);
    [OCMExpect([self.serviceMock fireTVMediaControl]) andReturn:mediaControlMock];

    [self checkTaskSuccessOnStubRecorder:OCMExpect([self.playerMock setMediaSourceToURL:OCMOCK_ANY
                                                                               metaData:OCMOCK_ANY
                                                                               autoPlay:YES
                                                                    andPlayInBackground:NO])
        shouldCallSuccessBlockUsingBlock:
     ^(SuccessBlock successVerifier, FailureBlock failureVerifier) {
         void(^successBlock)() = ^(MediaLaunchObject *object) {
             XCTAssertNotNil(object,
                             @"MediaLaunchObject should be returned on success");
             XCTAssertEqual(object.mediaControl, mediaControlMock,
                            @"mediaControl should be retrieved from FireTVService");
             XCTAssertNil(object.playListControl, @"playListControl is unavailable");

             LaunchSession *session = object.session;
             XCTAssertEqual(session.sessionType, LaunchSessionTypeMedia,
                            @"session type should be Media");
             XCTAssertEqual(session.service, self.serviceMock,
                            @"service should be returned");

             successVerifier(nil);
         };
         block(successBlock, failureVerifier);
     }];
}

- (void)checkSetMediaSourceErrorShouldCallMediaErrorBlockUsingBlock:(ActionBlock)block {
    [self checkTaskErrorOnStubRecorder:OCMExpect([self.playerMock setMediaSourceToURL:OCMOCK_ANY
                                                                             metaData:OCMOCK_ANY
                                                                             autoPlay:YES
                                                                  andPlayInBackground:NO])
      shouldCallFailureBlockUsingBlock:block];
}

#pragma mark - Subtitle Helpers

- (void)checkPlayMediaWithSubtitles:(MediaInfo *)mediaInfo
             metadataShouldPassTest:(void (^)(NSDictionary *metadata))checkBlock {
    [self checkMediaShouldSetMediaSourceUsingBlock:^{
            [self.mediaPlayer playMediaWithMediaInfo:mediaInfo
                                          shouldLoop:NO
                                             success:nil
                                             failure:nil];
        }
                      andMetadataVerificationBlock:checkBlock];
}

- (void)checkMediaShouldSetMediaSourceUsingBlock:(VoidActionBlock)block
                    andMetadataVerificationBlock:(void (^)(NSDictionary *metadata))checkBlock {
    BOOL(^metadataCheckBlock)(NSString *json) = ^(NSString *json) {
        NSData *data = [json dataUsingEncoding:NSUTF8StringEncoding];
        NSDictionary *metadata = [NSJSONSerialization JSONObjectWithData:data
                                                                 options:0
                                                                   error:nil];
        checkBlock(metadata);

        return YES;
    };

    [OCMExpect([self.playerMock setMediaSourceToURL:OCMOCK_ANY
                                           metaData:[OCMArg checkWithBlock:metadataCheckBlock]
                                           autoPlay:YES
                                andPlayInBackground:NO]) ignoringNonObjectArgs];

    block();

    OCMVerifyAll(self.playerMock);
}

- (MediaInfo *)mediaInfoWithSubtitle {
    return [self mediaInfoWithSubtitleLanguage:@"en" label:@"Test"];
}

- (MediaInfo *)mediaInfoWithSubtitleLanguage:(NSString *)language
                                       label:(NSString *)label {
    NSURL *subtitleURL = [NSURL URLWithString:@"http://example.com/"];
    MediaInfo *mediaInfo = self.audioInfo;
    SubtitleInfo *subtitleInfo = [SubtitleInfo infoWithURL:subtitleURL
                                                  andBlock:^(SubtitleInfoBuilder *builder) {
                                                      builder.language = language;
                                                      builder.label = label;
                                                  }];
    mediaInfo.subtitleInfo = subtitleInfo;

    return mediaInfo;
}

#pragma mark - Custom Asserts

- (void)assertDictionary:(NSDictionary *)dictionary
      isASubdictionaryOf:(NSDictionary *)subdictionary {
    NSArray *subkeys = subdictionary.allKeys;
    NSMutableDictionary *actualSubdictionary = [NSMutableDictionary new];
    [dictionary enumerateKeysAndObjectsUsingBlock:^(id key, id obj, BOOL *stop) {
        if ([subkeys containsObject:key]) {
            actualSubdictionary[key] = obj;
        }
    }];
    XCTAssertEqualObjects(subdictionary, actualSubdictionary);
}

@end
