//
//  CastService.m
//  Connect SDK
//
//  Created by Jeremy White on 2/7/14.
//  Copyright (c) 2014 LG Electronics.
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

#import "CastService_Private.h"

#import "ConnectError.h"
#import "CastWebAppSession.h"
#import "SubtitleInfo.h"

#import "NSObject+FeatureNotSupported_Private.h"
#import "NSMutableDictionary+NilSafe.h"

#define kCastServiceMuteSubscriptionName @"mute"
#define kCastServiceVolumeSubscriptionName @"volume"

static const NSInteger kSubtitleTrackIdentifier = 42;

static NSString *const kSubtitleTrackDefaultLanguage = @"en";

@interface CastService () <ServiceCommandDelegate, GCKMediaControlChannelDelegate>

@property (nonatomic, strong) MediaPlayStateSuccessBlock immediatePlayStateCallback;
@property (nonatomic, strong) ServiceSubscription *playStateSubscription;
@property (nonatomic, strong) ServiceSubscription *mediaInfoSubscription;

@end

@implementation CastService
{
    int UID;

    NSString *_currentAppId;
    NSString *_launchingAppId;

    NSMutableDictionary *_launchSuccessBlocks;
    NSMutableDictionary *_launchFailureBlocks;

    NSMutableDictionary *_sessions; // TODO: are we using this? get rid of it if not
    NSMutableArray *_subscriptions;

    float _currentVolumeLevel;
    BOOL _currentMuteStatus;
}

- (void) commonSetup
{
    _launchSuccessBlocks = [NSMutableDictionary new];
    _launchFailureBlocks = [NSMutableDictionary new];

    _sessions = [NSMutableDictionary new];
    _subscriptions = [NSMutableArray new];

    UID = 0;
}

- (instancetype) init
{
    self = [super init];

    if (self)
        [self commonSetup];

    return self;
}

- (instancetype)initWithServiceConfig:(ServiceConfig *)serviceConfig
{
    self = [super initWithServiceConfig:serviceConfig];

    if (self)
        [self commonSetup];

    return self;
}

+ (NSDictionary *) discoveryParameters
{
    return @{
             @"serviceId":kConnectSDKCastServiceId
             };
}

- (BOOL)isConnectable
{
    return YES;
}

- (void) updateCapabilities
{
    NSArray *capabilities = [NSArray new];

    capabilities = [capabilities arrayByAddingObjectsFromArray:kMediaPlayerCapabilities];
    capabilities = [capabilities arrayByAddingObjectsFromArray:kVolumeControlCapabilities];
    capabilities = [capabilities arrayByAddingObjectsFromArray:@[
            kMediaPlayerSubtitleWebVTT,

            kMediaControlPlay,
            kMediaControlPause,
            kMediaControlStop,
            kMediaControlDuration,
            kMediaControlSeek,
            kMediaControlPosition,
            kMediaControlPlayState,
            kMediaControlPlayStateSubscribe,
            kMediaControlMetadata,
            kMediaControlMetadataSubscribe,

            kWebAppLauncherLaunch,
            kWebAppLauncherMessageSend,
            kWebAppLauncherMessageReceive,
            kWebAppLauncherMessageSendJSON,
            kWebAppLauncherMessageReceiveJSON,
            kWebAppLauncherConnect,
            kWebAppLauncherDisconnect,
            kWebAppLauncherJoin,
            kWebAppLauncherClose
    ]];

    [self setCapabilities:capabilities];
}

-(NSString *)castWebAppId
{
    if(_castWebAppId == nil){
        _castWebAppId = kGCKMediaDefaultReceiverApplicationID;
    }
    return _castWebAppId;
}

#pragma mark - Connection

- (void)connect
{
    if (self.connected)
        return;

    if (!_castDevice)
    {
        UInt32 devicePort = (UInt32) self.serviceDescription.port;
        _castDevice = [[GCKDevice alloc] initWithIPAddress:self.serviceDescription.address servicePort:devicePort];
    }
    
    if (!_castDeviceManager)
    {
        NSDictionary *info = [[NSBundle mainBundle] infoDictionary];
        NSString *clientPackageName = [info objectForKey:@"CFBundleIdentifier"];

        _castDeviceManager = [self createDeviceManagerWithDevice:_castDevice
                                            andClientPackageName:clientPackageName];
        _castDeviceManager.delegate = self;
    }
    
    [_castDeviceManager connect];
}

- (void)disconnect
{
    if (!self.connected)
        return;

    self.connected = NO;

    [_castDeviceManager leaveApplication];
    [_castDeviceManager disconnect];

    if (self.delegate && [self.delegate respondsToSelector:@selector(deviceService:disconnectedWithError:)])
        dispatch_on_main(^{ [self.delegate deviceService:self disconnectedWithError:nil]; });
}

#pragma mark - Subscriptions

