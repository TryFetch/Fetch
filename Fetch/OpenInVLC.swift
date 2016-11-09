//
//  OpenInVLC.swift
//  Fetch
//
//  Created by Stephen Radford on 21/08/2015.
//  Copyright (c) 2015 Cocoon Development Ltd. All rights reserved.
//

import UIKit

class OpenInVLC: UIActivity {
   
    override func activityType() -> String? {
        return "SROpenInVLC"
    }
    
    override func activityTitle() -> String? {
        return "Open In VLC"
    }
    
    override func activityImage() -> UIImage? {
        
        if UIDevice.currentDevice().userInterfaceIdiom == .Pad {
            return UIImage(named: "vlc-ipad")
        }
        
        return UIImage(named: "vlc-iphone")
    }
    
    override func canPerformWithActivityItems(activityItems: [AnyObject]) -> Bool {
        let url: NSURL = activityItems[0] as! NSURL
        let converted = NSURL(string: "vlc://\(url)")!
        return UIApplication.sharedApplication().canOpenURL(converted)
    }
    
    override class func activityCategory() -> UIActivityCategory {
        return .Action
    }
    
    override func prepareWithActivityItems(activityItems: [AnyObject]) {
        for item in activityItems {
            let url: NSURL = item as! NSURL
            let converted = NSURL(string: "vlc://\(url)")!
            UIApplication.sharedApplication().openURL(converted)
        }
    }
    
}
