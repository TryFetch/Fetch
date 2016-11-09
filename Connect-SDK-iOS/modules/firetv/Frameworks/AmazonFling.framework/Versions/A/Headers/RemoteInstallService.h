/**
 * RemoteInstallService.h
 *
 * Copyright (c) 2015 Amazon Technologies, Inc. All rights reserved.
 *
 * PROPRIETARY/CONFIDENTIAL
 *
 * Use is subject to license terms.
 */

#import <Foundation/Foundation.h>
#import <Bolts/BFTask.h>

/**
 Constant returned by the install service on the Fire TV to convey that 
 the requested package is not installed on that Fire TV.
 */
FOUNDATION_EXPORT NSString* const RIS_PACKAGE_NOT_INSTALLED;

/**
  Simple representation of a remote device's install service
 */
@protocol RemoteInstallService

/**
  Returns the remote device's display name.
 */
- (NSString*) name;

/**
  Returns a unique id (UUID) for the remote device.
 */
- (NSString*) uniqueIdentifier;

/**
 Returns a version string for the provided package, or string literal
 variable RIS_PACKAGE_NOT_INSTALLED if not installed.
 @param packageName - Platform specific application package name
 @return BFTask (NSString*)result from asynchronous calling
 */
-(BFTask *) getInstalledPackageVersion:(NSString*) packageName;

/**
 Invokes the platform specific application used to acquire and install
 a product. This may require user interaction to complete.
 @param asin Unique product identifier used to specify a specific 
        application that can acquired, an Amazon Standard Identification 
        Number(ASIN)
 @return BFTask (void)result from asynchronous calling
 */
-(BFTask *) installByASIN:(NSString*) asin;

@end
