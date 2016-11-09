//
//  DirectoryTableViewController.swift
//  Fetch
//
//  Created by Stephen Radford on 18/05/2015.
//  Copyright (c) 2015 Cocoon Development Ltd. All rights reserved.
//

import UIKit
import Alamofire
import SwiftyJSON
import PutioKit

class DirectoryTableViewController: FilesTableViewController {
    
    var file: PutioKit.File!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        title = file.name
        trackingTitle = "All Files"
    }
    
    override func setParams() -> [String : String] {
        return ["oauth_token": "\(Putio.accessToken!)", "parent_id": "\(file!.id)", "start_from": "1"]
    }

}