- (int)sendSubscription:(ServiceSubscription *)subscription type:(ServiceSubscriptionType)type payload:(id)payload toURL:(NSURL *)URL withId:(int)callId
{
    if (type == ServiceSubscriptionTypeUnsubscribe) {
        if (subscription == _playStateSubscription) {
            _playStateSubscription = nil;
        } else if (subscription == _mediaInfoSubscription) {
            _mediaInfoSubscription = nil;
        } else {
            [_subscriptions removeObject:subscription];
        }
    } else if (type == ServiceSubscriptionTypeSubscribe) {
        [_subscriptions addObject:subscription];
    }

    return callId;
}

- (int) getNextId
{
    UID = UID + 1;
    return UID;
}

#pragma mark - GCKDeviceManagerDelegate

- (void)deviceManagerDidConnect:(GCKDeviceManager *)deviceManager
{
    DLog(@"connected");

    self.connected = YES;

    _castMediaControlChannel = [self createMediaControlChannel];
    [_castDeviceManager addChannel:_castMediaControlChannel];

    dispatch_on_main(^{ [self.delegate deviceServiceConnectionSuccess:self]; });
}

- (void)deviceManager:(GCKDeviceManager *)deviceManager didConnectToCastApplication:(GCKApplicationMetadata *)applicationMetadata sessionID:(NSString *)sessionID launchedApplication:(BOOL)launchedApplication
{
    DLog(@"%@ (%@)", applicationMetadata.applicationName, applicationMetadata.applicationID);

    _currentAppId = applicationMetadata.applicationID;

    WebAppLaunchSuccessBlock success = [_launchSuccessBlocks objectForKey:applicationMetadata.applicationID];

    LaunchSession *launchSession = [LaunchSession launchSessionForAppId:applicationMetadata.applicationID];
    launchSession.name = applicationMetadata.applicationName;
    launchSession.sessionId = sessionID;
    launchSession.sessionType = LaunchSessionTypeWebApp;
    launchSession.service = self;

    CastWebAppSession *webAppSession = [[CastWebAppSession alloc] initWithLaunchSession:launchSession service:self];
    webAppSession.metadata = applicationMetadata;

    [_sessions setObject:webAppSession forKey:applicationMetadata.applicationID];

    if (success)
        dispatch_on_main(^{ success(webAppSession); });

    [_launchSuccessBlocks removeObjectForKey:applicationMetadata.applicationID];
    [_launchFailureBlocks removeObjectForKey:applicationMetadata.applicationID];
    _launchingAppId = nil;
}

- (void)deviceManager:(GCKDeviceManager *)deviceManager didDisconnectFromApplicationWithError:(NSError *)error
{
    DLog(@"%@", error.localizedDescription);

    if (!_currentAppId)
        return;

    WebAppSession *webAppSession = [_sessions objectForKey:_currentAppId];

    if (!webAppSession || !webAppSession.delegate)
        return;

    [webAppSession.delegate webAppSessionDidDisconnect:webAppSession];
}

- (void)deviceManager:(GCKDeviceManager *)deviceManager didFailToConnectToApplicationWithError:(NSError *)error
{
    DLog(@"%@", error.localizedDescription);

    if (_launchingAppId)
    {
        FailureBlock failure = [_launchFailureBlocks objectForKey:_launchingAppId];

        if (failure)
            dispatch_on_main(^{ failure(error); });

        [_launchSuccessBlocks removeObjectForKey:_launchingAppId];
        [_launchFailureBlocks removeObjectForKey:_launchingAppId];
        _launchingAppId = nil;
    }
}

- (void)deviceManager:(GCKDeviceManager *)deviceManager didFailToConnectWithError:(NSError *)error
{
    DLog(@"%@", error.localizedDescription);

    if (self.connected)
        [self disconnect];
}

- (void)deviceManager:(GCKDeviceManager *)deviceManager didFailToStopApplicationWithError:(NSError *)error
{
    DLog(@"%@", error.localizedDescription);
}

- (void)deviceManager:(GCKDeviceManager *)deviceManager didReceiveApplicationMetadata:(GCKApplicationMetadata *)applicationMetadata
{
    DLog(@"%@", applicationMetadata);

    _currentAppId = applicationMetadata.applicationID;
}

- (void)deviceManager:(GCKDeviceManager *)deviceManager volumeDidChangeToLevel:(float)volumeLevel isMuted:(BOOL)isMuted
{
    DLog(@"volume: %f isMuted: %d", volumeLevel, isMuted);

    _currentVolumeLevel = volumeLevel;
    _currentMuteStatus = isMuted;

    [_subscriptions enumerateObjectsUsingBlock:^(ServiceSubscription *subscription, NSUInteger idx, BOOL *stop)
    {
        NSString *eventName = (NSString *) subscription.payload;

        if (eventName)
        {
            if ([eventName isEqualToString:kCastServiceVolumeSubscriptionName])
            {
                [subscription.successCalls enumerateObjectsUsingBlock:^(id success, NSUInteger successIdx, BOOL *successStop)
                {
                    VolumeSuccessBlock volumeSuccess = (VolumeSuccessBlock) success;

                    if (volumeSuccess)
                        dispatch_on_main(^{ volumeSuccess(volumeLevel); });
                }];
            }

            if ([eventName isEqualToString:kCastServiceMuteSubscriptionName])
            {
                [subscription.successCalls enumerateObjectsUsingBlock:^(id success, NSUInteger successIdx, BOOL *successStop)
                {
                    MuteSuccessBlock muteSuccess = (MuteSuccessBlock) success;

                    if (muteSuccess)
                        dispatch_on_main(^{ muteSuccess(isMuted); });
                }];
            }
        }
    }];
}

