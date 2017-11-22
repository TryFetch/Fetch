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
        return Array(events.keys).sorted { $0.compare($1 as Date) == .orderedDescending }
    }
    
    var overlay: LoaderView?
    
    var noResults: NoResultsView?
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        noResults = NoResultsView(frame: tableView.frame, text: "No recent activity.")
        tableView.addSubview(noResults!)
        
        overlay = LoaderView(frame: tableView.frame)
        tableView.addSubview(overlay!.view)
        
        refreshControl?.addTarget(self, action: #selector(fetch), for: .valueChanged)
        
        fetch(sender: self)
    }
    
    func fetch(sender: AnyObject?) {
        Events.get { events, error in
            self.events = events as [NSDate : [Event]]
            self.tableView.reloadData()
            self.refreshControl?.endRefreshing()
            
            self.overlay?.hideWithAnimation()
            if events.count == 0 {
                self.noResults!.isHidden = false
            } else {
                self.noResults!.isHidden = true
            }
        }
    }
    
    override func tableView(_ tableView: UITableView, willDisplayHeaderView view: UIView, forSection section: Int) {
        if let v = view as? UITableViewHeaderFooterView {
            v.backgroundView?.backgroundColor = .fetchLighterBackground()
            v.textLabel?.textColor = .white
        }
    }

    // MARK: - Table view data source
    
    override func numberOfSections(in tableView: UITableView) -> Int {
        return events.count
    }

    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        let key = sortedKeys[section]
        return events[key]!.count
    }
        
    override func tableView(_ tableView: UITableView, titleForHeaderInSection section: Int) -> String? {
        let dateFormatter = DateFormatter()
        dateFormatter.dateStyle = .long
        return dateFormatter.string(from: sortedKeys[section] as Date)
    }
    
    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "eventCell")!
        let key = sortedKeys[indexPath.section]
        let event = events[key]![indexPath.row]
        if event.fileID != nil {
            cell.accessoryType = .disclosureIndicator
        }
        cell.textLabel?.text = event.name
        return cell
    }
    
    // MARK: - Navigation
    
    override func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        let key = sortedKeys[indexPath.section]
        let event = events[key]![indexPath.row]
        if let vc = sb.instantiateViewController(withIdentifier: "directoryView") as? DirectoryTableViewController {
            File.getFileById(id: "\(event.fileID!)") { file in
                vc.file = file
                self.navigationController?.pushViewController(vc, animated: true)
            }
        }
    }
    
    // MARK: - Clear Activity
    
    @IBAction func clearActivity(_ sender: AnyObject) {
        overlay?.showWithAnimation()
        Events.clear {
            self.delay(delay: 1) {
                self.fetch(sender: self)
            }
        }
    }

}
