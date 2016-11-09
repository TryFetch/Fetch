//
//  ActivityTableViewController.swift
//  Fetch
//
//  Created by Stephen Radford on 08/01/2016.
//  Copyright © 2016 Cocoon Development Ltd. All rights reserved.
//

import UIKit
import PutioKit

class ActivityTableViewController: UITableViewController {

    var events = [NSDate:[Event]]()
    
    let sb = UIStoryboard(name: "Main", bundle: nil)
    
    var sortedKeys: [NSDate] {
        return Array(events.keys).sort { $0.compare($1) == .OrderedDescending }
    }
    
    var overlay: LoaderView?
    
    var noResults: NoResultsView?
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        noResults = NoResultsView(frame: tableView.frame, text: "No recent activity.")
        tableView.addSubview(noResults!)
        
        overlay = LoaderView(frame: tableView.frame)
        tableView.addSubview(overlay!.view)
        
        refreshControl?.addTarget(self, action: #selector(fetch), forControlEvents: UIControlEvents.ValueChanged)
        
        fetch(self)
    }
    
    func fetch(sender: AnyObject?) {
        Events.get { events, error in
            self.events = events
            self.tableView.reloadData()
            self.refreshControl?.endRefreshing()
            
            self.overlay?.hideWithAnimation()
            if events.count == 0 {
                self.noResults!.hidden = false
            } else {
                self.noResults!.hidden = true
            }
        }
    }
    
    override func tableView(tableView: UITableView, willDisplayHeaderView view: UIView, forSection section: Int) {
        if let v = view as? UITableViewHeaderFooterView {
            v.backgroundView?.backgroundColor = .fetchLighterBackground()
            v.textLabel?.textColor = .whiteColor()
        }
    }

    // MARK: - Table view data source

    override func numberOfSectionsInTableView(tableView: UITableView) -> Int {
        return events.count
    }

    override func tableView(tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        let key = sortedKeys[section]
        return events[key]!.count
    }
    
    override func tableView(tableView: UITableView, titleForHeaderInSection section: Int) -> String? {
        let dateFormatter = NSDateFormatter()
        dateFormatter.dateStyle = .LongStyle
        return dateFormatter.stringFromDate(sortedKeys[section])
    }
    
    override func tableView(tableView: UITableView, cellForRowAtIndexPath indexPath: NSIndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCellWithIdentifier("eventCell")!
        let key = sortedKeys[indexPath.section]
        let event = events[key]![indexPath.row]
        if event.fileID != nil {
            cell.accessoryType = .DisclosureIndicator
        }
        cell.textLabel?.text = event.name
        return cell
    }
    
    // MARK: - Navigation
    
    override func tableView(tableView: UITableView, didSelectRowAtIndexPath indexPath: NSIndexPath) {
        let key = sortedKeys[indexPath.section]
        let event = events[key]![indexPath.row]
        if let vc = sb.instantiateViewControllerWithIdentifier("directoryView") as? DirectoryTableViewController {
            File.getFileById("\(event.fileID!)") { file in
                vc.file = file
                self.navigationController?.pushViewController(vc, animated: true)
            }
        }
    }
    
    // MARK: - Clear Activity
    
    @IBAction func clearActivity(sender: AnyObject) {
        overlay?.showWithAnimation()
        Events.clear {
            self.delay(1) {
                self.fetch(self)
            }
        }
    }

}
