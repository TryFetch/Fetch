//
//  AppDelegate.swift
//  Fetch
//
//  Created by Stephen Radford on 17/05/2015.
//  Copyright (c) 2015 Cocoon Development Ltd. All rights reserved.
//

import UIKit
import AVFoundation
import Fabric
import Crashlytics
import PutioKit
import ReachabilitySwift

var reachability: Reachability?

@UIApplicationMain
class AppDelegate: UIResponder, UIApplicationDelegate, PutioDelegate {
    
    var window: UIWindow?
    let notificationCenter = NSNotificationCenter.defaultCenter()
    
    func application(application: UIApplication, didFinishLaunchingWithOptions launchOptions: [NSObject: AnyObject]?) -> Bool {
        
        do {
            reachability = try Reachability.reachabilityForInternetConnection()
        } catch {
            print(error)
        }
        
        Fabric.with([Crashlytics.self()])
        
        do {
            // Setup the AV Session so we can play via AirPlay in the background
            try AVAudioSession.sharedInstance().setCategory(AVAudioSessionCategoryPlayback)
        } catch {
            print("error creating audio session")
        }
        
        Putio.sharedInstance.delegate = self
        
        setupUI()
        
        // Determine which storyboard should be shown
        setupRootViewController()
        
        return true
    }
    
    func application(application: UIApplication, didReceiveRemoteNotification userInfo: [NSObject : AnyObject]) {
        // BACKGROUND REFRESH :D
    }
    
    func application(application: UIApplication, didRegisterForRemoteNotificationsWithDeviceToken deviceToken: NSData) {
        Putio.registerForPushNotifications(deviceToken)
    }
    
    func application(application: UIApplication, didFailToRegisterForRemoteNotificationsWithError error: NSError) {
        print("Couldn't register: \(error)")
    }
    
    func setupUI() {
        
        window?.tintColor = UIColor(red:0.91, green:0.7, blue:0.16, alpha:1)
        
        // Cell
        let colorView = UIView()
        colorView.backgroundColor = .fetchLighterBackground()
        
        let cell = UITableViewCell.appearance()
        cell.selectedBackgroundView = colorView
        cell.backgroundColor = .fetchBackground()
        cell.backgroundView?.backgroundColor = .fetchBackground()
        
        let table = UITableView.appearance()
        table.separatorColor = .fetchLighterBackground()
        
        let switchCtrl = UISwitch.appearance()
        switchCtrl.tintColor = .fetchYellow()
        switchCtrl.onTintColor = .fetchYellow()
        
        UITextField.appearance().keyboardAppearance = .Dark
        UISearchBar.appearance().keyboardAppearance = .Dark
        
    }
    
    func setupRootViewController() {
        
        // If the app has been passed a testing token then pop it in the keychain
        if let token = NSUserDefaults.standardUserDefaults().stringForKey("UITestingToken") {
            Putio.keychain["access_token"] = token
        }
        
        // This is the first run, it'll be shown if there is nothing stored in the keychain
        
        print(Putio.keychain)
        
        if let token = Putio.accessToken {
            // The user is logged in
        } else {
            let sb: UIStoryboard = UIStoryboard(name: "FirstRun", bundle: nil)
            let vc: UIViewController = sb.instantiateInitialViewController()!
            self.window?.rootViewController = vc
        }
        
    }
    
    
    // MARK: - 3DTouch
    

    // =====
    // Open the application via 3DTouch shortcuts on the homepage
    // =====
    func application(application: UIApplication, performActionForShortcutItem shortcutItem: UIApplicationShortcutItem, completionHandler: (Bool) -> Void) {
        
        var action: QuickAction? {
            switch shortcutItem.type {
            case "uk.co.wearecocoon.Fetch.Search":
                return .Search
            case "uk.co.wearecocoon.Fetch.AddFiles":
                return .AddFiles
            case "uk.co.wearecocoon.Fetch.Downloads":
                return .Downloads
            case "uk.co.wearecocoon.Fetch.Activity":
                return .Activity
            default:
                return nil
            }
        }
        
        if let a = action {
            QuickAction.handleAction(a, callback: completionHandler)
        } else {
            completionHandler(false)
        }
        
    }

    
    // MARK: - Add New Files
    
    func application(application: UIApplication, handleOpenURL url: NSURL) -> Bool {
        
        if Putio.accessToken != nil {
            
            let sb: UIStoryboard = UIStoryboard(name: "Main", bundle: nil)
            let sb2: UIStoryboard = UIStoryboard(name: "Transfers", bundle: nil)
            
            // Setup the root view controller
            let rvc: UITabBarController = sb.instantiateInitialViewController() as! UITabBarController
            
            // Set the selected tab to transfers
            rvc.selectedIndex = 2
            self.window?.rootViewController = rvc
            
            // Setup add files to be vc
            let vc: UINavigationController = sb2.instantiateViewControllerWithIdentifier("addFiles") as! UINavigationController
            let childView: AddFilesViewController = vc.viewControllers[0] as! AddFilesViewController
            
            // Move the url reference to the controller
            childView.magnetLink = url.absoluteString
            
            // Present
            
            let delayTime = dispatch_time(DISPATCH_TIME_NOW, Int64(0.5 * Double(NSEC_PER_SEC)))
            dispatch_after(delayTime, dispatch_get_main_queue(), { () -> Void in
                self.window?.rootViewController?.presentViewController(vc, animated: true, completion: nil)
            })
            
            return true
            
        }
        
        return false
    }
    
    // MARK: - Putio Delegate
    
    func error400Received() {
        print("error 400")
        logoutWithError()
    }
    
    // MARK: - Background Download
    
    func application(application: UIApplication, handleEventsForBackgroundURLSession identifier: String, completionHandler: () -> Void) {
        Downloader.sharedInstance.manager.backgroundCompletionHandler = completionHandler
    }
    
}


// MARK: - Forbidden error

// TODO: move to Putiokit
func logoutWithError() {
    let sb = UIStoryboard(name: "FirstRun", bundle: nil)
    let vc: UIViewController = sb.instantiateInitialViewController()!
    UIApplication.sharedApplication().keyWindow?.rootViewController = vc
    
    let alert = FetchAlertController(title: "Logged Out", message: "You've been logged out. Please login to continue.", preferredStyle: .Alert)
    alert.addAction(UIAlertAction(title: "OK", style: .Default, handler: nil))
    vc.presentViewController(alert, animated: true, completion: nil)
    
    
    Putio.keychain["access_token"] = nil
    Videos.sharedInstance.wipe()
    
    do {
        try Putio.realm.write {
            Putio.realm.deleteAll()
        }
    } catch {
        print(error)
    }
}

