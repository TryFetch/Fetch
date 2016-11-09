//
//  LoaderView.swift
//  Fetch
//
//  Created by Stephen Radford on 30/05/2015.
//  Copyright (c) 2015 Cocoon Development Ltd. All rights reserved.
//

import UIKit

class LoaderView: UIView {
    
    var view: UIView!
    var loader: UIActivityIndicatorView!
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        
        view = UIView(frame: frame)
        view.autoresizingMask = [UIViewAutoresizing.FlexibleWidth, UIViewAutoresizing.FlexibleHeight]
        view.backgroundColor = UIColor.fetchBackground()
        view.layer.zPosition = 15
        
        loader = UIActivityIndicatorView(activityIndicatorStyle: .White)
        loader.autoresizingMask = [UIViewAutoresizing.FlexibleBottomMargin, UIViewAutoresizing.FlexibleTopMargin, UIViewAutoresizing.FlexibleLeftMargin, UIViewAutoresizing.FlexibleRightMargin]
        loader.center = CGPointMake(view.center.x, view.center.y-64)
        loader.startAnimating()
        
        view.addSubview(loader)
    }

    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    func hideWithAnimation() {
        UIView.animateWithDuration(0.25, animations: {
            self.view.alpha = 0
        }, completion: { finished in
            self.view.hidden = true
        })
    }
    
    func showWithAnimation() {
        view.alpha = 0
        view.hidden = false
        
        UIView.animateWithDuration(0.25, animations: {
            self.view.alpha = 1
        })
    }
    
    func show() {
        self.view.alpha = 1
        self.view.hidden = false
    }

}
