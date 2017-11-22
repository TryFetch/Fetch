//
//  Event.swift
//  Fetch
//
//  Created by Stephen Radford on 08/01/2016.
//  Copyright © 2016 Cocoon Development Ltd. All rights reserved.
//

import Foundation

public class Event {
    
    /// The text that is shown on the event
    public var name: String?
    
    /// The type of event this is. We should probably show different icons etc. for this
    public var type: EventType?
    
    /// When was the event created
    public var createdAt: String? {
        didSet {
            if let string = createdAt {
                let formatter = DateFormatter()
                formatter.dateFormat = "yyyy-MM-dd HH:mm:s"
                date = formatter.date(from: string)
            }
        }
    }
    
    /// Parsed NSDate when the event was created
    public var date: Date?
    
    /// The ID of the file that this event relates to
    public var fileID: Int32?
    
}

public enum EventType {
    case TransferCompleted
    case FileShared
    case TransferFromRSSError
    case ZipCreated
}