- (void)deviceManager:(GCKDeviceManager *)deviceManager didDisconnectWithError:(NSError *)error
{
    DLog(@"%@", error.localizedDescription);

    self.connected = NO;
    
    _castMediaControlChannel.delegate = nil;
    _castMediaControlChannel = nil;
    _castDeviceManager = nil;

    dispatch_on_main(^{ [self.delegate deviceService:self disconnectedWithError:error]; });
}

#pragma mark - Media Player

- (id<MediaPlayer>)mediaPlayer
{
    return self;
}

- (CapabilityPriorityLevel)mediaPlayerPriority
{
    return CapabilityPriorityLevelHigh;
}

- (void)displayImage:(NSURL *)imageURL iconURL:(NSURL *)iconURL title:(NSString *)title description:(NSString *)description mimeType:(NSString *)mimeType success:(MediaPlayerDisplaySuccessBlock)success failure:(FailureBlock)failure
{
    GCKMediaMetadata *metaData = [[GCKMediaMetadata alloc] initWithMetadataType:GCKMediaMetadataTypePhoto];
    [metaData setString:title forKey:kGCKMetadataKeyTitle];
    [metaData setString:description forKey:kGCKMetadataKeySubtitle];

    if (iconURL)
    {
        GCKImage *iconImage = [[GCKImage alloc] initWithURL:iconURL width:100 height:100];
        [metaData addImage:iconImage];
    }
    
    GCKMediaInformation *mediaInformation = [[GCKMediaInformation alloc] initWithContentID:imageURL.absoluteString streamType:GCKMediaStreamTypeNone contentType:mimeType metadata:metaData streamDuration:0 customData:nil];

    [self playMedia:mediaInformation webAppId:self.castWebAppId success:^(MediaLaunchObject *mediaLanchObject) {
        success(mediaLanchObject.session,mediaLanchObject.mediaControl);
    } failure:failure];
}

- (void) displayImage:(MediaInfo *)mediaInfo
              success:(MediaPlayerDisplaySuccessBlock)success
              failure:(FailureBlock)failure
{
    NSURL *iconURL;
    if(mediaInfo.images){
        ImageInfo *imageInfo = [mediaInfo.images firstObject];
        iconURL = imageInfo.url;
    }
    
    [self displayImage:mediaInfo.url iconURL:iconURL title:mediaInfo.title description:mediaInfo.description mimeType:mediaInfo.mimeType success:success failure:failure];
}

- (void) displayImageWithMediaInfo:(MediaInfo *)mediaInfo success:(MediaPlayerSuccessBlock)success failure:(FailureBlock)failure
{
    NSURL *iconURL;
    if(mediaInfo.images){
        ImageInfo *imageInfo = [mediaInfo.images firstObject];
        iconURL = imageInfo.url;
    }
    
    GCKMediaMetadata *metaData = [[GCKMediaMetadata alloc] initWithMetadataType:GCKMediaMetadataTypePhoto];
    [metaData setString:mediaInfo.title forKey:kGCKMetadataKeyTitle];
    [metaData setString:mediaInfo.description forKey:kGCKMetadataKeySubtitle];
    
    if (iconURL)
    {
        GCKImage *iconImage = [[GCKImage alloc] initWithURL:iconURL width:100 height:100];
        [metaData addImage:iconImage];
    }
    
    GCKMediaInformation *mediaInformation = [[GCKMediaInformation alloc] initWithContentID:mediaInfo.url.absoluteString streamType:GCKMediaStreamTypeNone contentType:mediaInfo.mimeType metadata:metaData streamDuration:0 customData:nil];
    
    [self playMedia:mediaInformation webAppId:self.castWebAppId success:success failure:failure];
}

- (void) playMedia:(NSURL *)videoURL iconURL:(NSURL *)iconURL title:(NSString *)title description:(NSString *)description mimeType:(NSString *)mimeType shouldLoop:(BOOL)shouldLoop success:(MediaPlayerDisplaySuccessBlock)success failure:(FailureBlock)failure
{
    GCKMediaMetadata *metaData = [[GCKMediaMetadata alloc] initWithMetadataType:GCKMediaMetadataTypeMovie];
    [metaData setString:title forKey:kGCKMetadataKeyTitle];
    [metaData setString:description forKey:kGCKMetadataKeySubtitle];

    if (iconURL)
    {
        GCKImage *iconImage = [[GCKImage alloc] initWithURL:iconURL width:100 height:100];
        [metaData addImage:iconImage];
    }
    
    GCKMediaInformation *mediaInformation = [[GCKMediaInformation alloc] initWithContentID:videoURL.absoluteString streamType:GCKMediaStreamTypeBuffered contentType:mimeType metadata:metaData streamDuration:1000 customData:nil];

    [self playMedia:mediaInformation webAppId:self.castWebAppId success:^(MediaLaunchObject *mediaLanchObject) {
        success(mediaLanchObject.session,mediaLanchObject.mediaControl);
    } failure:failure];
}

