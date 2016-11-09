//
//  MediaPlayerViewController.swift
//  Fetch
//
//  Created by Stephen Radford on 24/05/2015.
//  Copyright (c) 2015 Cocoon Development Ltd. All rights reserved.
//

import UIKit
import AVFoundation
import AVKit
import CoreMedia
import PutioKit

class MediaPlayerViewController: AVPlayerViewController {

    // MARK: - Variables
    
    var file: File?
    var loadedTime: CMTime?
    var checked: Bool = false
    let defaults = NSUserDefaults.standardUserDefaults()
    var notifier = NSNotificationCenter.defaultCenter()
    var observer: AnyObject?
    
    
    // MARK: - Layout
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        // pause the player as soon as it loads
        player?.pause()
        player?.closedCaptionDisplayEnabled = true
    }
    
    override func viewDidAppear(animated: Bool) {
        super.viewDidAppear(animated)
        
        // Store the current position when the app is exited
        notifier.addObserver(self, selector: #selector(saveTime), name: UIApplicationWillResignActiveNotification, object: nil)
        notifier.addObserver(self, selector: #selector(playedToEnd), name: AVPlayerItemDidPlayToEndTimeNotification, object: player?.currentItem)
        
        // Check the time at intervals
        observer = player?.addPeriodicTimeObserverForInterval(CMTimeMake(15, 1), queue: nil) { (time) -> Void in
            self.saveTime()
        }
        
        if !checked {
            if file!.start_from > 0 {
                loadTime()
            } else {
                player?.play()
            }
            checked = true
        }
         
    }
    
    override func viewWillDisappear(animated: Bool) {
        super.viewWillDisappear(animated)
        saveTime()
        
        player?.removeTimeObserver(observer!)
        notifier.removeObserver(self)
        observer = nil
    }
    
    func playedToEnd() {
        dismissViewControllerAnimated(true, completion: nil)
        // TODO: recommend next one
    }
    
    
    // MARK: - Continue Playing
    
    
    /// Check if we've stored a time in NSUserDefaults
    func loadTime() {
        let avc: FetchAlertController = FetchAlertController(title: "Continue Playing", message: "Would you like to continue where you left off?", preferredStyle: .Alert)
            
        avc.addAction(UIAlertAction(title: "Yes", style: .Default, handler: { action in
            self.seekToTime(self.file!.start_from)
        }))
            
        avc.addAction(UIAlertAction(title: "No", style: .Cancel, handler: { action in
            self.player?.play()
        }))
            
        showContinuePlaying(avc, time: file!.start_from)

    }
    
    
    /// Seek to the time in the keystore
    func seekToTime(time: Float64) {
        loadedTime = CMTimeMakeWithSeconds(time, 600)
        player?.seekToTime(self.loadedTime!)
        player?.play()
    }
    
    
    /// Check in the NSUserDefaults to see if we should show an alert or just carry on
    func showContinuePlaying(avc: UIAlertController, time: Float64) {
        presentViewController(avc, animated: true, completion: nil)
    }
    
    
    // MARK: - Save time to Put.io
    
    
    func saveTime() {
        let time = player?.currentTime()
        let seconds = CMTimeGetSeconds(time!)
        if seconds > 0 {
            do {
                try Putio.realm.write {
                    file?.start_from = seconds
                    file?.saveTime()
                }
            } catch {
                print("Could not save time")
            }
        }
    }
    

}
