//
//  XCTestCase+TaskTests.h
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

#import "XCTestCase+Common.h"

@class BFTask;

/**
 * A category with a few convenience methods for tests using @c BFTask.
 * It may not be very clear what these methods do based on the documentation, so
 * please check the usage examples in tests.
 */
@interface XCTestCase (TaskTests)

/**
 * Checks that a successful void task returned from a stub @c recorder calls the
 * @c SuccessBlock of the operation done in the @c block.
 */
- (void)checkTaskSuccessOnStubRecorder:(OCMStubRecorder *)recorder
      shouldCallSuccessBlockUsingBlock:(ActionBlock)block;
/**
 * Checks that a provided successful @c task returned from a stub @c recorder
 * calls the @c SuccessBlock of the operation done in the @c block.
 */
- (void)checkTaskSuccess:(BFTask *)task
          onStubRecorder:(OCMStubRecorder *)recorder
shouldCallSuccessBlockUsingBlock:(ActionBlock)block;
/**
 * Checks that an error task returned from a stub @c recorder calls the
 * @c FailureBlock of the operation done in the @c block.
 */
- (void)checkTaskErrorOnStubRecorder:(OCMStubRecorder *)recorder
    shouldCallFailureBlockUsingBlock:(ActionBlock)block;

/**
 * Checks that a successful void task returned from a stub @c recorder
 * asynchronously calls the @c SuccessBlock of the operation done in the
 * @c block.
 */
- (void)checkTaskSuccessOnStubRecorder:(OCMStubRecorder *)recorder
 shouldAsyncCallSuccessBlockUsingBlock:(ActionBlock)block;

/// Returns a @c BFTask with an @c NSError.
- (BFTask *)errorTask;

@end
