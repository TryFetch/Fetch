//
//  NSObject+Delay.swift
//  Fetch
//
//  Created by Stephen Radford on 03/03/2016.
//  Copyright © 2016 Cocoon Development Ltd. All rights reserved.
//

import Foundation

extension NSObject {
    
    func delay(_ delay:Double, closure:@escaping ()->()) {
        DispatchQueue.main.asyncAfter(
            deadline: DispatchTime.now() + Double(Int64(delay * Double(NSEC_PER_SEC))) / Double(NSEC_PER_SEC), execute: closure)
    }
    
}
