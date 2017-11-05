//
//  UIView+FadeAndHide.swift
//  Fetch
//
//  Created by Stephen Radford on 18/03/2016.
//  Copyright © 2016 Cocoon Development Ltd. All rights reserved.
//

import UIKit

extension UIView {
    
    func fadeAndHide() {
        UIView.animate(withDuration: 0.3, animations: {
            self.alpha = 0
        }, completion: { complete in
            self.isHidden = true
        }) 
    }
    
    func fadeAndShow() {
        self.alpha = 0
        self.isHidden = false
        UIView.animate(withDuration: 0.3, animations: {
            self.alpha = 1
        })
    }
    
}
