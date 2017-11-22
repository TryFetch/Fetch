//
//  SearchDelegate.swift
//  Fetch
//
//  Created by Stephen Radford on 08/08/2015.
//  Copyright (c) 2015 Cocoon Development Ltd. All rights reserved.
//

import Foundation

public protocol SearchDelegate {
    
    /// Called when the search has been completed
    func searchCompleted(_ results: [File])
    
}
