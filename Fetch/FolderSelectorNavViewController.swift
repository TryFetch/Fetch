//
//  FolderSelectorNavViewController.swift
//  Fetch
//
//  Created by Stephen Radford on 15/08/2015.
//  Copyright (c) 2015 Cocoon Development Ltd. All rights reserved.
//

import UIKit

class FolderSelectorNavViewController: UINavigationController {

    /// The view that we'll shove over the top of the nav bar
    var whichView: WhichFolderView!
    
    var border: CALayer!
    
    var gradOverlay: GradientOverlay!
    
    override func viewDidLoad() {
        super.viewDidLoad()

        let navBar = navigationBar
        whichView = WhichFolderView(frame: CGRect(x: 0, y: 0, width: navBar.frame.width, height: navBar.frame.height))
        whichView.autoresizingMask = [.flexibleWidth, .flexibleHeight]
        navBar.addSubview(whichView)
        
        whichView.layer.zPosition = 20
        
        border = CALayer()
        border.frame = CGRect(x: 0, y: 0, width: navBar.frame.width, height: 1)
        border.backgroundColor = UIColor(hue:0, saturation:0, brightness:0.27, alpha:1).cgColor
        border.zPosition = 21
        
        navBar.layer.addSublayer(border)
        
        
        gradOverlay = GradientOverlay(frame: CGRect.zero)
        view.addSubview(gradOverlay)
        
    }
    
    override func viewDidLayoutSubviews() {
        whichView.layoutIfNeeded()
        border.frame = CGRect(x: 0, y: 0, width: navigationBar.frame.width, height: 0.8)
        gradOverlay.frame = CGRect(x: 0, y: navigationBar.frame.height+1, width: view.frame.width, height: view.frame.height-navigationBar.frame.height-1)
        
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    

    /*
    // MARK: - Navigation

    // In a storyboard-based application, you will often want to do a little preparation before navigation
    override func prepareForSegue(segue: UIStoryboardSegue, sender: AnyObject?) {
        // Get the new view controller using segue.destinationViewController.
        // Pass the selected object to the new view controller.
    }
    */

}
