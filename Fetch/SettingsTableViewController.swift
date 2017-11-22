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

    let defaults = UserDefaults.standard
    let notificationCenter = NotificationCenter.default
    
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
    
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
    }

    override var preferredStatusBarStyle: UIStatusBarStyle {
        return .lightContent
    }
    
    
    // MARK: - Table view data source

    override func numberOfSections(in tableView: UITableView) -> Int {
        return sections.count
    }

    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return sections[section].count
    }

    
    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
    
        var cell: UITableViewCell!
        let row = sections[indexPath.section][indexPath.row]
        
        if indexPath.section == 3 {
            
            cell = tableView.dequeueReusableCell(withIdentifier: "logoutBtn", for: indexPath)
            cell.textLabel!.text = "Logout"
            cell.textLabel!.textColor = UIColor(hue:1, saturation:0.66, brightness:0.85, alpha:1)
            cell.textLabel!.textAlignment = .center
            
        } else if indexPath.section == 2 {
            
            cell = tableView.dequeueReusableCell(withIdentifier: "supportIdentifer", for: indexPath)
            cell.textLabel!.text = row
        
        } else if indexPath.section == 1 {
            
            cell = tableView.dequeueReusableCell(withIdentifier: "switchCell", for: indexPath)
            cell.textLabel!.text = row
            
            cell.accessoryView = setupSwitch(key: info[row]!)
            
        } else {
            cell = tableView.dequeueReusableCell(withIdentifier: "reuseIdentifier", for: indexPath)
            cell.textLabel!.text = row
            cell.detailTextLabel?.text = info[row]
        }
        
        return cell
    }
    
    
    func setupSwitch(key: String) -> UISwitch {
        
        // Setup the switchView and set tint color
        let switchView = UISwitch(frame: CGRect.zero)
        switchView.onTintColor = UIColor(red:0.99, green:0.8, blue:0.33, alpha:1)
        
        // Setup the value
        let value = defaults.object(forKey: key) as? Bool ?? true
        
        switchView.isOn = value
        switchView.tag = switches.index(of: key)!
        
        switchView.addTarget(self, action: #selector(switchChanged), for: .valueChanged)
        
        return switchView
    }
    
    func switchChanged(switchState: UISwitch) {
        defaults.set(switchState.isOn, forKey: switches[switchState.tag])
    }
    
    override func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        
        // LOGOUT
        if(indexPath.section == 3) {
            
            let alert = FetchAlertController(title: "Logout", message: "Are you sure you wish to logout?", preferredStyle: .alert)
            
            alert.addAction(UIAlertAction(title: "OK", style: .default, handler: { action in
                
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
                self.present(vc, animated: true, completion: nil)
                
            }))
            
            alert.addAction(UIAlertAction(title: "Cancel", style: .cancel, handler: nil))
            
            present(alert, animated: true, completion: nil)
        }
        
        // SUPPORT BUTTONS
        if(indexPath.section == 2) {
            
            let row = sections[indexPath.section][indexPath.row]
            let url = URL(string: info[row]!)!
            UIApplication.shared.openURL(url)
            
        }
        
        tableView.deselectRow(at: indexPath, animated: true)
    }
    
    
    // MARK: - Actions
    
    
    @IBAction func saveSettings(_ sender: AnyObject) {
        dismiss(animated: true, completion: nil)
    }
    
    
    @IBAction func closeSettings(_ sender: AnyObject) {
        dismiss(animated: true, completion: nil)
    }
    
    // MARK: - Network
    
    func getAccountInfo() {
        
        UIApplication.shared.isNetworkActivityIndicatorVisible = true
        
        Putio.get("account/info") { json, error in
            
            if let avail = json?["info"]["disk"]["avail"].int64 {
                let formatter = ByteCountFormatter()
                let available = formatter.string(fromByteCount: avail)
                self.info["Space Free"] = "\(available)"
            }
            
            if let dateString = json?["info"]["plan_expiration_date"].string {
                self.info["Expires"] = dateString.components(separatedBy: "T")[0]
            }
            
            if let username = json?["info"]["username"].string {
                self.info["Username"] = username
            }
            
            self.tableView.reloadData()
            
        }
        
    }

}
