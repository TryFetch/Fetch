//
//  XCTestCase+TaskTests.m
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

#import "XCTestCase+TaskTests.h"
#import "ConnectError.h"

#import <Bolts/Bolts.h>

@implementation XCTestCase (TaskTests)

#pragma mark - Public Methods

- (void)checkTaskSuccessOnStubRecorder:(OCMStubRecorder *)recorder
      shouldCallSuccessBlockUsingBlock:(ActionBlock)block {
    BFTask *task = [BFTask taskWithResult:nil];
    [self checkTaskSuccess:task
            onStubRecorder:recorder
shouldCallSuccessBlockUsingBlock:block];
}

- (void)checkTaskSuccess:(BFTask *)task
          onStubRecorder:(OCMStubRecorder *)recorder
shouldCallSuccessBlockUsingBlock:(ActionBlock)block {
    [self checkTaskSuccess:task
            onStubRecorder:recorder
shouldCallSuccessBlockUsingBlock:block
           asynchoronously:NO];
}

- (void)checkTaskErrorOnStubRecorder:(OCMStubRecorder *)recorder
    shouldCallFailureBlockUsingBlock:(ActionBlock)block {
    BFTask *task = [self errorTask];
    [self checkTaskError:task
          onStubRecorder:recorder
shouldCallFailureBlockWithError:task.error
              usingBlock:block];
}

- (void)checkTaskSuccessOnStubRecorder:(OCMStubRecorder *)recorder
 shouldAsyncCallSuccessBlockUsingBlock:(ActionBlock)block {
    BFTask *task = [BFTask taskWithResult:nil];
    [self checkTaskSuccess:task
            onStubRecorder:recorder
shouldCallSuccessBlockUsingBlock:block
           asynchoronously:YES];
}

- (BFTask *)errorTask {
    NSError *error = [NSError errorWithDomain:NSURLErrorDomain
                                         code:NSURLErrorNotConnectedToInternet
                                     userInfo:nil];
    return [BFTask taskWithError:error];
}

#pragma mark - Helpers

- (void)checkTaskSuccess:(BFTask *)task
          onStubRecorder:(OCMStubRecorder *)recorder
shouldCallSuccessBlockUsingBlock:(ActionBlock)block
         asynchoronously:(BOOL)asynchronously {
    NSString *const message = @"success block should be called";
    ActionBlock actionBlock = ^(SuccessBlock successVerifier, FailureBlock failureVerifier) {
        SuccessBlock success = ^(id response) {
            XCTAssertNil(response, @"should be no response object");
            successVerifier(nil);
        };
        FailureBlock failure = ^(NSError *e) {
            XCTFail(@"should be no error");
            failureVerifier(nil);
        };
        block(success, failure);
    };

    if (asynchronously) {
        [self checkTask:task
         onStubRecorder:recorder
asyncCallsEitherBlockIn:actionBlock
      withAssertMessage:message];
    } else {
        [self checkTask:task
         onStubRecorder:recorder
     callsEitherBlockIn:actionBlock
      withAssertMessage:message];
    }
}

/**
 * Checks that the error @c task returned from a stub @c recorder calls the
 * @c FailureBlock (with the @c expectedError) of the operation done in the
 * @c block.
 */
- (void)checkTaskError:(BFTask *)task
        onStubRecorder:(OCMStubRecorder *)recorder
shouldCallFailureBlockWithError:(NSError *)expectedError
            usingBlock:(ActionBlock)block {
    [self checkTask:task
     onStubRecorder:recorder
 callsEitherBlockIn:^(SuccessBlock successVerifier, FailureBlock failureVerifier) {
     SuccessBlock success = ^(id response) {
         XCTFail(@"should be no success");
         successVerifier(nil);
     };
     FailureBlock failure = ^(NSError *error) {
         XCTAssertEqualObjects(error, expectedError, @"Error is wrong");
         failureVerifier(nil);
     };
     block(success, failure);
 }
  withAssertMessage:@"failure block should be called"];
}

/**
 * Checks that a provided @c task returned from a stub @c recorder calls either
 * the @c SuccessBlock or the @c FailureBlock of the operation done in the
 * @c actionBlock. The @c message is used to properly display the expected
 * behavior.
 */
- (void)checkTask:(BFTask *)task
   onStubRecorder:(OCMStubRecorder *)recorder
callsEitherBlockIn:(ActionBlock)actionBlock
withAssertMessage:(NSString *)message {
    [recorder andReturn:task];

    __block BOOL verified = NO;
    void(^blockCallVerifier)(id) = ^(id object) {
        verified = YES;
    };
    // either block should be called
    actionBlock(blockCallVerifier, blockCallVerifier);

    XCTAssertTrue(verified, @"%@", message);
}

/**
 * Checks that a provided @c task returned from a stub @c recorder
 * asynchronously calls either the @c SuccessBlock or the @c FailureBlock of the
 * operation done in the @c actionBlock. The @c message is used to properly
 * display the expected behavior.
 */
- (void)checkTask:(BFTask *)task
   onStubRecorder:(OCMStubRecorder *)recorder
asyncCallsEitherBlockIn:(ActionBlock)actionBlock
withAssertMessage:(NSString *)message {
    [recorder andReturn:task];

    XCTestExpectation *blockCalledExpectation = [self expectationWithDescription:message];
    void(^blockCallVerifier)(id) = ^(id object) {
        [blockCalledExpectation fulfill];
    };
    // either block should be called
    actionBlock(blockCallVerifier, blockCallVerifier);

    [self waitForExpectationsWithTimeout:kDefaultAsyncTestTimeout handler:nil];
}
@end
