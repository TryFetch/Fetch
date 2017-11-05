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
            
            if(transfer?.status == .completed) {
                values[0] = "Completed"
                percent = 100
            } else if(transfer?.status == .queued) {
                values[0] = "Queued"
            } else {
                values[0] = "In Progress"
            }
            
            values[1] = "\(percent!)%"
            
            let formatter = ByteCountFormatter()
            let size = formatter.string(fromByteCount: transfer!.size)
            values[2] = "\(size)"
            
        }
        
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
    }

    // MARK: - Table view data source

    override func numberOfSections(in tableView: UITableView) -> Int {
        // #warning Potentially incomplete method implementation.
        // Return the number of sections.
        return 1
    }

    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        // #warning Incomplete method implementation.
        // Return the number of rows in the section.
        return rows.count
    }

    
    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "reuseIdentifier", for: indexPath) 

        cell.textLabel?.text = rows[indexPath.row]
        cell.detailTextLabel?.text = values[indexPath.row]

        return cell
    }
    
    // MARK: - Overlay
    
    func showOverlay() {
        
        let frame = view.frame
        var noTransfers: UIView?
        noTransfers = UIView(frame: frame)
        noTransfers!.isHidden = false
        noTransfers!.autoresizingMask = [UIViewAutoresizing.flexibleWidth, UIViewAutoresizing.flexibleHeight]
        noTransfers!.backgroundColor = UIColor(hue: 0, saturation: 0, brightness: 0.12, alpha: 1)
        noTransfers!.layer.zPosition = 10
        view.addSubview(noTransfers!)
        
    }
    
}
