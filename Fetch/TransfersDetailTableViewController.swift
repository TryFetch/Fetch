//
//  TransfersDetailTableViewController.swift
//  Fetch
//
//  Created by Stephen Radford on 26/05/2015.
//  Copyright (c) 2015 Cocoon Development Ltd. All rights reserved.
//

import UIKit

class TransfersDetailTableViewController: UITableViewController {
    
    var transfer: Transfer?
    var rows: [String] = ["Status", "Percentage Complete", "File Size"]
    var values: [String] = ["-", "-", "-"]

    override func viewDidLoad() {
        super.viewDidLoad()
        
        self.title = transfer?.name
        
        if transfer == nil {
            showOverlay()
        } else {
            
            var percent = (transfer?.percent_done != nil) ? transfer?.percent_done : 0
            
            if(transfer?.status == .Completed) {
                values[0] = "Completed"
                percent = 100
            } else if(transfer?.status == .Queued) {
                values[0] = "Queued"
            } else {
                values[0] = "In Progress"
            }
            
            values[1] = "\(percent!)%"
            
            let formatter = NSByteCountFormatter()
            let size = formatter.stringFromByteCount(transfer!.size)
            values[2] = "\(size)"
            
        }
        
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
    }

    // MARK: - Table view data source

    override func numberOfSectionsInTableView(tableView: UITableView) -> Int {
        // #warning Potentially incomplete method implementation.
        // Return the number of sections.
        return 1
    }

    override func tableView(tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        // #warning Incomplete method implementation.
        // Return the number of rows in the section.
        return rows.count
    }

    
    override func tableView(tableView: UITableView, cellForRowAtIndexPath indexPath: NSIndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCellWithIdentifier("reuseIdentifier", forIndexPath: indexPath) 

        cell.textLabel?.text = rows[indexPath.row]
        cell.detailTextLabel?.text = values[indexPath.row]

        return cell
    }
    
    // MARK: - Overlay
    
    func showOverlay() {
        
        let frame = view.frame
        var noTransfers: UIView?
        noTransfers = UIView(frame: frame)
        noTransfers!.hidden = false
        noTransfers!.autoresizingMask = [UIViewAutoresizing.FlexibleWidth, UIViewAutoresizing.FlexibleHeight]
        noTransfers!.backgroundColor = UIColor(hue: 0, saturation: 0, brightness: 0.12, alpha: 1)
        noTransfers!.layer.zPosition = 10
        view.addSubview(noTransfers!)
        
    }
    
}
