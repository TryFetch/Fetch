//
//  CastHandler.swift
//  Fetch
//
//  Created by Stephen Radford on 01/08/2015.
//  Copyright (c) 2015 Cocoon Development Ltd. All rights reserved.
//

import UIKit
import MZFormSheetPresentationController
import PutioKit

class CastHandler: NSObject, DevicePickerDelegate, ConnectableDeviceDelegate, DiscoveryManagerDelegate, GCKLoggerDelegate {
    
    /// Shared instance
    static let sharedInstance = CastHandler()
    
    /// CastHandlerDelegate
    var delegate: CastHandlerDelegate?
    
    /// Chromecast App ID
    let castID = "6F389D19"
    
    /// The file that's currently playing
    var filePlaying: File?
    
    /// Is the currently steaming file playing?
    var isPlaying: Bool = false
    
    /// Instance of the discovery manager
    var discoveryManager: DiscoveryManager?
    
    /// Which device are we connected to
    var device: ConnectableDevice?
    
    /// The raw cast button
    let castBtn: CastButton = CastButton.sharedInstance
    
    /// Cast button wrapped in a UIBarButtonItem for use elsewhere
    var button: UIBarButtonItem?
    
    /// Store of the media launch object
    var launchObject: MediaLaunchObject?
    
    /// Are subtitles on?
    var subtitlesEnabled = false
    
    
    override init() {
        super.init()
        
        createHeaderBtn()
        setupDiscoveryManager()
    }
    
    /// Create the instance of the discovery manager
    private func setupDiscoveryManager() {
        
//        GCKLogger.sharedInstance().delegate = self
        
        discoveryManager = DiscoveryManager.sharedManager()
        discoveryManager?.delegate = self
        
        discoveryManager?.registerDeviceService(CastService.self, withDiscovery: CastDiscoveryProvider.self)
        discoveryManager?.registerDeviceService(DIALService.self, withDiscovery: SSDPDiscoveryProvider.self)
        discoveryManager?.registerDeviceService(RokuService.self, withDiscovery: SSDPDiscoveryProvider.self)
        discoveryManager?.registerDeviceService(DLNAService.self, withDiscovery: SSDPDiscoveryProvider.self)
        discoveryManager?.registerDeviceService(WebOSTVService.self, withDiscovery: SSDPDiscoveryProvider.self)
        discoveryManager?.registerDeviceService(FireTVService.self, withDiscovery: FireTVDiscoveryProvider.self)
        
        discoveryManager?.capabilityFilters = [
            CapabilityFilter(capabilities: [kMediaPlayerPlayVideo])
        ]
        
        discoveryManager?.startDiscovery()
        discoveryManager?.devicePicker().delegate = self
    }
    
