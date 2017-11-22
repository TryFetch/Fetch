//
//  Episode.swift
//  Fetch
//
//  Created by Stephen Radford on 10/10/2015.
//  Copyright © 2015 Cocoon Development Ltd. All rights reserved.
//

import Alamofire
import AlamofireImage
import RealmSwift

public class TVEpisode: Object {
    
    /// the tmdb ID
    public dynamic var id: Int = 0
    
    /// the epsiode number in the tv series
    public dynamic var episodeNo: Int = 0
    
    /// the title of the episode
    public dynamic var title: String?
    
    /// the description of the episode
    public dynamic var overview: String?
    
    /// the season the episode is in
    public dynamic var seasonNo: Int = 0
    
    /// link to the sill
    public dynamic var stillURL: String?
    
    /// Original Air date
    public dynamic var airDate: String?
    
    /// the putio file accompanying this tv episode
    public dynamic var file: File?
    
    override public static func primaryKey() -> String? {
        return "id"
    }
    
    // MARK: Non-Realm
    
    var screenshot: UIImage?
    
    override public static func ignoredProperties() -> [String] {
        return ["screenshot"]
    }
    
    // MARK: Methods
    
    public func getScreenshot(callback: @escaping (UIImage) -> Void) {
        
        if let image = screenshot {
            callback(image)
        } else if let url = (stillURL != nil) ? "https://image.tmdb.org/t/p/w780\(stillURL!)" : file?.screenshot {
            Alamofire.request(url, method: .get)
                .responseImage { response in
                    if let image = response.result.value {
                        self.screenshot = image
                        callback(image)
                    }
                }
        }
        
    }
    
}
