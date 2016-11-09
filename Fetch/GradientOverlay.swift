//
//  GradientOverlay.swift
//  Fetch
//
//  Created by Stephen Radford on 22/08/2015.
//  Copyright (c) 2015 Cocoon Development Ltd. All rights reserved.
//

import UIKit

class GradientOverlay: UIView {

    
    override init(frame: CGRect) {
        super.init(frame: frame)
        backgroundColor = .clearColor()
    }

    required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
        backgroundColor = .clearColor()
    }
    
    // Only override drawRect: if you perform custom drawing.
    // An empty implementation adversely affects performance during animation.
    override func drawRect(rect: CGRect) {
        
        //2 - get the current context
        let context = UIGraphicsGetCurrentContext()
        let colors = [UIColor(hue: 0, saturation: 0, brightness: 0.14, alpha: 0.5).CGColor, UIColor.fetchBackground().CGColor]
        
        //3 - set up the color space
        let colorSpace = CGColorSpaceCreateDeviceRGB()
        
        //4 - set up the color stops
        let colorLocations:[CGFloat] = [0.0, 1.0]
        
        //5 - create the gradient
        let gradient = CGGradientCreateWithColors(colorSpace,
            colors,
            colorLocations)
        
        //6 - draw the gradient
        let startPoint = CGPoint.zero
        let endPoint = CGPoint(x:0, y:self.bounds.height)
        CGContextDrawLinearGradient(context,
            gradient,
            startPoint,
            endPoint,
            [])
        
    }
    
    func hideWithAnimation() {
        UIView.animateWithDuration(0.35, animations: {
            self.alpha = 0
            }, completion: { finished in
                self.hidden = true
        })
    }
    
    func showWithAnimation() {
        alpha = 0
        hidden = false
        
        UIView.animateWithDuration(0.35, animations: {
            self.alpha = 1
        })
    }
    
}
