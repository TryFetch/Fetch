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
    
    func playerViewControllerDidStartPictureInPicture(_ playerViewController: AVPlayerViewController) {
        
        print("--- PIP STARTING ---")
        
    }
    
    func playerViewControllerDidStopPictureInPicture(_ playerViewController: AVPlayerViewController) {
        
        print("--- PIP STOPPING ---")
        
    }
    
    func playerViewController(_ playerViewController: AVPlayerViewController, restoreUserInterfaceForPictureInPictureStopWithCompletionHandler completionHandler: @escaping (Bool) -> Void) {
        
        print("---- PIP RESTORING -----")
        
        let rvc = UIApplication.shared.keyWindow?.rootViewController
            
        rvc!.present(playerViewController, animated: true, completion: {
            completionHandler(true)
        })
        
    }
    
}
