//
//  Movie.swift
//  Fetch
//
//  Created by Stephen Radford on 10/10/2015.
//  Copyright © 2015 Cocoon Development Ltd. All rights reserved.
//

import UIKit
import RealmSwift
import Alamofire
import AlamofireImage

public class Movie: Object, MediaType {
    
    public dynamic var id: Int = 0
    
    /// URL to the backdrop on the API
    public dynamic var backdropURL: String?
    
    /// URL to the poster on the API
    public dynamic var posterURL: String?
    
    public dynamic var title: String?
    
    public let genres = List<Genre>()
    
    public dynamic var overview: String?
    
    public dynamic var releaseDate: String?
    
    public dynamic var runtime: Float64 = 0

    public dynamic var tagline: String?
    
    public dynamic var voteAverage: Float64 = 0
    
    /// Putio Files
    public let files = List<File>()
    
    override public static func primaryKey() -> String? {
        return "id"
    }
    
    
    // MARK: - Non-realm
    
    public var poster: UIImage?
    
    /// Title to sort alphabetically witout "The"
    public var sortableTitle: String? {
        get {
            if let range = title?.range(of: "The "), range.lowerBound == title?.startIndex {
                return title?.replacingCharacters(in: range, with: "")
            }
            return title
        }
    }
    
    override public static func ignoredProperties() -> [String] {
        return ["poster"]
    }
    
}
