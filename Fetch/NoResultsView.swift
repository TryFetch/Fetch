//
//  viewView.swift
//  Fetch
//
//  Created by Stephen Radford on 08/08/2015.
//  Copyright (c) 2015 Cocoon Development Ltd. All rights reserved.
//

import UIKit

class NoResultsView: UIView {
    
    var label: UILabel!
    
    init(frame: CGRect, text: String) {
        super.init(frame: frame)
        
        hidden = true
        autoresizingMask = [UIViewAutoresizing.FlexibleWidth, UIViewAutoresizing.FlexibleHeight]
        backgroundColor = UIColor.fetchBackground()
        layer.zPosition = 10
        
        label = UILabel(frame: frame)
        label.text = text
        label.textColor = UIColor.fetchGreyText()
        label.autoresizingMask = [UIViewAutoresizing.FlexibleBottomMargin, UIViewAutoresizing.FlexibleTopMargin, UIViewAutoresizing.FlexibleLeftMargin, UIViewAutoresizing.FlexibleRightMargin]
        label.center = CGPointMake(center.x, center.y-64)
        label.textAlignment = .Center
        
        addSubview(label)
    }

    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    
}
