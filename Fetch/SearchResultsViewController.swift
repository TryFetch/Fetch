//
//  SearchResultsViewController.swift
//  Fetch
//
//  Created by Stephen Radford on 08/08/2015.
//  Copyright (c) 2015 Cocoon Development Ltd. All rights reserved.
//

import UIKit
import PutioKit

class SearchResultsViewController: FilesTableViewController, SearchDelegate {

    var search: Search?
    
    override func viewDidLoad() {
        super.viewDidLoad()
        search?.delegate = self
        title = search!.term
    }
    
    override func fetchFiles() {
        search?.search(self)
    }
    
    override func refresh(sender: UIRefreshControl) {
        refreshControl?.beginRefreshing()
        fetchFiles()
    }
    
    /// Search results have come back, now we can sing hallelu!
    func searchCompleted(results results: [PutioKit.File]) {
        files = results
        
        tableView.reloadData()
        refreshControl?.endRefreshing()
        overlay?.hideWithAnimation()
        
        if files.count == 0 {
            noFiles!.hidden = false
        } else {
            noFiles!.hidden = true
        }

    }
}
