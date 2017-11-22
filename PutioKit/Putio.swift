//
//  Putio.swift
//  Fetch
//
//  Created by Stephen Radford on 11/09/2015.
//  Copyright © 2015 Cocoon Development Ltd. All rights reserved.
//

import Foundation
import KeychainAccess
@_exported import RealmSwift
import Alamofire
import SwiftyJSON

public class Putio {
    
    /// The reference to the Put.io API
    public static let api = "https://api.put.io/v2/"
    
    /// The client ID used to authenticate with Put.io
    public static let clientId = 2023
    
    /// The keychain we're using
    public static let keychain = Keychain(service: "uk.co.wearecocoon.fetch")
    
    /// The shared realm instance
    public static let realm = try! Realm()
    
    /// The access token stored in keychain after we logged in
    public static var accessToken: String? {
        get {
            return keychain["access_token"]
        }
    }
    
    public static let sharedInstance = Putio()
    
    public var delegate: PutioDelegate?
    
    public static let secret = "1E6p8Mlh9PfGrtZH0UUNArC252FX74FO"
    
    // TODO: Remove as it's now an extension
    public static let accent = UIColor(red:0.98, green:0.77, blue:0.21, alpha:1)
    
    /**
     Helper method to set the network activity indicator. This will only show/hide the indicator on iOS and will silently fail on tvOS.
     
     - parameter yn: Whether to show the indicator or not
     */
    public class func networkActivityIndicatorVisible(_ yn: Bool) {
        #if os(iOS)
            UIApplication.shared.isNetworkActivityIndicatorVisible = yn
        #endif
    }
    
    
    // MARK: - Networking
    
    /**
    Run a GET request to Put.io
    
    - parameter endpoint: The endpoint to call
    - parameter callback: Optional callback
    */
    public class func get(_ endpoint: String, parameters: [String:Any] = [:], callback: ((JSON?, NSError?) -> Void)?) {
        
        self.networkActivityIndicatorVisible(true)
        
        var params = parameters
        params["oauth_token"] = "\(self.accessToken!)" as AnyObject
        
        Alamofire.request("\(self.api)\(endpoint)", method: .get, parameters: params)
            .validate(statusCode: 200..<300)
            .responseJSON { response in
                
                self.networkActivityIndicatorVisible(false)
                
                if let code = response.response?.statusCode, response.result.isFailure {
                    if case 400..<404 = code {
                        Putio.sharedInstance.delegate?.error400Received()
                    }
                }
                
                if let cb = callback {
                    if response.result.error != nil {
                        cb(nil, response.result.error as NSError?)
                    } else if let data = response.result.value {
                        let json = JSON(data)
                        cb(json, nil)
                    } else {
                        cb(nil, nil)
                    }
                }

            }
        
    }
    
    /**
     Run a POST request to Put.io
     
     - parameter endpoint: Endpoint to call
     - parameter callback: Optional callback
     */
    public class func post(_ endpoint: String, callback: ((JSON?, NSError?) -> Void)?) {
        self.post(endpoint, parameters: [:], callback: callback)
    }
    
    /**
     Run a POST request to Put.io with some optional parameters
     
     - parameter endpoint: Endpoint to call
     - parameter params:   Parameters to POST
     - parameter callback: Optional callback
     */
    public class func post(_ endpoint: String, parameters params: [String:Any], callback: ((JSON?, NSError?) -> Void)?) {
        
        var params = params
        
        self.networkActivityIndicatorVisible(true)
        
        params["oauth_token"] = self.accessToken!
        
        Alamofire.request("\(self.api)\(endpoint)", method: .get, parameters: params)
            .validate(statusCode: 200..<300)
            .responseJSON { response in
                
                self.networkActivityIndicatorVisible(false)
                
                if let code = response.response?.statusCode, response.result.isFailure {
                    if case 400..<404 = code {
                        Putio.sharedInstance.delegate?.error400Received()
                    }
                }
                
                if let cb = callback {
                    if response.result.error != nil {
                        cb(nil, response.result.error as NSError?)
                    } else if let data = response.result.value {
                        let json = JSON(data)
                        cb(json, nil)
                    } else {
                        cb(nil, nil)
                    }
                }
                
        }
        
    }
    
}
