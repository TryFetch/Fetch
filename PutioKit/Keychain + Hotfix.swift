//
//  Keychain + Hotfix.swift
//  Fetch
//
//  Created by Stephen Radford on 10/11/2016.
//  Copyright © 2016 Cocoon Development Ltd. All rights reserved.
//

import KeychainAccess

extension Keychain {
    
    func updateIfNeeded(_ key: String, value: String?) {
        if self[key] != value {
            self[key] = value
        }
    }
    
}
