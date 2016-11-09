//
//  PushNotifications.swift
//  Fetch
//
//  Created by Stephen Radford on 12/03/2016.
//  Copyright © 2016 Cocoon Development Ltd. All rights reserved.
//

import Alamofire

extension Putio {
    
    /**
     Register the device token for Push notifications with the ftch.in service
     
     - parameter token: The device token
     */
    public class func registerForPushNotifications(token: NSData) {
        
        if let apiToken = Putio.accessToken {
            
            let characterSet = NSCharacterSet( charactersInString: "<>" )
            let deviceToken = (token.description as NSString)
                .stringByTrimmingCharactersInSet(characterSet)
                .stringByReplacingOccurrencesOfString(" ", withString: "") as String
        
            Alamofire.request(.POST, "https://ftch.in/api/register-device", parameters: ["device": deviceToken, "api": apiToken])
        
        }
        
    }
    
}
