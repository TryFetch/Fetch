//
//  Genre.swift
//  Fetch
//
//  Created by Stephen Radford on 10/10/2015.
//  Copyright © 2015 Cocoon Development Ltd. All rights reserved.
//

import Foundation
import RealmSwift

public class Genre: Object {
    
    /// The id of the genre
    public dynamic var id: Int = 0
    
    /// The name of the genre
    public dynamic var name: String? = nil
    
    override public static func primaryKey() -> String? {
        return "id"
    }
    
}