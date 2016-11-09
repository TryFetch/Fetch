//
//  CastWebAppSessionTests.m
//  ConnectSDK
//
//  Created by Eugene Nikolskyi on 2015-07-30.
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

#import "CastWebAppSession.h"

@interface CastWebAppSessionTests : XCTestCase

@property (nonatomic, strong) CastWebAppSession *session;

@end

@implementation CastWebAppSessionTests

- (void)setUp {
    [super setUp];

    self.session = [CastWebAppSession new];
}

#pragma mark - Method Implementation Tests

- (void)testSeekShouldBeImplemented {
    [self assertMethodIsImplemented:^{
        [self.session seek:0.0 success:nil failure:nil];
    }];
}

- (void)testGetDurationShouldBeImplemented {
    [self assertMethodIsImplemented:^{
        [self.session getDurationWithSuccess:nil failure:nil];
    }];
}

- (void)testGetPositionShouldBeImplemented {
    [self assertMethodIsImplemented:^{
        [self.session getPositionWithSuccess:nil failure:nil];
    }];
}

- (void)testGetPlayStateShouldBeImplemented {
    [self assertMethodIsImplemented:^{
        [self.session getPlayStateWithSuccess:nil failure:nil];
    }];
}

- (void)testSubscribePlayStateShouldBeImplemented {
    [self assertMethodIsImplemented:^{
        [self.session subscribePlayStateWithSuccess:nil failure:nil];
    }];
}

- (void)testGetMediaMetadataShouldBeImplemented {
    [self assertMethodIsImplemented:^{
        [self.session getMediaMetaDataWithSuccess:nil failure:nil];
    }];
}

- (void)testSubscribeMediaInfoShouldBeImplemented {
    [self assertMethodIsImplemented:^{
        [self.session subscribeMediaInfoWithSuccess:nil failure:nil];
    }];
}

#pragma mark - Helpers

- (void)assertMethodIsImplemented:(void (^)())testBlock {
    XCTAssertNoThrowSpecificNamed(testBlock(), NSException,
                                  NSInvalidArgumentException);
}

@end
