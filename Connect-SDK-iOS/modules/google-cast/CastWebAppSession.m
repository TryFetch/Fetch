//
//  CastWebAppSession.m
//  Connect SDK
//
//  Created by Jeremy White on 2/23/14.
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

#import "CastWebAppSession.h"
#import "ConnectError.h"


@interface CastWebAppSession () <GCKMediaControlChannelDelegate>

@end

@implementation CastWebAppSession

@dynamic service;

- (void) connectWithSuccess:(SuccessBlock)success failure:(FailureBlock)failure
{
    if (_castServiceChannel)
        [self disconnectFromWebApp];
    
    FailureBlock channelFailure = ^(NSError *error) {
        _castServiceChannel = nil;
        
        if (failure)
            failure(error);
    };
    
    _castServiceChannel = [[CastServiceChannel alloc] initWithAppId:self.launchSession.appId session:self];

    // clean up old instance of channel, if it exists
    [self.service.castDeviceManager removeChannel:_castServiceChannel];

    _castServiceChannel.connectionSuccess = success;
    _castServiceChannel.connectionFailure = channelFailure;

    [self.service.castDeviceManager addChannel:_castServiceChannel];
}

- (void) joinWithSuccess:(SuccessBlock)success failure:(FailureBlock)failure
{
    [self connectWithSuccess:success failure:failure];
}

- (void)disconnectFromWebApp
{
    if (!_castServiceChannel)
        return;

    [self.service.castDeviceManager removeChannel:_castServiceChannel];
    _castServiceChannel = nil;

    [self.service.castDeviceManager leaveApplication];
}

#pragma mark - App to app

- (void)sendText:(NSString *)message success:(SuccessBlock)success failure:(FailureBlock)failure
{
    if (message == nil)
    {
        if (failure)
            failure([ConnectError generateErrorWithCode:ConnectStatusCodeArgumentError andDetails:@"Cannot send nil message."]);

        return;
    }

    if (_castServiceChannel == nil)
    {
        if (failure)
            failure([ConnectError generateErrorWithCode:ConnectStatusCodeError andDetails:@"Cannot send a message to the web app without first connecting"]);

        return;
    }

    BOOL messageSent = [_castServiceChannel sendTextMessage:message];

    if (messageSent)
    {
        if (success)
            success(nil);
    } else
    {
        if (failure)
            failure([ConnectError generateErrorWithCode:ConnectStatusCodeError andDetails:@"Message could not be sent at this time."]);
    }
}

- (void)sendJSON:(NSDictionary *)message success:(SuccessBlock)success failure:(FailureBlock)failure
{
    if (message == nil)
    {
        if (failure)
            failure([ConnectError generateErrorWithCode:ConnectStatusCodeArgumentError andDetails:@"Cannot send nil message."]);

        return;
    }

    NSError *error;
    NSData *messageData = [NSJSONSerialization dataWithJSONObject:message options:0 error:&error];

    if (error || messageData == nil)
    {
        if (failure)
            failure([ConnectError generateErrorWithCode:ConnectStatusCodeArgumentError andDetails:@"Failed to parse message dictionary into a JSON object."]);

        return;
    } else
    {
        NSString *messageJSON = [[NSString alloc] initWithData:messageData encoding:NSUTF8StringEncoding];

        [self sendText:messageJSON success:success failure:failure];
    }
}

#pragma mark - Media Player

- (id <MediaPlayer>) mediaPlayer
{
    return self;
}

- (CapabilityPriorityLevel) mediaPlayerPriority
{
    return CapabilityPriorityLevelHigh;
}

- (void) displayImage:(NSURL *)imageURL iconURL:(NSURL *)iconURL title:(NSString *)title description:(NSString *)description mimeType:(NSString *)mimeType success:(MediaPlayerDisplaySuccessBlock)success failure:(FailureBlock)failure
{
    if (failure)
        failure([ConnectError generateErrorWithCode:ConnectStatusCodeArgumentError andDetails:nil]);
}

