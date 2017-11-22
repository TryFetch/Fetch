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
        
        isHidden = true
        autoresizingMask = [UIViewAutoresizing.flexibleWidth, UIViewAutoresizing.flexibleHeight]
        backgroundColor = UIColor.fetchBackground()
        layer.zPosition = 10
        
        label = UILabel(frame: frame)
        label.text = text
        label.textColor = UIColor.fetchGreyText()
        label.autoresizingMask = [UIViewAutoresizing.flexibleBottomMargin, UIViewAutoresizing.flexibleTopMargin, UIViewAutoresizing.flexibleLeftMargin, UIViewAutoresizing.flexibleRightMargin]
        label.center = CGPoint(x: center.x, y: center.y-64)
        label.textAlignment = .center
        
        addSubview(label)
    }

    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    
}