    /// Create the header button instance
    private func createHeaderBtn() {
        castBtn.button.addTarget(self, action: #selector(showDevicePicker), forControlEvents: .TouchUpInside)
        castBtn.hidden = true
        button = UIBarButtonItem(customView: castBtn)
    }
    
    /// Show the device picker as an action sheet
    func showDevicePicker(sender: AnyObject?) {
        if device != nil {
            showDisconnectSheet(sender)
        } else {
            discoveryManager!.devicePicker().showActionSheet(sender)
        }
    }
    
    /// Show the disconnect sheet if a device is already connected
    private func showDisconnectSheet(sender: AnyObject?) {
        
        let sheet = FetchAlertController(title: "Connected: \(device!.friendlyName!)", message: "", preferredStyle: .ActionSheet)
        
        sheet.popoverPresentationController?.barButtonItem = button
        
        if filePlaying != nil {
            sheet.addAction(UIAlertAction(title: "Show Remote", style: .Default, handler: { (action) -> Void in
                self.showRemote(sender?.window??.rootViewController)
            }));
        }
        
        sheet.addAction(UIAlertAction(title: "Disconnect", style: .Destructive, handler: disconnect))
        sheet.addAction(UIAlertAction(title: "Cancel", style: .Cancel, handler: nil))
        
        // Present it on the root view controller. We'll need to check to see if this works on iPad
        sender?.window??.rootViewController?.presentViewController(sheet, animated: true, completion: nil)
        
    }
    
    /// Disconnect from the device, set it to nil and set the button state to .Disconnected
    func disconnect(sender: AnyObject?) {
        stop()
        device?.disconnect()
        device = nil
        castBtn.setState(.Disconnected)
    }
    
    func stop() {
        launchObject?.session.closeWithSuccess(nil, failure: nil)
        launchObject = nil
        filePlaying = nil
        isPlaying = false
        subtitlesEnabled = false
    }
    
    
    // MARK: - DiscoveryManagerDelegate
    
    func discoveryManager(manager: DiscoveryManager!, didFindDevice device: ConnectableDevice!) {
        changeButtonVisibility()
    }
    
    func discoveryManager(manager: DiscoveryManager!, didLoseDevice device: ConnectableDevice!) {
        print("Lost: \(device)")
        changeButtonVisibility()
    }

    func discoveryManager(manager: DiscoveryManager!, didUpdateDevice device: ConnectableDevice!) {
        print("Updated: \(device)")
        changeButtonVisibility()
    }
    
    func discoveryManager(manager: DiscoveryManager!, didFailWithError error: NSError!) {
        changeButtonVisibility()
        print(error)
    }
    
    /// Hide / Show the cast button based on the number of devices in the store
    func changeButtonVisibility() {
        if discoveryManager?.compatibleDevices().count > 0 {
            castBtn.hidden = false
        } else {
            castBtn.hidden = true
        }
    }
    
    
    // MARK: - DevicePickerDelegate
    
    func devicePicker(picker: DevicePicker!, didSelectDevice device: ConnectableDevice!) {
        self.device = device
        device.connect()
        device.delegate = self
        castBtn.setState(.Connecting)
    }
    
    func devicePicker(picker: DevicePicker!, didCancelWithError error: NSError!) {
        castBtn.setState(.Disconnected)
        self.device = nil
    }
    
    
    // MARK: - ConnectableDeviceDelegate
    
    func connectableDeviceReady(device: ConnectableDevice!) {
        castBtn.setState(.Connected)
    }
    
    func connectableDeviceDisconnected(device: ConnectableDevice!, withError error: NSError!) {
        castBtn.setState(.Disconnected)
        self.device = nil
    }
    
    
    // MARK: - Cast Media
    
    /// Send a file to the connected device
    func sendFile(file: File, callback: () -> Void) {
        
        launchObject = nil
        filePlaying = file
        isPlaying = true

        callback()
        
        var mp: MediaPlayer = device!.mediaPlayer()
        var URL: String!

        if file.has_mp4 {
            URL = "\(Putio.api)files/\(file.id)/mp4/stream?oauth_token=\(Putio.accessToken!)"
        } else {
            URL = "\(Putio.api)files/\(file.id)/stream?oauth_token=\(Putio.accessToken!)"
        }
        
        let info = MediaInfo(URL: NSURL(string: URL)!, mimeType: "video/mp4")
        info.title = file.name
        
        // Add subtitles if it's an MP4 and chromecast
        if (device?.serviceWithName("Chromecast") != nil && file.has_mp4) || device?.serviceWithName("Chromecast") == nil  {
            
            if device!.hasCapabilities([kMediaPlayerSubtitleWebVTT]) {
                
                info.subtitleInfo = SubtitleInfo(URL: NSURL(string: "\(Putio.api)files/\(file.id)/subtitles/default?oauth_token=\(Putio.accessToken!)&format=webvtt")!) { sub in
                    sub.mimeType = "text/vtt"
                    sub.language = "en"
                    sub.label = "Subtitles"
                }
                
            } else if device!.hasCapabilities([kMediaPlayerSubtitleSRT]) {
                
                info.subtitleInfo = SubtitleInfo(URL: NSURL(string: "\(Putio.api)files/\(file.id)/subtitles/default?oauth_token=\(Putio.accessToken!)&format=srt")!) { sub in
                    sub.mimeType = "text/srt"
                    sub.language = "en-US"
                    sub.label = "Subtitles"
                }
                
            }
            
        }
        
        // if it's chromecast set it to be our app ID
        if device?.serviceWithName("Chromecast") != nil {
            let cs: CastService = device!.mediaPlayer() as! CastService
            cs.castWebAppId = castID
            mp = cs as MediaPlayer
        }
            
        mp.playMediaWithMediaInfo(info, shouldLoop: false, success: { (media) -> Void in
            self.launchObject = media
            self.delegate?.launchObjectSuccess()
        }) { (error) -> Void in
            print(error)
        }
        
        
    }
    
    // MARK: - Remote
    
    /// Show the Cast Remote in a overlay
    func showRemote(sender: AnyObject?) {
        
        let vc = CastRemoteViewController(nibName: "CastRemote", bundle: NSBundle.mainBundle())
        vc.file = filePlaying
        
        let formSheetController = MZFormSheetPresentationViewController(contentViewController: vc)
        if self.device?.serviceWithName("Chromecast") != nil && filePlaying!.has_mp4 {
            formSheetController.presentationController?.contentViewSize = CGSizeMake(300, 320)
        } else {
            formSheetController.presentationController?.contentViewSize = CGSizeMake(300, 290)
        }
        formSheetController.contentViewControllerTransitionStyle = MZFormSheetPresentationTransitionStyle.DropDown
        formSheetController.contentViewCornerRadius = 5
        
        formSheetController.view.layer.shadowColor = UIColor.blackColor().CGColor
        formSheetController.view.layer.shadowOffset = CGSize(width: 0, height: 5)
        formSheetController.view.layer.shadowOpacity = 0.4
        formSheetController.view.layer.shadowRadius = 3
        
        formSheetController.presentationController?.shouldCenterVertically = true
        formSheetController.presentationController?.shouldUseMotionEffect = true
        
        sender?.presentViewController(formSheetController, animated: true, completion: nil)
        
    }
    
    
    // MARK: - GCKLoggerDelegate
    
    func logFromFunction(function: UnsafePointer<Int8>, message: String!) {
        print("----------------------")
        print("CHROMECAST: \(message)")
        print("----------------------")
    }
    
    
}