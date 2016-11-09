//
//  NSObject+Delay.swift
//  Fetch
//
//  Created by Stephen Radford on 03/03/2016.
//  Copyright © 2016 Cocoon Development Ltd. All rights reserved.
//

import Foundation

extension NSObject {
    
    func delay(delay:Double, closure:()->()) {
        dispatch_after(
            dispatch_time(
                DISPATCH_TIME_NOW,
                Int64(delay * Double(NSEC_PER_SEC))
            ),
            dispatch_get_main_queue(), closure)
    }
    
}