- (void) playMedia:(MediaInfo *)mediaInfo shouldLoop:(BOOL)shouldLoop success:(MediaPlayerDisplaySuccessBlock)success failure:(FailureBlock)failure
{
    NSURL *iconURL;
    if(mediaInfo.images){
        ImageInfo *imageInfo = [mediaInfo.images firstObject];
        iconURL = imageInfo.url;
    }
    [self playMedia:mediaInfo.url iconURL:iconURL title:mediaInfo.title description:mediaInfo.description mimeType:mediaInfo.mimeType shouldLoop:shouldLoop success:success failure:failure];
}

- (void) playMediaWithMediaInfo:(MediaInfo *)mediaInfo shouldLoop:(BOOL)shouldLoop success:(MediaPlayerSuccessBlock)success failure:(FailureBlock)failure{
    NSURL *iconURL;
    if(mediaInfo.images){
        ImageInfo *imageInfo = [mediaInfo.images firstObject];
        iconURL = imageInfo.url;
    }
    
    GCKMediaMetadata *metaData = [[GCKMediaMetadata alloc] initWithMetadataType:GCKMediaMetadataTypeMovie];
    [metaData setString:mediaInfo.title forKey:kGCKMetadataKeyTitle];
    [metaData setString:mediaInfo.description forKey:kGCKMetadataKeySubtitle];
    
    if (iconURL)
    {
        GCKImage *iconImage = [[GCKImage alloc] initWithURL:iconURL width:100 height:100];
        [metaData addImage:iconImage];
    }

    NSArray *mediaTracks;
    if (mediaInfo.subtitleInfo) {
        mediaTracks = @[
            [self mediaTrackFromSubtitleInfo:mediaInfo.subtitleInfo]];
    }

    GCKMediaInformation *mediaInformation = [[GCKMediaInformation alloc]
        initWithContentID:mediaInfo.url.absoluteString
               streamType:GCKMediaStreamTypeBuffered
              contentType:mediaInfo.mimeType
                 metadata:metaData
           streamDuration:1000
              mediaTracks:mediaTracks
           textTrackStyle:[GCKMediaTextTrackStyle createDefault]
               customData:nil];
    
    [self playMedia:mediaInformation webAppId:self.castWebAppId success:success failure:failure];
}

- (void) playMedia:(GCKMediaInformation *)mediaInformation webAppId:(NSString *)mediaAppId success:(MediaPlayerSuccessBlock)success failure:(FailureBlock)failure
{
    WebAppLaunchSuccessBlock webAppLaunchBlock = ^(WebAppSession *webAppSession)
    {
        NSArray *trackIDs;
        if (mediaInformation.mediaTracks) {
            trackIDs = @[@(kSubtitleTrackIdentifier)];
        }

        NSInteger result = [_castMediaControlChannel loadMedia:mediaInformation
                                                      autoplay:YES
                                                  playPosition:0.0
                                                activeTrackIDs:trackIDs];

        if (result == kGCKInvalidRequestID)
        {
            if (failure)
                failure([ConnectError generateErrorWithCode:ConnectStatusCodeTvError andDetails:nil]);
        } else
        {
            webAppSession.launchSession.sessionType = LaunchSessionTypeMedia;

            _castMediaControlChannel.delegate = self;

            if (success){
                    MediaLaunchObject *launchObject = [[MediaLaunchObject alloc] initWithLaunchSession:webAppSession.launchSession andMediaControl:webAppSession.mediaControl];
                    success(launchObject);
            }
        }
    };

    _launchingAppId = mediaAppId;

    [_launchSuccessBlocks setObject:webAppLaunchBlock forKey:mediaAppId];

    if (failure)
        [_launchFailureBlocks setObject:failure forKey:mediaAppId];

    BOOL result = [self launchApplicationWithId:mediaAppId relaunchIfRunning:NO];

    if (!result)
    {
        [_launchSuccessBlocks removeObjectForKey:mediaAppId];
        [_launchFailureBlocks removeObjectForKey:mediaAppId];

        if (failure)
            failure([ConnectError generateErrorWithCode:ConnectStatusCodeTvError andDetails:nil]);
    }
}

- (void)closeMedia:(LaunchSession *)launchSession success:(SuccessBlock)success failure:(FailureBlock)failure
{
    BOOL result = [_castDeviceManager stopApplicationWithSessionID:launchSession.sessionId];

    if (result)
    {
        if (success)
            success(nil);
    } else
    {
        if (failure)
            failure([ConnectError generateErrorWithCode:ConnectStatusCodeTvError andDetails:nil]);
    }
}

