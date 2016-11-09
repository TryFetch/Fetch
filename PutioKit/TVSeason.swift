//
//  TVSeason.swift
//  Fetch
//
//  Created by Stephen Radford on 13/10/2015.
//  Copyright © 2015 Cocoon Development Ltd. All rights reserved.
//

import Foundation
import RealmSwift

public class TVSeason: Object {
    
    public dynamic var id: Int = 0
    
    public dynamic var number: Int = 0
    
    /// Episodes of the tv season
    public let episodes = List<TVEpisode>()
    
    override public static func primaryKey() -> String? {
        return "id"
    }
    
}