- (void) displayImage:(MediaInfo *)mediaInfo
              success:(MediaPlayerDisplaySuccessBlock)success
              failure:(FailureBlock)failure
{
    if (failure)
        failure([ConnectError generateErrorWithCode:ConnectStatusCodeArgumentError andDetails:nil]);
}

- (void) playMedia:(NSURL *)mediaURL iconURL:(NSURL *)iconURL title:(NSString *)title description:(NSString *)description mimeType:(NSString *)mimeType shouldLoop:(BOOL)shouldLoop success:(MediaPlayerDisplaySuccessBlock)success failure:(FailureBlock)failure
{
    
    MediaInfo *mediaInfo = [[MediaInfo alloc] initWithURL:mediaURL mimeType:mimeType];
    mediaInfo.title = title;
    mediaInfo.description = description;
    ImageInfo *imageInfo = [[ImageInfo alloc] initWithURL:iconURL type:ImageTypeThumb];
    [mediaInfo addImage:imageInfo];
    
    [self playMediaWithMediaInfo:mediaInfo shouldLoop:shouldLoop success:^(MediaLaunchObject *mediaLanchObject) {
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

- (void)playMediaWithMediaInfo:(MediaInfo *)mediaInfo shouldLoop:(BOOL)shouldLoop success:(MediaPlayerSuccessBlock)success failure:(FailureBlock)failure
{
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
    
    GCKMediaInformation *mediaInformation = [[GCKMediaInformation alloc] initWithContentID:mediaInfo.url.absoluteString streamType:GCKMediaStreamTypeBuffered contentType:mediaInfo.mimeType metadata:metaData streamDuration:1000 customData:nil];
    
    [self.service playMedia:mediaInformation webAppId:self.launchSession.appId success:^(MediaLaunchObject *mediaLanchObject){
         self.launchSession.sessionId = mediaLanchObject.session.sessionId;
        mediaLanchObject.session = self.launchSession;
        mediaLanchObject.mediaControl = self.mediaControl;
         if (success)
             success(mediaLanchObject);
     } failure:failure];
    
}

- (void) closeMedia:(LaunchSession *)launchSession success:(SuccessBlock)success failure:(FailureBlock)failure
{
    [self closeWithSuccess:success failure:failure];
}

#pragma mark - Media Control

- (id <MediaControl>)mediaControl
{
    return self;
}

- (CapabilityPriorityLevel)mediaControlPriority
{
    return CapabilityPriorityLevelHigh;
}

- (void)getDurationWithSuccess:(MediaDurationSuccessBlock)success failure:(FailureBlock)failure
{
    [self.service getDurationWithSuccess:success failure:failure];
}

- (void)seek:(NSTimeInterval)position success:(SuccessBlock)success failure:(FailureBlock)failure
{
    [self.service seek:position success:success failure:failure];
}

- (void)getPlayStateWithSuccess:(MediaPlayStateSuccessBlock)success failure:(FailureBlock)failure
{
    [self.service getPlayStateWithSuccess:success failure:failure];
}

- (ServiceSubscription *)subscribePlayStateWithSuccess:(MediaPlayStateSuccessBlock)success failure:(FailureBlock)failure
{
    return [self.service subscribePlayStateWithSuccess:success failure:failure];
}

- (void)getPositionWithSuccess:(MediaPositionSuccessBlock)success failure:(FailureBlock)failure
{
    [self.service getPositionWithSuccess:success failure:failure];
}

- (void)closeWithSuccess:(SuccessBlock)success failure:(FailureBlock)failure
{
    if (_castServiceChannel)
        [self disconnectFromWebApp];

    [self.service.webAppLauncher closeWebApp:self.launchSession success:success failure:failure];
}

-(void)getMediaMetaDataWithSuccess:(SuccessBlock)success failure:(FailureBlock)failure{
    [self.service getMediaMetaDataWithSuccess:success failure:failure];
}

- (ServiceSubscription *)subscribeMediaInfoWithSuccess:(SuccessBlock)success failure:(FailureBlock)failure{
    return [self.service subscribeMediaInfoWithSuccess:success failure:failure];
}

@end