#pragma mark - Media Control

- (id<MediaControl>)mediaControl
{
    return self;
}

- (CapabilityPriorityLevel)mediaControlPriority
{
    return CapabilityPriorityLevelHigh;
}

- (void)playWithSuccess:(SuccessBlock)success failure:(FailureBlock)failure
{
    NSInteger result;

    @try
    {
        result = [_castMediaControlChannel play];
    } @catch (NSException *exception)
    {
        // this exception will be caught when trying to send command with no video
        result = kGCKInvalidRequestID;
    }

    if (result == kGCKInvalidRequestID)
    {
        if (failure)
            failure(nil);
    } else
    {
        if (success)
            success(nil);
    }
}

- (void)pauseWithSuccess:(SuccessBlock)success failure:(FailureBlock)failure
{
    NSInteger result;

    @try
    {
        result = [_castMediaControlChannel pause];
    } @catch (NSException *exception)
    {
        // this exception will be caught when trying to send command with no video
        result = kGCKInvalidRequestID;
    }

    if (result == kGCKInvalidRequestID)
    {
        if (failure)
            failure(nil);
    } else
    {
        if (success)
            success(nil);
    }
}

- (void)stopWithSuccess:(SuccessBlock)success failure:(FailureBlock)failure
{
    NSInteger result;

    @try
    {
        result = [_castMediaControlChannel stop];
    } @catch (NSException *exception)
    {
        // this exception will be caught when trying to send command with no video
        result = kGCKInvalidRequestID;
    }

    if (result == kGCKInvalidRequestID)
    {
        if (failure)
            failure(nil);
    } else
    {
        if (success)
            success(nil);
    }
}

- (void)rewindWithSuccess:(SuccessBlock)success failure:(FailureBlock)failure
{
    [self sendNotSupportedFailure:failure];
}

- (void)fastForwardWithSuccess:(SuccessBlock)success failure:(FailureBlock)failure
{
    [self sendNotSupportedFailure:failure];
}

- (void)seek:(NSTimeInterval)position
     success:(SuccessBlock)success
     failure:(FailureBlock)failure {
    if (!self.castMediaControlChannel.mediaStatus)
    {
        if (failure)
            failure([ConnectError generateErrorWithCode:ConnectStatusCodeError andDetails:@"There is no media currently available"]);

        return;
    }

    NSInteger result = [self.castMediaControlChannel seekToTimeInterval:position];

    if (result == kGCKInvalidRequestID)
    {
        if (failure)
            failure([ConnectError generateErrorWithCode:ConnectStatusCodeTvError andDetails:nil]);
    } else
    {
        if (success)
            success(nil);
    }
}

- (void)getDurationWithSuccess:(MediaDurationSuccessBlock)success
                       failure:(FailureBlock)failure {
    if (self.castMediaControlChannel.mediaStatus)
    {
        if (success)
            success(self.castMediaControlChannel.mediaStatus.mediaInformation.streamDuration);
    } else
    {
        if (failure)
            failure([ConnectError generateErrorWithCode:ConnectStatusCodeError andDetails:@"There is no media currently available"]);
    }
}

- (void)getPositionWithSuccess:(MediaPositionSuccessBlock)success
                       failure:(FailureBlock)failure {
    if (self.castMediaControlChannel.mediaStatus)
    {
        if (success)
            success(self.castMediaControlChannel.approximateStreamPosition);
    } else
    {
        if (failure)
            failure([ConnectError generateErrorWithCode:ConnectStatusCodeError andDetails:@"There is no media currently available"]);
    }
}

- (void)getPlayStateWithSuccess:(MediaPlayStateSuccessBlock)success
                        failure:(FailureBlock)failure {
    if (!self.castMediaControlChannel.mediaStatus)
    {
        if (failure)
            failure([ConnectError generateErrorWithCode:ConnectStatusCodeError andDetails:@"There is no media currently available"]);

        return;
    }

    _immediatePlayStateCallback = success;

    NSInteger result = [self.castMediaControlChannel requestStatus];

    if (result == kGCKInvalidRequestID)
    {
        _immediatePlayStateCallback = nil;

        if (failure)
            failure([ConnectError generateErrorWithCode:ConnectStatusCodeTvError andDetails:nil]);
    }
}

- (ServiceSubscription *)subscribePlayStateWithSuccess:(MediaPlayStateSuccessBlock)success
                                               failure:(FailureBlock)failure {
    if (!_playStateSubscription)
        _playStateSubscription = [ServiceSubscription subscriptionWithDelegate:self target:nil payload:nil callId:-1];

    [_playStateSubscription addSuccess:success];
    [_playStateSubscription addFailure:failure];

    [self.castMediaControlChannel requestStatus];

    return _playStateSubscription;
}

