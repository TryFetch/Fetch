//
//  Videos.swift
//  Fetch
//
//  Created by Stephen Radford on 10/10/2015.
//  Copyright © 2015 Cocoon Development Ltd. All rights reserved.
//

import UIKit
import Alamofire
import SwiftyJSON
import Downpour

public class Videos {
    
    /// Parsed movies from tmdb
    public var movies: [Movie] = []
    
    /// Parsed tv shows from tmdb
    public var tvShows: [TVShow] = []
    
    /// New movies just found on TMDB
    private var newMovies: [Movie] = []
    
    /// New TV just found on TMDB
    private var newTvShows: [TVShow] = []
    
    /// Movies sorted alphabetically
    public var sortedMovies: [Movie] {
        get {
            return self.movies.sorted(by: { $0.sortableTitle! < $1.sortableTitle! })
        }
    }

    /// TV shows sorted alphabetically
    public var sortedTV: [TVShow] {
        get {
            return self.tvShows.sorted(by: { $0.sortableTitle! < $1.sortableTitle! })
        }
    }
    
    /// The flattened out raw files from put.io
    public var files: [File] = []
    
    /// The old raw files
    public var oldFiles: [File] = []
    
    /// The cached file count
    public var cachedFileCount = 0
    
    /// The shared instances of our lovely video class
    public static let sharedInstance = Videos()
    
    /// Recursive method count
    private var folderCount = 0
    
    /// Search Terms
    private var searches: [String:TMDBSearch] = [:]
    
    private var completed = 0
    
    public var syncing = false
    
    public var completedPercent: Float {
        get {
            return (Float(self.completed) / Float(self.searches.count))
        }
    }
    
    
    // MARK: - Putio
    
    /**
     Start fetching files and folders from Put.io
     */
    public func fetch() {
        
        guard !syncing else {
            print("already syncing")
            return
        }
        
        UIApplication.shared.isNetworkActivityIndicatorVisible = true
        
        syncing = true
        
        // Wipe everything!
        if files.count > 0 || movies.count > 0 || tvShows.count > 0 {
            oldFiles = files
            searches = [:]
            files = []
        }
        
        cachedFileCount = UserDefaults.standard.integer(forKey: "fileCount")
        
        let params = ["oauth_token": "\(Putio.accessToken!)", "start_from": "1"]
        
        Putio.get("files/list", parameters: params) { json, error in
            if let files = json?["files"].array {
                self.recursivelyFetchFiles(files.map(self.parseFile))
            }
        }
        
    }
    
    /**
     Recursively fetch files from the original root results
     
     - parameter files: Files to fetch
     */
    private func recursivelyFetchFiles(_ files: [File]) {
        self.files.append(contentsOf: files)
        for file in files {
            
            if file.is_shared {
                continue
            }
            
            if file.content_type == "application/x-directory" {
                folderCount += 1
                loadSubfolderFromFile(file) { files in
                    self.folderCount -= 1
                    self.recursivelyFetchFiles(files)
                }
            }
        }
        
        UserDefaults.standard.set(self.files.count, forKey: "fileCount")
        
        if cachedFileCount == 0 && folderCount == 0 && movies.count == 0 && tvShows.count == 0 { // This is the first run
            UIApplication.shared.isNetworkActivityIndicatorVisible = false
            print("Finished fetching files")
            NotificationCenter.default.post(NSNotification(name: NSNotification.Name(rawValue: "PutioFinished"), object: self) as Notification)
            convertToSearchTerms()
        } else if folderCount == 0 { // This is a refresh
            UIApplication.shared.isNetworkActivityIndicatorVisible = false
            print("Finished re-fetching files")
            if self.files.count != cachedFileCount {
                print("File count changed!")
                NotificationCenter.default.post(NSNotification(name: NSNotification.Name(rawValue: "PutioFinished"), object: self) as Notification)
                convertToSearchTerms()
            } else {
                syncing = false
                NotificationCenter.default.post(NSNotification(name: NSNotification.Name(rawValue: "TMDBFinished"), object: self) as Notification)
            }
        }
    }
    
    /**
     Load a subfolder by using the parent_id from the file provided
     
     - parameter file:     The folder to fetch
     - parameter callback: Called when Alamofire has finished
     */
    private func loadSubfolderFromFile(_ file: File, callback: @escaping ([File]) -> Void) {
        guard Putio.accessToken != nil else {
            print("Logged out")
            return
        }
        
        let params = ["oauth_token": "\(Putio.accessToken!)", "parent_id": "\(file.id)", "start_from": "1"]
       
        Putio.get("files/list", parameters: params) { json, error in
            if let files = json?["files"].array?.map(self.parseFile) {
                for f in files {
                    f.parent = file
                }
                
                callback(files)
            } else {
                callback([])
            }
        }
    }
    
