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
    let notificationCenter = NotificationCenter.default
    
    func application(_ application: UIApplication, didFinishLaunchingWithOptions launchOptions: [UIApplicationLaunchOptionsKey: Any]?) -> Bool {
        
        do {
            reachability = try Reachability()
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
    
    func application(_ application: UIApplication, didReceiveRemoteNotification userInfo: [AnyHashable: Any]) {
        // BACKGROUND REFRESH :D
    }
    
    func application(_ application: UIApplication, didRegisterForRemoteNotificationsWithDeviceToken deviceToken: Data) {
        Putio.registerForPushNotifications(token: deviceToken)
    }
    
    func application(_ application: UIApplication, didFailToRegisterForRemoteNotificationsWithError error: Error) {
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
        
        UITextField.appearance().keyboardAppearance = .dark
        UISearchBar.appearance().keyboardAppearance = .dark
        
    }
    
    func setupRootViewController() {
        
        // If the app has been passed a testing token then pop it in the keychain
        if let token = UserDefaults.standard.string(forKey: "UITestingToken") {
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
    func application(_ application: UIApplication, performActionFor shortcutItem: UIApplicationShortcutItem, completionHandler: @escaping (Bool) -> Void) {
        
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
    
    func application(_ application: UIApplication, handleOpen url: URL) -> Bool {
        
        if Putio.accessToken != nil {
            
            let sb: UIStoryboard = UIStoryboard(name: "Main", bundle: nil)
            let sb2: UIStoryboard = UIStoryboard(name: "Transfers", bundle: nil)
            
            // Setup the root view controller
            let rvc: UITabBarController = sb.instantiateInitialViewController() as! UITabBarController
            
            // Set the selected tab to transfers
            rvc.selectedIndex = 2
            self.window?.rootViewController = rvc
            
            // Setup add files to be vc
            let vc: UINavigationController = sb2.instantiateViewController(withIdentifier: "addFiles") as! UINavigationController
            let childView: AddFilesViewController = vc.viewControllers[0] as! AddFilesViewController
            
            // Move the url reference to the controller
            childView.magnetLink = url.absoluteString
            
            // Present
            
            let delayTime = DispatchTime.now() + Double(Int64(0.5 * Double(NSEC_PER_SEC))) / Double(NSEC_PER_SEC)
            DispatchQueue.main.asyncAfter(deadline: delayTime, execute: { () -> Void in
                self.window?.rootViewController?.present(vc, animated: true, completion: nil)
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
    
    func application(_ application: UIApplication, handleEventsForBackgroundURLSession identifier: String, completionHandler: @escaping () -> Void) {
        Downloader.sharedInstance.manager.backgroundCompletionHandler = completionHandler
    }
    
}


// MARK: - Forbidden error

// TODO: move to Putiokit
func logoutWithError() {
    let sb = UIStoryboard(name: "FirstRun", bundle: nil)
    let vc: UIViewController = sb.instantiateInitialViewController()!
    UIApplication.shared.keyWindow?.rootViewController = vc
    
    let alert = FetchAlertController(title: "Logged Out", message: "You've been logged out. Please login to continue.", preferredStyle: .alert)
    alert.addAction(UIAlertAction(title: "OK", style: .default, handler: nil))
    vc.present(alert, animated: true, completion: nil)
    
    
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

