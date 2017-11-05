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
    let oneP = OnePasswordExtension.shared()
    
    @IBOutlet weak var urlBtn: UIButton!

    override func viewDidLoad() {
        super.viewDidLoad()
        
        webView.delegate = self
        
        createOnePasswordBtn()
        clearCookies()
        
        let url = URL(string: "https://api.put.io/v2/oauth2/authenticate?client_id=2023&response_type=code&redirect_uri=http://getfetchapp.com/authenticate")!
        let request = URLRequest(url: url)
        webView?.loadRequest(request)
    }
    
    override var preferredStatusBarStyle : UIStatusBarStyle {
        return .lightContent
    }
    
    // MARK: - Actions
    
    @IBAction func closeView(_ sender: AnyObject) {
        dismiss(animated: true, completion: nil)
    }
    

    // MARK: - UIWebViewDelegate
    
    
    func webViewDidStartLoad(_ webView: UIWebView) {
        print(webView.request?.url)
        UIApplication.shared.isNetworkActivityIndicatorVisible = true
    }
    
    func webViewDidFinishLoad(_ webView: UIWebView) {
        
        UIApplication.shared.isNetworkActivityIndicatorVisible = false
        
        let url = webView.request?.mainDocumentURL
        let urlString = url!.absoluteString
        
        if(urlString.range(of: "http://getfetchapp.com/authenticate/success.php") != nil) {
            
            let accessToken = url?.query!.replacingOccurrences(of: "access_token=", with: "", options: [], range: nil)
            
            Putio.keychain.updateIfNeeded("access_token", value: accessToken)
            
            let pc = self.presentingViewController
            let sb = UIStoryboard(name: "Main", bundle: nil)
            let vc: UITabBarController = sb.instantiateInitialViewController() as! UITabBarController
            
            self.dismiss(animated: true, completion: {
                pc!.present(vc, animated: true, completion: nil)
            })
            
        }
        
    }
    
    // MARK: - Cookies
    
    func clearCookies() {
        let storage: HTTPCookieStorage = HTTPCookieStorage.shared
        for cookie in storage.cookies! {
            storage.deleteCookie(cookie)
        }
    }
    
    // MARK: - 1Password
    
    func createOnePasswordBtn() {
        
        if oneP.isAppExtensionAvailable() {
            navigationItem.rightBarButtonItem = UIBarButtonItem(image: UIImage(named: "onepassword-navbar-light"), style: .plain, target: self, action: #selector(loginWithOnePassword))
        }
        
    }
    
    func loginWithOnePassword(_ sender: AnyObject) {
        oneP.fillItem(intoWebView: webView, for: self, sender: sender, showOnlyLogins: true) { completed, error in
            print(error)
        }
    }

}
