//
//  OpenInVLC.swift
//  Fetch
//
//  Created by Stephen Radford on 21/08/2015.
//  Copyright (c) 2015 Cocoon Development Ltd. All rights reserved.
//

import UIKit

class OpenInVLC: UIActivity {
    
    override var activityType: UIActivityType? {
        return UIActivityType(rawValue: "SROpenInVLC")
    }
   
    override var activityTitle: String? {
        return "Open In VLC"
    }
    
    override var activityImage: UIImage? {
        if UIDevice.current.userInterfaceIdiom == .pad {
            return UIImage(named: "vlc-ipad")
        }
        
        return UIImage(named: "vlc-iphone")
    }
    
    override func canPerform(withActivityItems activityItems: [Any]) -> Bool {
        let url: URL = activityItems[0] as! URL
        let converted = URL(string: "vlc://\(url)")!
        return UIApplication.shared.canOpenURL(converted)
    }
    
    override func prepare(withActivityItems activityItems: [Any]) {
        for item in activityItems {
            let url: URL = item as! URL
            let convert = URL(string: "vlc://\(url)")!
            UIApplication.shared.openURL(convert)
        }
    }
    
//
//
//    override class func activityCategory() -> UIActivityCategory {
//        return .Action
//    }
//
    
}
