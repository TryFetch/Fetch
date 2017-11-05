//
//  Search.swift
//  Fetch
//
//  Created by Stephen Radford on 08/08/2015.
//  Copyright (c) 2015 Cocoon Development Ltd. All rights reserved.
//

import UIKit
import RealmSwift

public class Search {

    /// The search term
    public let term: String
    
    /// The search delegate
    public var delegate: SearchDelegate?
    
    /// Search results
    public var results: [File] = []
    
    public init(term: String) {
        self.term = term
    }
    
    /// Search Put.io
    public func search(sender: UIViewController) {
        let t = term.addingPercentEscapes(using: .utf8)
        Files.fetchWithURL("\(Putio.api)files/search/\(t!)/page/-1", params: ["oauth_token": "\(Putio.accessToken!)"], sender: sender) { files in
            self.results = files
            self.delegate?.searchCompleted(results: self.results)
        }
        
    }
    

}
