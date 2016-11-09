//
//  PlayerDelegate.swift
//  Fetch
//
//  Created by Stephen Radford on 19/09/2015.
//  Copyright © 2015 Cocoon Development Ltd. All rights reserved.
//

import UIKit
import AVKit
import AVFoundation

@available(iOS 9.0, *)
class PlayerDelegate: NSObject, AVPlayerViewControllerDelegate {
    
    static let sharedInstance = PlayerDelegate()
    
    func playerViewControllerDidStartPictureInPicture(playerViewController: AVPlayerViewController) {
        
        print("--- PIP STARTING ---")
        
    }
    
    func playerViewControllerDidStopPictureInPicture(playerViewController: AVPlayerViewController) {
        
        print("--- PIP STOPPING ---")
        
    }
    
    func playerViewController(playerViewController: AVPlayerViewController, restoreUserInterfaceForPictureInPictureStopWithCompletionHandler completionHandler: (Bool) -> Void) {
        
        print("---- PIP RESTORING -----")
        
        let rvc = UIApplication.sharedApplication().keyWindow?.rootViewController
            
        rvc!.presentViewController(playerViewController, animated: true, completion: {
            completionHandler(true)
        })
        
    }
    
}
