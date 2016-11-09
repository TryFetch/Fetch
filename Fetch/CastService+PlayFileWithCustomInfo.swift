//
//  CastService+PlayFileWithCustomInfo.swift
//  Fetch
//
//  Created by Stephen Radford on 26/08/2015.
//  Copyright (c) 2015 Cocoon Development Ltd. All rights reserved.
//

import UIKit

//extension CastService {
//    
//    func playFileWithCustomInfo(mediaInfo: MediaInfo, shouldLoop: Bool, success: MediaPlayerSuccessBlock, failure: FailureBlock) {
//        
//        let metaData: GCKMediaMetadata = GCKMediaMetadata(metadataType: GCKMediaMetadataType.Movie)
//        metaData.setString(mediaInfo.title, forKey: kGCKMetadataKeyTitle)
//        metaData.setString(mediaInfo.description, forKey: kGCKMetadataKeySubtitle)
//        metaData.setString("\(mediaInfo.subtitleInfo.url.absoluteString!)", forKey: "subtitleUrl")
//        
//        let customData = [
//            "subtitleUrl" : "\(mediaInfo.subtitleInfo.url.absoluteString!)"
//        ]
//        
//        let mediaInformation = GCKMediaInformation(contentID: mediaInfo.url.absoluteString, streamType: GCKMediaStreamType.Buffered, contentType: mediaInfo.mimeType, metadata: metaData, streamDuration: 1000, customData: customData)
//        
//        return playMedia(mediaInformation, webAppId: castWebAppId, success: success, failure: failure)
//        
//    }
//    
//}