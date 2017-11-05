//
//  FetchAlertViewController.swift
//  Fetch
//
//  Created by Stephen Radford on 13/03/2016.
//  Copyright © 2016 Cocoon Development Ltd. All rights reserved.
//

import UIKit

class FetchAlertController: UIAlertController {

    override func addAction(_ action: UIAlertAction) {
        super.addAction(action)
        
        let subView = view.subviews.first!
        let contentView = subView.subviews.first!
        for view in contentView.subviews[0].subviews {
            view.backgroundColor = UIColor.white
            view.alpha = 1
        }
    }
    
}
