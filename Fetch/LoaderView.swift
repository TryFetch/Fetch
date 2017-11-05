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
        view.autoresizingMask = [UIViewAutoresizing.flexibleWidth, UIViewAutoresizing.flexibleHeight]
        view.backgroundColor = UIColor.fetchBackground()
        view.layer.zPosition = 15
        
        loader = UIActivityIndicatorView(activityIndicatorStyle: .white)
        loader.autoresizingMask = [UIViewAutoresizing.flexibleBottomMargin, UIViewAutoresizing.flexibleTopMargin, UIViewAutoresizing.flexibleLeftMargin, UIViewAutoresizing.flexibleRightMargin]
        loader.center = CGPoint(x: view.center.x, y: view.center.y-64)
        loader.startAnimating()
        
        view.addSubview(loader)
    }

    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    func hideWithAnimation() {
        UIView.animate(withDuration: 0.25, animations: {
            self.view.alpha = 0
        }, completion: { finished in
            self.view.isHidden = true
        })
    }
    
    func showWithAnimation() {
        view.alpha = 0
        view.isHidden = false
        
        UIView.animate(withDuration: 0.25, animations: {
            self.view.alpha = 1
        })
    }
    
    func show() {
        self.view.alpha = 1
        self.view.isHidden = false
    }

}
