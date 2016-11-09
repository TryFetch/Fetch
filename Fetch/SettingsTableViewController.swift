//
//  SettingsTableViewController.swift
//  Fetch
//
//  Created by Stephen Radford on 23/05/2015.
//  Copyright (c) 2015 Cocoon Development Ltd. All rights reserved.
//

import UIKit
import Alamofire
import SwiftyJSON
import PutioKit

class SettingsTableViewController: UITableViewController {

    let defaults = NSUserDefaults.standardUserDefaults()
    let notificationCenter = NSNotificationCenter.defaultCenter()
    
    let sections = [
        ["Username", "Space Free", "Expires"],
        ["Continue Playing Alert"],
        ["Twitter", "Support"],
        ["Logout"]
    ]
    
    var info = [
        "Username": "-",
        "Space Free": "-",
        "Expires": "-",
        "Twitter": "http://twitter.com/fetch_ios",
        "Support": "http://getfetchapp.com",
        "Continue Playing Alert": "continueplaying"
    ]
    
    var switches = [
        "continueplaying"
    ]
    
    override func viewDidLoad() {
        super.viewDidLoad()
        getAccountInfo()
    }
    
    override func viewDidAppear(animated: Bool) {
        super.viewDidAppear(animated)
    }

    override func preferredStatusBarStyle() -> UIStatusBarStyle {
        return .LightContent
    }
    
    // MARK: - Table view data source

    override func numberOfSectionsInTableView(tableView: UITableView) -> Int {
        return sections.count
    }

    override func tableView(tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return sections[section].count
    }

    
    override func tableView(tableView: UITableView, cellForRowAtIndexPath indexPath: NSIndexPath) -> UITableViewCell {
    
        var cell: UITableViewCell!
        let row = sections[indexPath.section][indexPath.row]
        
        if indexPath.section == 3 {
            
            cell = tableView.dequeueReusableCellWithIdentifier("logoutBtn", forIndexPath: indexPath) 
            cell.textLabel!.text = "Logout"
            cell.textLabel!.textColor = UIColor(hue:1, saturation:0.66, brightness:0.85, alpha:1)
            cell.textLabel!.textAlignment = .Center
            
        } else if indexPath.section == 2 {
            
            cell = tableView.dequeueReusableCellWithIdentifier("supportIdentifer", forIndexPath: indexPath) 
            cell.textLabel!.text = row
        
        } else if indexPath.section == 1 {
            
            cell = tableView.dequeueReusableCellWithIdentifier("switchCell", forIndexPath: indexPath) 
            cell.textLabel!.text = row
            
            cell.accessoryView = setupSwitch(info[row]!)
            
        } else {
            cell = tableView.dequeueReusableCellWithIdentifier("reuseIdentifier", forIndexPath: indexPath) 
            cell.textLabel!.text = row
            cell.detailTextLabel?.text = info[row]
        }
        
        return cell
    }
    
    
    func setupSwitch(key: String) -> UISwitch {
        
        // Setup the switchView and set tint color
        let switchView = UISwitch(frame: CGRectZero)
        switchView.onTintColor = UIColor(red:0.99, green:0.8, blue:0.33, alpha:1)
        
        // Setup the value
        var value: Bool = true
        
        if let val: AnyObject? = defaults.objectForKey(key) {
            value = (val != nil) ? val as! Bool : true
        }
        
        switchView.on = value
        switchView.tag = switches.indexOf(key)!
        
        switchView.addTarget(self, action: #selector(switchChanged), forControlEvents: .ValueChanged)
        
        return switchView
    }
    
    func switchChanged(switchState: UISwitch) {
        defaults.setBool(switchState.on, forKey: switches[switchState.tag])
    }
    
    override func tableView(tableView: UITableView, didSelectRowAtIndexPath indexPath: NSIndexPath) {
        
        // LOGOUT
        if(indexPath.section == 3) {
            
            let alert = FetchAlertController(title: "Logout", message: "Are you sure you wish to logout?", preferredStyle: .Alert)
            
            alert.addAction(UIAlertAction(title: "OK", style: .Default, handler: { action in
                
                do {
                    try Putio.realm.write {
                        Putio.realm.deleteAll()
                    }
                } catch {
                    print(error)
                }
                
                Putio.keychain["access_token"] = nil
                Videos.sharedInstance.wipe()
                
                let sb = UIStoryboard(name: "FirstRun", bundle: nil)
                let vc: UIViewController = sb.instantiateInitialViewController()!
                self.presentViewController(vc, animated: true, completion: nil)
                
            }))
            
            alert.addAction(UIAlertAction(title: "Cancel", style: .Cancel, handler: nil))
            
            presentViewController(alert, animated: true, completion: nil)
        }
        
        // SUPPORT BUTTONS
        if(indexPath.section == 2) {
            
            let row = sections[indexPath.section][indexPath.row]
            let url = NSURL(string: info[row]!)
            UIApplication.sharedApplication().openURL(url!)
            
        }
        
        tableView.deselectRowAtIndexPath(indexPath, animated: true)
    }
    
    
    // MARK: - Actions
    
    
    @IBAction func saveSettings(sender: AnyObject) {
        dismissViewControllerAnimated(true, completion: nil)
    }
    
    
    @IBAction func closeSettings(sender: AnyObject) {
        dismissViewControllerAnimated(true, completion: nil)
    }
    
    // MARK: - Network
    
    func getAccountInfo() {
        
        UIApplication.sharedApplication().networkActivityIndicatorVisible = true
        
        Putio.get("account/info") { json, error in
            
            if let avail = json?["info"]["disk"]["avail"].int64 {
                let formatter = NSByteCountFormatter()
                let available = formatter.stringFromByteCount(avail)
                self.info["Space Free"] = "\(available)"
            }
            
            if let dateString = json?["info"]["plan_expiration_date"].string {
                self.info["Expires"] = dateString.componentsSeparatedByString("T")[0]
            }
            
            if let username = json?["info"]["username"].string {
                self.info["Username"] = username
            }
            
            self.tableView.reloadData()
            
        }
        
    }

}
