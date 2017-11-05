//
//  SettingsNavViewController.swift
//  Fetch
//
//  Created by Stephen Radford on 07/10/2015.
//  Copyright © 2015 Cocoon Development Ltd. All rights reserved.
//

import UIKit

class SettingsNavViewController: UINavigationController {

    override func viewDidLoad() {
        super.viewDidLoad()

        // Do any additional setup after loading the view.
    }
    
    /// Force the status bar to be white
    override var preferredStatusBarStyle : UIStatusBarStyle {
        return .lightContent
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
    override var shouldAutorotate : Bool {
        if visibleViewController!.isKind(of: QRScannerViewController.self) {
            return false
        }
        
        return true
    }
    
    override var supportedInterfaceOrientations : UIInterfaceOrientationMask {
        
        if visibleViewController!.isKind(of: QRScannerViewController.self) {
            return [UIInterfaceOrientationMask.portrait, UIInterfaceOrientationMask.portraitUpsideDown]
        }
        
        return [UIInterfaceOrientationMask.portrait, UIInterfaceOrientationMask.landscape, UIInterfaceOrientationMask.portraitUpsideDown]
        
    }

}