- (void)getMediaMetaDataWithSuccess:(SuccessBlock)success
                            failure:(FailureBlock)failure {
    if (self.castMediaControlChannel.mediaStatus)
    {
        if (success) {
            success([self metadataInfoFromMediaMetadata:self.castMediaControlChannel
                .mediaStatus
                .mediaInformation
                .metadata]);
        }
    } else
    {
        if (failure)
            failure([ConnectError generateErrorWithCode:ConnectStatusCodeError andDetails:@"There is no media currently available"]);
    }
}

- (ServiceSubscription *)subscribeMediaInfoWithSuccess:(SuccessBlock)success
                                               failure:(FailureBlock)failure {
    if (!_mediaInfoSubscription)
        _mediaInfoSubscription = [ServiceSubscription subscriptionWithDelegate:self target:nil payload:nil callId:-1];

    [_mediaInfoSubscription addSuccess:success];
    [_mediaInfoSubscription addFailure:failure];

    [self.castMediaControlChannel requestStatus];

    return _mediaInfoSubscription;
}

#pragma mark - WebAppLauncher

- (id<WebAppLauncher>)webAppLauncher
{
    return self;
}

- (CapabilityPriorityLevel)webAppLauncherPriority
{
    return CapabilityPriorityLevelHigh;
}

- (void)launchWebApp:(NSString *)webAppId success:(WebAppLaunchSuccessBlock)success failure:(FailureBlock)failure
{
    [self launchWebApp:webAppId relaunchIfRunning:YES success:success failure:failure];
}

- (void)launchWebApp:(NSString *)webAppId relaunchIfRunning:(BOOL)relaunchIfRunning success:(WebAppLaunchSuccessBlock)success failure:(FailureBlock)failure
{
    [_launchSuccessBlocks removeObjectForKey:webAppId];
    [_launchFailureBlocks removeObjectForKey:webAppId];

    if (success)
        [_launchSuccessBlocks setObject:success forKey:webAppId];

    if (failure)
        [_launchFailureBlocks setObject:failure forKey:webAppId];

    _launchingAppId = webAppId;

    BOOL result = [self launchApplicationWithId:webAppId
                              relaunchIfRunning:relaunchIfRunning];

    if (!result)
    {
        [_launchSuccessBlocks removeObjectForKey:webAppId];
        [_launchFailureBlocks removeObjectForKey:webAppId];
        _launchingAppId = nil;

        if (failure)
            failure([ConnectError generateErrorWithCode:ConnectStatusCodeTvError andDetails:@"Could not detect if web app launched -- make sure you have the Google Cast Receiver JavaScript file in your web app"]);
    }
}

- (void)launchWebApp:(NSString *)webAppId params:(NSDictionary *)params success:(WebAppLaunchSuccessBlock)success failure:(FailureBlock)failure
{
    [self sendNotSupportedFailure:failure];
}

- (void)launchWebApp:(NSString *)webAppId params:(NSDictionary *)params relaunchIfRunning:(BOOL)relaunchIfRunning success:(WebAppLaunchSuccessBlock)success failure:(FailureBlock)failure
{
    [self sendNotSupportedFailure:failure];
}

- (void)joinWebApp:(LaunchSession *)webAppLaunchSession success:(WebAppLaunchSuccessBlock)success failure:(FailureBlock)failure
{
    WebAppLaunchSuccessBlock mySuccess = ^(WebAppSession *webAppSession)
    {
        SuccessBlock joinSuccess = ^(id responseObject)
        {
            if (success)
                success(webAppSession);
        };

        [webAppSession connectWithSuccess:joinSuccess failure:failure];
    };

    [_launchSuccessBlocks setObject:mySuccess forKey:webAppLaunchSession.appId];

    if (failure)
        [_launchFailureBlocks setObject:failure forKey:webAppLaunchSession.appId];

    _launchingAppId = webAppLaunchSession.appId;

    BOOL result = [_castDeviceManager joinApplication:webAppLaunchSession.appId];

    if (!result)
    {
        [_launchSuccessBlocks removeObjectForKey:webAppLaunchSession.appId];
        [_launchFailureBlocks removeObjectForKey:webAppLaunchSession.appId];
        _launchingAppId = nil;

        if (failure)
            failure([ConnectError generateErrorWithCode:ConnectStatusCodeTvError andDetails:@"Could not detect if web app launched -- make sure you have the Google Cast Receiver JavaScript file in your web app"]);
    }
}

- (void) joinWebAppWithId:(NSString *)webAppId success:(WebAppLaunchSuccessBlock)success failure:(FailureBlock)failure
{
    LaunchSession *launchSession = [LaunchSession launchSessionForAppId:webAppId];
    launchSession.sessionType = LaunchSessionTypeWebApp;
    launchSession.service = self;

    [self joinWebApp:launchSession success:success failure:failure];
}

