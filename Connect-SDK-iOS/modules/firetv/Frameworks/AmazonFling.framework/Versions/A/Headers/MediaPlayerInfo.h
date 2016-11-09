/**
 *  MediaInfo.h
 *
 * Copyright (c) 2015 Amazon Technologies, Inc. All rights reserved.
 *
 * PROPRIETARY/CONFIDENTIAL
 *
 * Use is subject to license terms.
 */

/**
 This class holds all the relevant information about the currently playing media clip.
 */
@interface MediaPlayerInfo : NSObject {
    /**
     The uniqueId of the media clip being played. Mostly the URL, but depends on the API usage.
     */
    NSString* _source;

    /**
     Metadata of the media clip. The controller application sets this as a JSON string when calling the
     setMediaSource method.
     */
    NSString* _metadata;

    /**
     This field can be used by the API consumer to extend media information to hold application
     specific information. This field should be a JSON string.
     */
    NSString* _extra;
}

/**
 Initializes the object with provided uniqueId and metadata.
 @param source The initial value of the uniqueId property.
 @param metadata The initial value of the metadata property.
 @param extra This initial value of the extra information.
 */
- (MediaPlayerInfo*) initWithSource : (NSString*) source
                           metaData : (NSString*) metadata
                           andExtra : (NSString*) extra;

/**
 Get accessor for source.
 */
- (NSString*) source;

/**
 Get accessor for Metadata.
 */
- (NSString*) metadata;

/**
 Get accessor for extra.
 */
- (NSString*) extra;

@end
