//
//  LoginViewController.swift
//  Fetch
//
//  Created by Stephen Radford on 17/05/2015.
//  Copyright (c) 2015 Cocoon Development Ltd. All rights reserved.
//

import UIKit
import KeychainAccess
import SwiftyJSON
import OnePasswordExtension
import PutioKit

class LoginViewController: UIViewController, UIWebViewDelegate {

    @IBOutlet var webView: UIWebView!
    @IBOutlet weak var logo: UIImageView!
    
    @IBOutlet weak var activityView: UIActivityIndicatorView!
    let oneP = OnePasswordExtension.sharedExtension()
    
    @IBOutlet weak var urlBtn: UIButton!

    override func viewDidLoad() {
        super.viewDidLoad()
        
        webView.delegate = self
        
        createOnePasswordBtn()
        clearCookies()
        
        let url = NSURL(string: "https://api.put.io/v2/oauth2/authenticate?client_id=2023&response_type=code&redirect_uri=http://getfetchapp.com/authenticate")!
        let request = NSURLRequest(URL: url)
        webView?.loadRequest(request)
    }
    
    override func preferredStatusBarStyle() -> UIStatusBarStyle {
        return .LightContent
    }
    
    // MARK: - Actions
    
    @IBAction func closeView(sender: AnyObject) {
        dismissViewControllerAnimated(true, completion: nil)
    }
    

    // MARK: - UIWebViewDelegate
    
    
    func webViewDidStartLoad(webView: UIWebView) {
        print(webView.request?.URL)
        UIApplication.sharedApplication().networkActivityIndicatorVisible = true
    }
    
    func webViewDidFinishLoad(webView: UIWebView) {
        
        UIApplication.sharedApplication().networkActivityIndicatorVisible = false
        
        let url = webView.request?.mainDocumentURL
        let urlString = url!.absoluteString
        
        if(urlString!.rangeOfString("http://getfetchapp.com/authenticate/success.php") != nil) {
            
            let accessToken = url?.query!.stringByReplacingOccurrencesOfString("access_token=", withString: "", options: [], range: nil)
            
            
            
            Putio.keychain["access_token"] = accessToken
            
            let pc = self.presentingViewController
            let sb = UIStoryboard(name: "Main", bundle: nil)
            let vc: UITabBarController = sb.instantiateInitialViewController() as! UITabBarController
            
            self.dismissViewControllerAnimated(true, completion: {
                pc!.presentViewController(vc, animated: true, completion: nil)
            })
            
        }
        
    }
    
    // MARK: - Cookies
    
    func clearCookies() {
        let storage: NSHTTPCookieStorage = NSHTTPCookieStorage.sharedHTTPCookieStorage()
        for cookie in storage.cookies! {
            storage.deleteCookie(cookie)
        }
    }
    
    // MARK: - 1Password
    
    func createOnePasswordBtn() {
        
        if oneP.isAppExtensionAvailable() {
            navigationItem.rightBarButtonItem = UIBarButtonItem(image: UIImage(named: "onepassword-navbar-light"), style: .Plain, target: self, action: #selector(loginWithOnePassword))
        }
        
    }
    
    func loginWithOnePassword(sender: AnyObject) {
        oneP.fillItemIntoWebView(webView, forViewController: self, sender: sender, showOnlyLogins: true) { completed, error in
            print(error)
        }
    }

}