- (void)closeWebApp:(LaunchSession *)launchSession success:(SuccessBlock)success failure:(FailureBlock)failure
{
    BOOL result = [self.castDeviceManager stopApplication];

    if (result)
    {
        if (success)
            success(nil);
    } else
    {
        if (failure)
            failure([ConnectError generateErrorWithCode:ConnectStatusCodeTvError andDetails:nil]);
    }
}

- (void) pinWebApp:(NSString *)webAppId success:(SuccessBlock)success failure:(FailureBlock)failure
{
    [self sendNotSupportedFailure:failure];
}

-(void)unPinWebApp:(NSString *)webAppId success:(SuccessBlock)success failure:(FailureBlock)failure
{
    [self sendNotSupportedFailure:failure];
}

- (void)isWebAppPinned:(NSString *)webAppId success:(WebAppPinStatusBlock)success failure:(FailureBlock)failure
{
    [self sendNotSupportedFailure:failure];
}

- (ServiceSubscription *)subscribeIsWebAppPinned:(NSString*)webAppId success:(WebAppPinStatusBlock)success failure:(FailureBlock)failure
{
    [self sendNotSupportedFailure:failure];
    return nil;
}

#pragma mark - Volume Control

- (id <VolumeControl>)volumeControl
{
    return self;
}

- (CapabilityPriorityLevel)volumeControlPriority
{
    return CapabilityPriorityLevelHigh;
}

- (void)volumeUpWithSuccess:(SuccessBlock)success failure:(FailureBlock)failure
{
    [self getVolumeWithSuccess:^(float volume)
    {
        if (volume >= 1.0)
        {
            if (success)
                success(nil);
        } else
        {
            float newVolume = volume + 0.01;

            if (newVolume > 1.0)
                newVolume = 1.0;

            [self setVolume:newVolume success:success failure:failure];
        }
    } failure:failure];
}

- (void)volumeDownWithSuccess:(SuccessBlock)success failure:(FailureBlock)failure
{
    [self getVolumeWithSuccess:^(float volume)
    {
        if (volume <= 0.0)
        {
            if (success)
                success(nil);
        } else
        {
            float newVolume = volume - 0.01;

            if (newVolume < 0.0)
                newVolume = 0.0;

            [self setVolume:newVolume success:success failure:failure];
        }
    } failure:failure];
}

- (void)setMute:(BOOL)mute success:(SuccessBlock)success failure:(FailureBlock)failure
{
    NSInteger result = [self.castDeviceManager setMuted:mute];

    if (result == kGCKInvalidRequestID)
    {
        if (failure)
            [ConnectError generateErrorWithCode:ConnectStatusCodeTvError andDetails:nil];
    } else
    {
        [self.castDeviceManager requestDeviceStatus];

        if (success)
            success(nil);
    }
}

- (void)getMuteWithSuccess:(MuteSuccessBlock)success failure:(FailureBlock)failure
{
    if (_currentMuteStatus)
    {
        if (success)
            success(_currentMuteStatus);
    } else
    {
        if (failure)
            failure([ConnectError generateErrorWithCode:ConnectStatusCodeTvError andDetails:@"Cannot get this information without media loaded"]);
    }
}

- (ServiceSubscription *)subscribeMuteWithSuccess:(MuteSuccessBlock)success failure:(FailureBlock)failure
{
    if (_currentMuteStatus)
    {
        if (success)
            success(_currentMuteStatus);
    }

    ServiceSubscription *subscription = [ServiceSubscription subscriptionWithDelegate:self target:nil payload:kCastServiceMuteSubscriptionName callId:[self getNextId]];
    [subscription addSuccess:success];
    [subscription addFailure:failure];
    [subscription subscribe];

    return subscription;
}

- (void)setVolume:(float)volume success:(SuccessBlock)success failure:(FailureBlock)failure
{
    NSInteger result;
    NSString *failureMessage;

    @try
    {
        result = [self.castDeviceManager setVolume:volume];
    } @catch (NSException *ex)
    {
        // this is likely caused by having no active media session
        result = kGCKInvalidRequestID;
        failureMessage = @"There is no active media session to set volume on";
    }

    if (result == kGCKInvalidRequestID)
    {
        if (failure)
            [ConnectError generateErrorWithCode:ConnectStatusCodeTvError andDetails:failureMessage];
    } else
    {
        [self.castDeviceManager requestDeviceStatus];

        if (success)
            success(nil);
    }
}

- (void)getVolumeWithSuccess:(VolumeSuccessBlock)success failure:(FailureBlock)failure
{
    if (_currentVolumeLevel)
    {
        if (success)
            success(_currentVolumeLevel);
    } else
    {
        if (failure)
            failure([ConnectError generateErrorWithCode:ConnectStatusCodeTvError andDetails:@"Cannot get this information without media loaded"]);
    }
}

