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
    public class func registerForPushNotifications(token: Data) {
        
        if let apiToken = Putio.accessToken {
            
            let characterSet = CharacterSet(charactersIn: "<>")
            let deviceToken = token.description
                .trimmingCharacters(in: characterSet)
                .replacingOccurrences(of: " ", with: "")
        
            Alamofire.request("https://ftch.in/api/register-device", method: .post, parameters: ["device": deviceToken, "api": apiToken])
        
        }
        
    }
    
}
