//
//  AllFilesTableViewController.swift
//  Fetch
//
//  Created by Stephen Radford on 13/03/2016.
//  Copyright © 2016 Cocoon Development Ltd. All rights reserved.
//

import UIKit
import PutioKit

class AllFilesTableViewController: FilesTableViewController, UISearchBarDelegate {

    @IBOutlet weak var searchBar: UISearchBar!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        searchBar.delegate = self
        tableView.contentOffset = CGPointMake(0, 44)
    }
    
    func searchBarSearchButtonClicked(searchBar: UISearchBar) {
        let search = Search(term: searchBar.text!)
        let searchResultsVC = UIStoryboard(name: "Main", bundle: nil).instantiateViewControllerWithIdentifier("Search Results") as! SearchResultsViewController
        searchResultsVC.search = search
        navigationController?.pushViewController(searchResultsVC, animated: true)
    }
    
}
