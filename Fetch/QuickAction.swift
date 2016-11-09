//
//  QuickActions.swift
//  Fetch
//
//  Created by Stephen Radford on 25/03/2016.
//  Copyright © 2016 Cocoon Development Ltd. All rights reserved.
//

import UIKit

enum QuickAction: String {
    case Search = "uk.co.wearecocoon.Fetch.Search"
    case AddFiles = "uk.co.wearecocoon.Fetch.AddFiles"
    case Downloads = "uk.co.wearecocoon.Fetch.Downloads"
    case Activity = "uk.co.wearecocoon.Fetch.Activity"
    
    static func handleAction(action: QuickAction, callback: (Bool) -> Void) {
        
        guard let window = UIApplication.sharedApplication().delegate?.window! else {
            callback(false)
            return
        }
        
        guard let tabs = window.rootViewController as? FilesTabViewController else {
            callback(false)
            return
        }
        
        switch action {
            
            case .Downloads:
            
                tabs.selectedIndex = 3
                if let navController = tabs.viewControllers?[3] as? UINavigationController {
                    navController.popToRootViewControllerAnimated(false)
                    if let moreController = navController.childViewControllers[0] as? MoreTableViewController {
                        moreController.performSegueWithIdentifier("showDownloads", sender: moreController)
                    }
                }
                
                break
        
            case .Activity:
            
                tabs.selectedIndex = 3
                if let navController = tabs.viewControllers?[3] as? UINavigationController {
                    navController.popToRootViewControllerAnimated(false)
                    if let moreController = navController.childViewControllers[0] as? MoreTableViewController {
                        moreController.performSegueWithIdentifier("showActivity", sender: moreController)
                    }
                }
                
                break
            
            case .Search:
            
                tabs.selectedIndex = 1
                if let navController = tabs.viewControllers?[1] as? UINavigationController {
                    navController.popToRootViewControllerAnimated(false)
                    if let filesController = navController.childViewControllers[0] as? AllFilesTableViewController {
                        let delayTime = dispatch_time(DISPATCH_TIME_NOW, Int64(0.5 * Double(NSEC_PER_SEC)))
                        dispatch_after(delayTime, dispatch_get_main_queue()) {
                            filesController.searchBar.becomeFirstResponder()
                        }
                    }
                }
            
                break
            
            case .AddFiles:
            
                tabs.selectedIndex = 2
                if let split = tabs.viewControllers?[2] as? UISplitViewController {
                    if let navController = split.childViewControllers[0] as? UINavigationController {
                        navController.popToRootViewControllerAnimated(false)
                        if let transfers = navController.childViewControllers[0] as? TransfersTableViewController {
                            transfers.performSegueWithIdentifier("addTransfer", sender: transfers)
                        }
                    }
                }
            
            break
            
        }
        
        
    }
    
}
