//
//  PageViewController.swift
//  Fetch
//
//  Created by Stephen Radford on 19/05/2015.
//  Copyright (c) 2015 Cocoon Development Ltd. All rights reserved.
//

import UIKit
import SafariServices

class PageViewController: UIViewController {
    
    @IBOutlet weak var loginButton: UIButton!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        setupLoginButton()
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
    }
    
    override func preferredStatusBarStyle() -> UIStatusBarStyle {
        return .LightContent
    }
    
    
    // MARK: - Login Button
    
    func setupLoginButton() {
        loginButton.clipsToBounds = true
        loginButton.layer.cornerRadius = 5
        loginButton.contentEdgeInsets = UIEdgeInsets(top: 10, left: 10, bottom: 10, right: 10)
        loginButton.layer.borderColor = UIColor.whiteColor().CGColor
        loginButton.layer.borderWidth = 1
        
        // SELECTED
        loginButton.setTitleColor(UIColor.whiteColor(), forState: .Selected)
    }
    
    
    @IBAction func loginDown(sender: AnyObject) {
        loginButton.backgroundColor = UIColor(white: 1, alpha: 0.2)
    }
    
    @IBAction func loginUp(sender: AnyObject) {
        loginButton.backgroundColor = UIColor.clearColor()
    }
    
    @IBAction func showWebView(sender: AnyObject) {
        performSegueWithIdentifier("showWebView", sender: sender)
    }

}
