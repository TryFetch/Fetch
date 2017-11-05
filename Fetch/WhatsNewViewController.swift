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
    
    let defaults = UserDefaults.standard
    
    override func viewDidLoad() {
        super.viewDidLoad()
        image.tintColor = .white
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
    /// Show the view controller
    class func show(_ sender: AnyObject?) {
        
        if self.checkVersion() < 1.4 {
            let vc = WhatsNewViewController(nibName: "WhatsNewViewController", bundle: Bundle.main)
            
            let formSheetController = MZFormSheetPresentationViewController(contentViewController: vc)
            formSheetController.presentationController?.contentViewSize = CGSize(width: 300, height: 400)
            formSheetController.contentViewControllerTransitionStyle = MZFormSheetPresentationTransitionStyle.slideFromBottom
            formSheetController.contentViewCornerRadius = 5
            
            formSheetController.view.layer.shadowColor = UIColor.black.cgColor
            formSheetController.view.layer.shadowOffset = CGSize(width: 0, height: 5)
            formSheetController.view.layer.shadowOpacity = 0.4
            formSheetController.view.layer.shadowRadius = 3
            
            formSheetController.presentationController?.shouldCenterVertically = true
            formSheetController.presentationController?.shouldUseMotionEffect = true
            
            sender?.present(formSheetController, animated: true, completion: nil)

            UserDefaults.standard.set(1.4, forKey: "last_version")
        }
        
    }
    
    class func checkVersion() -> Float {
        var version: Float? = UserDefaults.standard.object(forKey: "last_version") as? Float
        
        if version == nil {
            version = 0
        }
        
        return version!
    }
    
    @IBAction func ok(_ sender: AnyObject) {
        dismiss(animated: true, completion: nil)
    }

    
}
