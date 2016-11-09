//
//  WhatsNewViewController.swift
//  Fetch
//
//  Created by Stephen Radford on 07/08/2015.
//  Copyright (c) 2015 Cocoon Development Ltd. All rights reserved.
//

import UIKit
import MZFormSheetPresentationController

class WhatsNewViewController: UIViewController {

    @IBOutlet weak var topSection: UIView!
    @IBOutlet weak var image: UIImageView!
    
    let defaults = NSUserDefaults.standardUserDefaults()
    
    override func viewDidLoad() {
        super.viewDidLoad()
        image.tintColor = .whiteColor()
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
    /// Show the view controller
    class func show(sender: AnyObject?) {
        
        if self.checkVersion() < 1.4 {
            let vc = WhatsNewViewController(nibName: "WhatsNewViewController", bundle: NSBundle.mainBundle())
            
            let formSheetController = MZFormSheetPresentationViewController(contentViewController: vc)
            formSheetController.presentationController?.contentViewSize = CGSizeMake(300, 400)
            formSheetController.contentViewControllerTransitionStyle = MZFormSheetPresentationTransitionStyle.SlideFromBottom
            formSheetController.contentViewCornerRadius = 5
            
            formSheetController.view.layer.shadowColor = UIColor.blackColor().CGColor
            formSheetController.view.layer.shadowOffset = CGSize(width: 0, height: 5)
            formSheetController.view.layer.shadowOpacity = 0.4
            formSheetController.view.layer.shadowRadius = 3
            
            formSheetController.presentationController?.shouldCenterVertically = true
            formSheetController.presentationController?.shouldUseMotionEffect = true
            
            sender?.presentViewController(formSheetController, animated: true, completion: nil)

            NSUserDefaults.standardUserDefaults().setFloat(1.4, forKey: "last_version")
        }
        
    }
    
    class func checkVersion() -> Float {
        var version: Float? = NSUserDefaults.standardUserDefaults().objectForKey("last_version") as? Float
        
        if version == nil {
            version = 0
        }
        
        return version!
    }
    
    @IBAction func ok(sender: AnyObject) {
        dismissViewControllerAnimated(true, completion: nil)
    }

    
}
