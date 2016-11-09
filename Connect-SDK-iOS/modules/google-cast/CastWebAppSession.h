//
//  CastWebAppSession.h
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

#import <Foundation/Foundation.h>
#import "CastService.h"
#import "WebAppSession.h"
#import "MediaControl.h"
#import "CastServiceChannel.h"


@interface CastWebAppSession : WebAppSession

@property (nonatomic, readonly) CastService *service;
@property (nonatomic) GCKApplicationMetadata *metadata;
@property (nonatomic, readonly) CastServiceChannel *castServiceChannel;

@end
