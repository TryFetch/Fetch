//
//  TMDB.swift
//  Fetch
//
//  Created by Stephen Radford on 11/10/2015.
//  Copyright © 2015 Cocoon Development Ltd. All rights reserved.
//

import UIKit
import Alamofire
import SwiftyJSON

class TMDB {
    
    /// The API URL
    static let api = "http://api.themoviedb.org/3/"
    
    /// The API Key
    static let key = "effc766d4c2565abd1e93fb7f5f7c628"
    
    /// The sharedInstance
    static let sharedInstance = TMDB()
    
    /// The current number of requests
    var requests = 0
    

    
    // MARK: - Search
    
    /**
     Search TMDB for tv with a string
     
     - parameter string: The term to search the databse with
     */
    class func searchTVWithString(_ string: String, year: String?, callback: @escaping ((movie: Movie?, tvshow: TVShow?)) -> Void) {
        
        TMDB.sharedInstance.requests += 1
        
        var params = [
            "api_key" : TMDB.key,
            "query" : string
        ]
        
        if year != nil {
            params["first_air_date_year"] = year!
        }
        
        DispatchQueue.main.asyncAfter(deadline: .now() + Double(TMDB.sharedInstance.requests / 4)) {
            TMDB.sharedInstance.searchWithParams(params, type: "tv") { response in
                callback(response)
            }
        }
        
    }
    
    /**
     Search TMDB for movies with a string
     
     - parameter string: The term to search the databse with
     */
    class func searchMoviesWithString(_ string: String, year: String?, callback: @escaping ((movie: Movie?, tvshow: TVShow?)) -> Void) {
        
        TMDB.sharedInstance.requests += 1
        
        var params = [
            "api_key" : TMDB.key,
            "query" : string
        ]
        
        if year != nil {
            params["year"] = year!
        }
        
        DispatchQueue.main.asyncAfter(deadline: .now() + Double(TMDB.sharedInstance.requests / 4)) {
            TMDB.sharedInstance.searchWithParams(params, type: "movie") { response in
                callback(response)
            }
        }

        
    }
    
    /**
     Search TMDB for movies with a string
     
     - parameter params: The parameters to use with Alamofire
     */
    func searchWithParams(_ params: [String:String], type: String, callback: @escaping ((movie: Movie?, tvshow: TVShow?)) -> Void) {
        
        Alamofire.request("\(TMDB.api)search/\(type)", method: .get, parameters: params)
            .responseJSON { response in
                
                if response.result.isSuccess {
                    
                    let json = JSON(response.result.value!)
                    if let results = json["results"].array {
                        
                        if results.count > 0 && type == "movie" {
                            
                            let movie = Movie()
                            movie.id = results[0]["id"].int!
                            movie.title = results[0]["title"].string
                            movie.backdropURL = results[0]["backdrop_path"].string
                            movie.posterURL = results[0]["poster_path"].string
                            movie.overview = results[0]["overview"].string
                            if let date = results[0]["release_date"].string {
                                let formatter = DateFormatter()
                                formatter.dateFormat = "yyyy-MM-dd"
                                if let parsed = formatter.date(from: date) {
                                    let calendar = Calendar.current
                                    let year = calendar.component(.year, from: parsed)
                                    movie.releaseDate = "\(year)"
                                }
                            }
                            
                            callback((movie, nil))
                            return
                            
                        } else if results.count > 0 && type == "tv" {
                            
                            let tv = TVShow()
                            if let id = results[0]["id"].int {
                                tv.id = id
                            }
                            tv.title = results[0]["name"].string
                            tv.posterURL = results[0]["poster_path"].string
                            tv.overview = results[0]["overview"].string
                            
                            callback((nil, tv))
                            return
                            
                        }
                        
                    }
                    
                }
                
                // should add some kinda retry in
                callback((nil, nil))
                
        }
    }
    
    
    
    // MARK: - TV Shows
    
    /**
    Fetch the TV Season from TMDB
    
    - parameter season:   The season on the tv show
    - parameter episode:  The episode on the tv show
    - parameter showId:   ID of the TV Show
    - parameter callback: Called when TV Season is fetched
    */
    class func fetchEpisodeForSeason(_ season: String, episode: String, showId: Int, callback: @escaping (TVEpisode?) -> Void) {
        
        TMDB.sharedInstance.requests += 1
        
        let params = [
            "api_key" : TMDB.key
        ]
        
        DispatchQueue.main.asyncAfter(deadline: .now() + Double(TMDB.sharedInstance.requests / 4)) {
            
            Alamofire.request("\(TMDB.api)tv/\(showId)/season/\(season)/episode/\(episode)", method: .get, parameters: params)
                .responseJSON { response in
                    
                    if response.result.isSuccess {
                        let json = JSON(response.result.value!)
                        
                        let ep = TVEpisode()
                        if let season = json["season_number"].int {
                            ep.seasonNo = season
                        }
                        if let episode = json["episode_number"].int {
                            ep.episodeNo = episode
                        }
                        ep.title = json["name"].string
                        ep.overview = json["overview"].string
                        ep.stillURL = json["still_path"].string
                        if let id = json["id"].int {
                            ep.id = id
                        }
                        ep.airDate = json["air_date"].string
                        callback(ep)
                        return
                    }
                    
                    callback(nil)
                    
            }
            
        }
        
    }
    
}