    /**
     Map JSON to a file
     
     - parameter f: JSON to map
     
     - returns: File
     */
    private func parseFile(f: JSON) -> File {
        let subtitles = ""
        let accessed = ( f["first_accessed_at"].null != nil ) ? false : true
        let start_from = ( f["start_from"].null != nil ) ? 0 : f["start_from"].double!
        let has_mp4 = (f["is_mp4_available"].bool != nil) ? f["is_mp4_available"].bool! : false
        
        let file = File()
        file.id = f["id"].int!
        file.name = f["name"].string!
        file.size = f["size"].int64!
        file.icon = f["icon"].string!
        file.content_type = f["content_type"].string!
        file.has_mp4 = has_mp4
        file.parent_id = f["parent_id"].int!
        file.subtitles = subtitles
        file.accessed = accessed
        file.screenshot = f["screenshot"].string
        file.is_shared = f["is_shared"].bool!
        file.start_from = start_from
        file.created_at = f["created_at"].string
        return file
    }
    
    // MARK: - TMDB
    
    /**
    Convert names to proper search terms
    */
    private func convertToSearchTerms() {
        
        do {
            try Putio.realm.write {
                Putio.realm.deleteAll()
            }
        } catch {
            print("Could not delete all files")
        }
        
        for file in files {
            
            if file.has_mp4 || file.content_type == "video/mp4" {
                
                let d = Downpour(string: file.name!)
  
                if let search = searches[d.title.lowercased()] {
                    search.files.append(file)
                } else {
                    let search = TMDBSearch()
                    search.downpour = d
                    search.files.append(file)
                    searches[d.title.lowercased()] = search
                }
                
            }

        }
        
        print("Searching TMDB")
        searchTMDB()
        
    }
    
    /**
     Search the TMDB
     */
    func searchTMDB() {
        
        folderCount = 0
        TMDB.sharedInstance.requests = 0
        newMovies = []
        newTvShows = []
        
        UIApplication.shared.isNetworkActivityIndicatorVisible = true
        
        for term in searches {
            folderCount += 1
            
            func parseResult(result: (movie: Movie?, tvshow: TVShow?)) {
                
                self.folderCount -= 1
                self.completed += 1
                
                NotificationCenter.default.post(NSNotification(name: NSNotification.Name(rawValue: "TMDBUpdated"), object: self) as Notification)
                
                if let tvshow = result.tvshow {
                    tvshow.files.append(objectsIn: term.1.files)
                    self.newTvShows.append(tvshow)
                    
                    do {
                        try Putio.realm.write {
                            Putio.realm.add(tvshow, update: true)
                        }
                    } catch {
                        print("Could not write tv shows")
                    }
                }
                
                if let movie = result.movie {
                    movie.files.append(objectsIn: term.1.files)
                    self.newMovies.append(movie)
                    
                    do {
                        try Putio.realm.write {
                            Putio.realm.add(movie, update: true)
                        }
                    } catch {
                        print("Could not write movies")
                    }
                }
                
                if self.folderCount == 0 {
                    print("TMDB Search Complete")
                    
                    // Set movies to be the new movies from the fetch/refresh
                    self.movies = self.newMovies
                    self.tvShows = self.newTvShows

                    TMDB.sharedInstance.requests = 0
                    
                    UIApplication.shared.isNetworkActivityIndicatorVisible = false
                    syncing = false
                    
                    // Tell the App it's all done
                    NotificationCenter.default.post(NSNotification(name: NSNotification.Name(rawValue: "TMDBFinished"), object: self) as Notification)
                    
                }
                
            }
            
            if term.1.downpour?.type == .movie {
                TMDB.searchMoviesWithString(term.0, year: term.1.downpour?.year, callback: parseResult)
            } else {
                TMDB.searchTVWithString(term.0, year: term.1.downpour?.year, callback: parseResult)
            }
            
        }
        
    }
    
  
    
    /// Atomically wipe the shared instance
    public func wipe() {
        syncing = false
        tvShows = []
        files = []
        movies = []
        searches = [:]
        UserDefaults.standard.set(0, forKey: "fileCount")
    }

    
}
