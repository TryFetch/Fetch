//
//  UIColor+Colors.swift
//  Fetch
//
//  Created by Stephen Radford on 12/12/2015.
//  Copyright © 2015 Cocoon Development Ltd. All rights reserved.
//

import Foundation

extension UIColor {
    
    class func fetchYellow() -> UIColor {
        return UIColor(red:0.91, green:0.7, blue:0.16, alpha:1)
    }
    
    class func fetchBackground() -> UIColor {
        return UIColor(hue: 0, saturation: 0, brightness: 0.14, alpha: 1)
    }
    
    class func fetchLighterBackground() -> UIColor {
        return UIColor(hue: 0, saturation: 0, brightness: 0.22, alpha: 1)
    }
    
    class func fetchGreyText() -> UIColor {
        return UIColor(red:0.51, green:0.51, blue:0.51, alpha:1)
    }
    
    class func fetchGreen() -> UIColor {
        return UIColor(hue:0.4, saturation:0.84, brightness:0.76, alpha:1)
    }

}