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
    
    override var preferredStatusBarStyle : UIStatusBarStyle {
        return .lightContent
    }
    
    
    // MARK: - Login Button
    
    func setupLoginButton() {
        loginButton.clipsToBounds = true
        loginButton.layer.cornerRadius = 5
        loginButton.contentEdgeInsets = UIEdgeInsets(top: 10, left: 10, bottom: 10, right: 10)
        loginButton.layer.borderColor = UIColor.white.cgColor
        loginButton.layer.borderWidth = 1
        
        // SELECTED
        loginButton.setTitleColor(UIColor.white, for: .selected)
    }
    
    
    @IBAction func loginDown(_ sender: AnyObject) {
        loginButton.backgroundColor = UIColor(white: 1, alpha: 0.2)
    }
    
    @IBAction func loginUp(_ sender: AnyObject) {
        loginButton.backgroundColor = UIColor.clear
    }
    
    @IBAction func showWebView(_ sender: AnyObject) {
        performSegue(withIdentifier: "showWebView", sender: sender)
    }

}
