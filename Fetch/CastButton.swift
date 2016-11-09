//
//  CastButton.swift
//  Fetch
//
//  Created by Stephen Radford on 21/06/2015.
//  Copyright (c) 2015 Cocoon Development Ltd. All rights reserved.
//

import UIKit

class CastButton: UIView {
    
    /// Shared instance
    static let sharedInstance =  CastButton()

    /// Reference to the UIButton
    var button: UIButton!
    
    /// Image when connected to Chromecast
    let castOn: UIImage = UIImage(named: "cast_on")!
    
    /// Image when not connected to Chromecast
    let castOff: UIImage = UIImage(named: "cast_off")!
    
    /// Images for use in the animation when connecting
    let castConnecting: [UIImage] = [
        UIImage(named: "cast_on0")!,
        UIImage(named: "cast_on1")!,
        UIImage(named: "cast_on2")!
    ]
    
    /// Is the button connected?
    var connectionState: CastConnectionState = .Disconnected
    
    init() {
        super.init(frame: CGRect.zero)
        
        frame = CGRectMake(0, 0, castOn.size.width, castOn.size.height)
        
        button = UIButton(type: .System)
        button.frame = frame
        button.imageView?.animationImages = castConnecting
        button.imageView?.animationDuration = 1.0
        
        addSubview(button)
        
        updateButtonImage()
    }
    

    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    
    // MARK: - State
    
    /// Set the current state of the button
    func setState(state: CastConnectionState) {
        self.connectionState = state
        updateButtonImage()
    }
    
    /// Update the image used by the button
    private func updateButtonImage() {
        switch connectionState {
            case .Connecting :
                button.imageView?.startAnimating()
                break
            case .Connected :
                button.imageView?.stopAnimating()
                button.setImage(castOn, forState: .Normal)
                break
            default:
                button.imageView?.stopAnimating()
                button.setImage(castOff, forState: .Normal)
                break
            
        }
    }
    

}
