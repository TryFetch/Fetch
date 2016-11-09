//
//  DetailViewController.swift
//  Fetch
//
//  Created by Stephen Radford on 19/05/2015.
//  Copyright (c) 2015 Cocoon Development Ltd. All rights reserved.
//

import UIKit
import Alamofire
import SwiftyJSON
import TUSafariActivity
import PutioKit

class DetailViewController: UITableViewController {

    var file: File!
    var mp4Status: String?
    var mp4Percent: Int = 0
    var timer: NSTimer?
    var times: Int = 0
    var activitySheet: UIActivityViewController!
    
    var url: NSURL!
    let safari = TUSafariActivity()
    let vlc = OpenInVLC()
    
    var sections = [
        ["Name", "Size", "Type"]
    ]
    
    var rows = [
        "Name": "-",
        "Size": "-",
        "Type": "-"
    ]
    
    @IBOutlet weak var fileNameLabel: UILabel!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        createActionSheet()
        url = NSURL(string: "\(Putio.api)files/\(file.id)/download?oauth_token=\(Putio.accessToken!)")!
        
        // Set the title for the navbar
        self.title = "Details"
        
        // Do we need a convert button?
        if(file.content_type != "video/mp4" && file.content_type?.rangeOfString("video") != nil && !file.has_mp4) {
            getMp4Status(nil)
            sections.append(["-"])
        }
        
        // Setup the rows
        rows["Name"] = file.name
        
        let formatter = NSByteCountFormatter()
        let size = formatter.stringFromByteCount(file.size)
        
        rows["Size"] = size
        rows["Type"] = file.content_type
        
    }
    
    override func viewDidAppear(animated: Bool) {
        super.viewDidAppear(animated)
    }
    
    override func viewDidDisappear(animated: Bool) {
        super.viewDidDisappear(animated)
        timer?.invalidate()
        timer = nil
    }
    

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        file = nil
        timer?.invalidate()
        timer = nil
    }
    
    // MARK: - Table view data source
    
    override func numberOfSectionsInTableView(tableView: UITableView) -> Int {
        // #warning Potentially incomplete method implementation.
        // Return the number of sections.
        return sections.count
    }
    
    override func tableView(tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        // #warning Incomplete method implementation.
        // Return the number of rows in the section.
        return sections[section].count
    }
    
    
    override func tableView(tableView: UITableView, cellForRowAtIndexPath indexPath: NSIndexPath) -> UITableViewCell {
        
        var cell: UITableViewCell
        
        let row = sections[indexPath.section][indexPath.row]
        
        if indexPath.section == 0 {
            cell = tableView.dequeueReusableCellWithIdentifier("reuseIdentifier", forIndexPath: indexPath) 
            cell.textLabel!.text = row
            cell.detailTextLabel!.text = rows[row]
        } else {
            
            cell = tableView.dequeueReusableCellWithIdentifier("mp4Btn", forIndexPath: indexPath) 
            cell.selectionStyle = .None
            cell.textLabel?.textColor = UIColor.grayColor()
            
            var text: String!
            
            if mp4Status == "IN_QUEUE" {
                text = "In Conversion Queue..."
                setupTimer()
            } else if mp4Status == "CONVERTING" {
                text = "Converting to MP4... \(mp4Percent)%"
                setupTimer()
            } else if mp4Status == "COMPLETED" {
                text = "Successfully Converted!"
                timer?.invalidate()
                timer = nil
            } else if mp4Status == "NOT_AVAILABLE" {
                text = "Convert to MP4"
                cell.textLabel?.textColor = UIColor(red:0, green:0.48, blue:1, alpha:1)
                cell.selectionStyle = .Default
            } else {
                text = "Checking MP4 Status..."
            }
            
            cell.textLabel!.text = text
        }
        
        
        return cell
    }
    
    // MARK: - Table View Selection
    
    override func tableView(tableView: UITableView, didSelectRowAtIndexPath indexPath: NSIndexPath) {
        
        if indexPath.section == 1 && mp4Status == "NOT_AVAILABLE" {
            file.convertToMp4()
            let cell = tableView.cellForRowAtIndexPath(indexPath)
            cell?.textLabel?.text = "Added to Queue..."
            cell?.textLabel?.textColor = UIColor.grayColor()
            cell?.selectionStyle = .None
            setupTimer()
        }
        
    }
    
    // MARK: - MP4 status & timer
    
    func getMp4Status(sender: AnyObject?) {
        UIApplication.sharedApplication().networkActivityIndicatorVisible = true
        let params = ["oauth_token": "\(Putio.accessToken!)"]
        
        times += 1
        print("called \(times)")
        
        Alamofire.request(.GET, "\(Putio.api)files/\(file.id)/mp4", parameters: params)
            .responseJSON { response in
                UIApplication.sharedApplication().networkActivityIndicatorVisible = false
                
                if response.result.isFailure {
                    print(response.result.error)
                } else {
                    let json = JSON(response.result.value!)
                    self.mp4Status = json["mp4"]["status"].string
                    
                    if json["mp4"]["percent_done"] != nil {
                        self.mp4Percent = json["mp4"]["percent_done"].int!
                    }
                    
                    self.tableView.reloadData()
                }
                
        }
        
    }
    
    func setupTimer() {
        if timer == nil {
            timer = NSTimer.scheduledTimerWithTimeInterval(2, target: self, selector: #selector(getMp4Status), userInfo: nil, repeats: true)
        }
    }
    
    
    // MARK: - Action Sheet
    
    func createActionSheet() {
        
        navigationItem.rightBarButtonItem = UIBarButtonItem(barButtonSystemItem: UIBarButtonSystemItem.Action, target: self, action: #selector(showActionSheet))
        
    }
    
    func showActionSheet(sender: AnyObject) {
        
        activitySheet = UIActivityViewController(activityItems: [url], applicationActivities: [safari, vlc])
        activitySheet.excludedActivityTypes = [
            UIActivityTypePostToFacebook,
            UIActivityTypePostToFlickr,
            UIActivityTypePostToTwitter,
            UIActivityTypeAddToReadingList,
            UIActivityTypeAirDrop
        ]
        
        activitySheet.popoverPresentationController?.barButtonItem = navigationItem.rightBarButtonItem

        presentViewController(activitySheet, animated: true, completion: nil)
        
    }
}
