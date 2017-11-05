//
//  FilesNavViewController.swift
//  Fetch
//
//  Created by Stephen Radford on 24/05/2015.
//  Copyright (c) 2015 Cocoon Development Ltd. All rights reserved.
//

import UIKit

class FilesNavViewController: UINavigationController {


    override func viewDidLoad() {
        super.viewDidLoad()
    }
    
    
    /// Force the status bar to be white
    override var preferredStatusBarStyle : UIStatusBarStyle {
        return .lightContent
    }

    
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }


}