- (ServiceSubscription *)subscribeVolumeWithSuccess:(VolumeSuccessBlock)success failure:(FailureBlock)failure
{
    if (_currentVolumeLevel)
    {
        if (success)
            success(_currentVolumeLevel);
    }

    ServiceSubscription *subscription = [ServiceSubscription subscriptionWithDelegate:self target:nil payload:kCastServiceVolumeSubscriptionName callId:[self getNextId]];
    [subscription addSuccess:success];
    [subscription addFailure:failure];
    [subscription subscribe];

    [self.castDeviceManager requestDeviceStatus];

    return subscription;
}

#pragma mark - GCKMediaControlChannelDelegate methods

- (void)mediaControlChannelDidUpdateStatus:(GCKMediaControlChannel *)mediaControlChannel
{
    MediaControlPlayState playState;

    switch (mediaControlChannel.mediaStatus.playerState)
    {
        case GCKMediaPlayerStateIdle:
            if (mediaControlChannel.mediaStatus.idleReason == GCKMediaPlayerIdleReasonFinished)
                playState = MediaControlPlayStateFinished;
            else
                playState = MediaControlPlayStateIdle;
            break;

        case GCKMediaPlayerStatePlaying:
            playState = MediaControlPlayStatePlaying;
            break;

        case GCKMediaPlayerStatePaused:
            playState = MediaControlPlayStatePaused;
            break;

        case GCKMediaPlayerStateBuffering:
            playState = MediaControlPlayStateBuffering;
            break;

        case GCKMediaPlayerStateUnknown:
        default:
            playState = MediaControlPlayStateUnknown;
    }

    if (_immediatePlayStateCallback)
    {
        _immediatePlayStateCallback(playState);
        _immediatePlayStateCallback = nil;
    }

    if (_playStateSubscription)
    {
        [_playStateSubscription.successCalls enumerateObjectsUsingBlock:^(id success, NSUInteger idx, BOOL *stop)
        {
            MediaPlayStateSuccessBlock mediaPlayStateSuccess = (MediaPlayStateSuccessBlock) success;

            if (mediaPlayStateSuccess)
                mediaPlayStateSuccess(playState);
        }];
    }

    if (_mediaInfoSubscription)
    {
        [_mediaInfoSubscription.successCalls enumerateObjectsUsingBlock:^(id success, NSUInteger idx, BOOL *stop)
        {
            SuccessBlock mediaInfoSuccess = (SuccessBlock) success;

            if (mediaInfoSuccess){
                mediaInfoSuccess([self metadataInfoFromMediaMetadata:self.castMediaControlChannel
                    .mediaStatus
                    .mediaInformation
                    .metadata]);
            }
        }];
    }
}

#pragma mark - Private

- (GCKDeviceManager *)createDeviceManagerWithDevice:(GCKDevice *)device
                               andClientPackageName:(NSString *)clientPackageName {
    return [[GCKDeviceManager alloc] initWithDevice:device
                                  clientPackageName:clientPackageName];
}

- (GCKMediaControlChannel *)createMediaControlChannel {
    return [[GCKMediaControlChannel alloc] init];
}

- (GCKMediaTrack *)mediaTrackFromSubtitleInfo:(SubtitleInfo *)subtitleInfo {
    return [[GCKMediaTrack alloc]
        initWithIdentifier:kSubtitleTrackIdentifier
         contentIdentifier:subtitleInfo.url.absoluteString
               contentType:subtitleInfo.mimeType
                      type:GCKMediaTrackTypeText
               textSubtype:GCKMediaTextTrackSubtypeSubtitles
                      name:subtitleInfo.label
        // languageCode is required when the track is subtitles
              languageCode:subtitleInfo.language ?: kSubtitleTrackDefaultLanguage
                customData:nil];
}

- (NSDictionary *)metadataInfoFromMediaMetadata:(GCKMediaMetadata *)metaData {
    NSMutableDictionary *mediaMetaData = [NSMutableDictionary dictionary];

    [mediaMetaData setNullableObject:[metaData objectForKey:kGCKMetadataKeyTitle]
                              forKey:@"title"];
    [mediaMetaData setNullableObject:[metaData objectForKey:kGCKMetadataKeySubtitle]
                              forKey:@"subtitle"];

    NSString *const kMetadataKeyIconURL = @"iconURL";
    GCKImage *image = [metaData.images firstObject];
    [mediaMetaData setNullableObject:image.URL.absoluteString
                              forKey:kMetadataKeyIconURL];
    if (!mediaMetaData[kMetadataKeyIconURL]) {
        NSDictionary *imageDict = [[metaData objectForKey:@"images"] firstObject];
        [mediaMetaData setNullableObject:imageDict[@"url"]
                                  forKey:kMetadataKeyIconURL];
    }

    return mediaMetaData;
}

- (BOOL)launchApplicationWithId:(NSString *)webAppId
              relaunchIfRunning:(BOOL)relaunchIfRunning {
    GCKLaunchOptions *options = [[GCKLaunchOptions alloc]
        initWithRelaunchIfRunning:relaunchIfRunning];
    NSInteger requestId = [_castDeviceManager launchApplication:webAppId
                                              withLaunchOptions:options];
    return kGCKInvalidRequestID != requestId;
}

@end
