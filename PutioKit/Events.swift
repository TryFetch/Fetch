//
//  Events.swift
//  Fetch
//
//  Created by Stephen Radford on 08/01/2016.
//  Copyright © 2016 Cocoon Development Ltd. All rights reserved.
//

import Foundation

public class Events {
    
    public class func get(callback: @escaping ([Date: [Event]], NSError?) -> Void) {
        
        Putio.get("events/list") { json, error in
            
            var sorted = [Date: [Event]]()
            if let j = json {
                
                if let rawEvents = j["events"].array {
                    let events: [Event] = rawEvents.map { e in
                        let event = Event()
                        
                        if let type = e["type"].string {
                            switch type {
                                case "zip_created":
                                    event.name = "You requested we zip some files and they are ready"
                                    event.type = .ZipCreated
                                    event.fileID = e["file_id"].int32
                                case "transfer_from_rss_error":
                                    event.name = e["transfer_name"].string
                                    event.type = .TransferFromRSSError
                                case "file_shared":
                                    event.name = e["file_name"].string
                                    event.type = .FileShared
                                    event.fileID = e["file_id"].int32
                                default:
                                    event.name = e["transfer_name"].string
                                    event.type = .TransferCompleted
                                    event.fileID = e["file_id"].int32
                            }
                        } else {
                            event.name = e["transfer_name"].string
                            event.type = .TransferFromRSSError
                        }
                        
                        event.createdAt = e["created_at"].string
                        
                        return event
                    }
                    
                    
                    let formatter = DateFormatter()
                    formatter.dateFormat = "dd/MM/yyyy"
                    for event in events {
                        if let date = event.date {
                            let dateString = formatter.string(from: date as Date)
                            let newDate = formatter.date(from: dateString)!
                            if sorted[newDate] == nil {
                                sorted[newDate] = []
                            }
                            sorted[newDate]!.append(event)
                        }
                    }
                    
                }
                
                callback(sorted, nil)
            
            } else {
                callback(sorted, error)
            }
        }
        
    }
    
    public class func clear(callback: @escaping () -> Void) {
        Putio.post("events/delete") { json, error in
            callback()
        }
    }
    
}
