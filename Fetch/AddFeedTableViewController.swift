//
//  AddFeedTableViewController.swift
//  Fetch
//
//  Created by Stephen Radford on 08/01/2016.
//  Copyright © 2016 Cocoon Development Ltd. All rights reserved.
//

import UIKit

class AddFeedTableViewController: UITableViewController {

    override func viewDidLoad() {
        super.viewDidLoad()

        // Uncomment the following line to preserve selection between presentations
        // self.clearsSelectionOnViewWillAppear = false

        // Uncomment the following line to display an Edit button in the navigation bar for this view controller.
        // self.navigationItem.rightBarButtonItem = self.editButtonItem()
    }
    
    // MARK: - Actions
    
    @IBAction func close(_ sender: AnyObject) {
        dismiss(animated: true, completion: nil)
    }

    @IBAction func save(_ sender: AnyObject) {
        dismiss(animated: true, completion: nil)
    }
    
}
