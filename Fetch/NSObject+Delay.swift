//
//  NSObject+Delay.swift
//  Fetch
//
//  Created by Stephen Radford on 03/03/2016.
//  Copyright © 2016 Cocoon Development Ltd. All rights reserved.
//

import Foundation

extension NSObject {
    
    func delay(delay: Double, closure: @escaping () -> ()) {
        DispatchQueue.main.asyncAfter(deadline: .now() + delay) {
            closure()
        }
    }
    
}
