//
//  Show.swift
//  Fetch
//
//  Created by Stephen Radford on 10/10/2015.
//  Copyright © 2015 Cocoon Development Ltd. All rights reserved.
//

import Downpour
import RealmSwift
import Alamofire

public class TVShow: Object, MediaType {
    
    // MARK: - Realm Properties
    
    /// The TV Show ID
    public dynamic var id: Int = 0

    /// URL to the poster on the API
    public dynamic var posterURL: String?
    
    /// The name of the TV Show
    public dynamic var title: String?
    
    /// Description of the TV Show
    public dynamic var overview: String?
    
    /// voting average of the tv show
    public dynamic var voteAverage: Float64 = 0
    
    /// TV show genre
    public let genres = List<Genre>()
    
    /// Putio Files
    public let files = List<File>()
    
    /// TV Seasons
    public let seasons = List<TVSeason>()
    
    override public static func primaryKey() -> String? {
        return "id"
    }
    
    
    // MARK: - Non-Realm Properties
    
    override public static func ignoredProperties() -> [String] {
        return ["poster", "delegate", "requests", "completed"]
    }
    
    /// The poster image
    public var poster: UIImage?
    
    public func getPoster(callback: @escaping (UIImage) -> Void) {
        if let url = posterURL {
            Alamofire.request("https://image.tmdb.org/t/p/w500\(url)", method: .get)
                .responseImage { response in
                    if let image = response.result.value {
                        self.poster = image
                        callback(image)
                    } else {
                        self.generatePoster { image in
                            self.poster = image
                            callback(image)
                        }
                    }
            }
            
        } else {
            generatePoster { image in
                self.poster = image
                callback(image)
            }
        }
    }
    
    /// Delegate for the TVShow
    public var delegate: TVShowDelegate?
    
    /// Title to sort alphabetically witout "The"
    public var sortableTitle: String? {
        get {
            if let range = title?.range(of: "The ") {
                if range.lowerBound == title?.startIndex {
                    return title?.replacingCharacters(in: range, with: "")
                }
            }
            return title
        }
    }
    
    var requests = 0
    
    private var completed = 0
    
    public var completedPercent: Float {
        get {
            return (Float(self.completed) / Float(self.files.count))
        }
    }
    
    
    // MARK: - Methods
    
    /**
     Convert the files to TV Episodes
     */
    public func convertFilesToEpisodes() {
        
        guard seasons.count == 0 else {
            self.delegate?.tvEpisodesLoaded()
            return
        }
        
        TMDB.sharedInstance.requests = 0
        
        for file in files {
            
            requests += 1
            
            let d = Downpour(string: file.name!)
            if d.season != nil && d.episode != nil {
                
                TMDB.fetchEpisodeForSeason(d.season!, episode: d.episode!, showId: id) { episode in
                    self.requests -= 1
                    self.completed += 1
                    self.delegate?.percentUpdated()
                    
                    if let ep = episode {
                        
                        ep.file = file
                        
                        if let season = self.seasons.filter({ $0.number == ep.seasonNo }).first {
                            if season.episodes.filter({ $0.id == ep.id }).isEmpty {
                                do {
                                    try Putio.realm.write {
                                        season.episodes.append(ep)
                                    }
                                } catch {
                                    print(error)
                                }
                            }
                        } else {
                            let season = TVSeason()
                            season.id = Int("\(self.id)\(ep.seasonNo)")!
                            season.number = ep.seasonNo
                            season.episodes.append(ep)
                            do {
                                try Putio.realm.write {
                                    self.seasons.append(season)
                                }
                            } catch {
                                print(error)
                            }
                        }
                    
                    }
                    
                    if self.requests == 0 {
                        TMDB.sharedInstance.requests = 0
                        self.delegate?.tvEpisodesLoaded()
                    }
    
                }
            }
            
        }
        
    }
    
}
