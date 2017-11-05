//
//  Feed.swift
//  Fetch
//
//  Created by Stephen Radford on 08/01/2016.
//  Copyright © 2016 Cocoon Development Ltd. All rights reserved.
//

import UIKit
import Alamofire

public class Feed {
    
    public var id: Int?
    
    public var title: String?
    
    public var paused: Bool?
    
    /**
     Pause the feed and cease automatic downloading of files
     */
    public func pause() {
        if let id = self.id {
            Putio.post("rss/\(id)/pause", callback: nil)
        }
    }
    
    /**
     Resume the feed and continue automatic downloading of files
     */
    public func resume() {
        if let id = self.id {
            Putio.post("rss/\(id)/resume", callback: nil)
        }
    }
    
    /**
     Delete the feed
     */
    public func delete() {
        if let id = self.id {
            Putio.post("rss/\(id)/delete", callback: nil)
        }
    }
    
}
