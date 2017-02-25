//
//  DownloadsTableViewController.swift
//  Fetch
//
//  Created by Stephen Radford on 06/03/2016.
//  Copyright © 2016 Cocoon Development Ltd. All rights reserved.
//

import UIKit
import AVKit
import AVFoundation

class DownloadsTableViewController: UITableViewController, DownloaderDelegate {

    var percentage = "0%"
    
    var noResultsView: NoResultsView!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        Downloader.sharedInstance.delegate = self
        noResultsView = NoResultsView(frame: tableView.bounds, text: "Add a file to the queue to begin.")
        noResultsView.backgroundColor = UIColor(hue: 0, saturation: 0, brightness: 0.12, alpha: 1)
        tableView.addSubview(noResultsView)
        showNoResultsIfRequired()
    }
    
    func showNoResultsIfRequired() {
        if Downloader.sharedInstance.queue.count > 0 || Downloader.sharedInstance.downloadedFiles.count > 0 {
            noResultsView.hidden = true
        } else {
            noResultsView.hidden = false
        }
    }

    // MARK: - DownloaderDelegate
    
    func percentageChanged(percentage: String) {
        self.percentage = percentage
        if !tableView.editing {
            tableView.reloadData()
            showNoResultsIfRequired()
        }
    }
    
    func downloadCompleted() {
        percentage = "0%"
        tableView.reloadData()
        showNoResultsIfRequired()
    }
    
    func downloadError(error: NSError) {
        if error.code != -999 {
            let alert = FetchAlertController(title: "Could Not Download", message: "The download could not be completed. Do you have an internet connection or enough storage?", preferredStyle: .Alert)
            alert.addAction(UIAlertAction(title: "OK", style: .Default, handler: nil))
            presentViewController(alert, animated: true, completion: nil)
            tableView.reloadData()
            showNoResultsIfRequired()
        }
    }
    
    

    // MARK: - Table view data source

    override func numberOfSectionsInTableView(tableView: UITableView) -> Int {
        return 2
    }

    override func tableView(tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        if section == 0 {
            return Downloader.sharedInstance.queue.count
        }
        return Downloader.sharedInstance.downloadedFiles.count
    }
    
    override func tableView(tableView: UITableView, titleForHeaderInSection section: Int) -> String? {
        if section == 0 {
            return (Downloader.sharedInstance.queue.count > 0) ? "Download Queue" : ""
        }
        return (Downloader.sharedInstance.downloadedFiles.count > 0) ? "Files" : ""
    }
    
    override func tableView(tableView: UITableView, heightForHeaderInSection section: Int) -> CGFloat {
        if section == 0 && Downloader.sharedInstance.queue.count == 0 {
            return 0.01
        }
        
        return 44.0
    }
    
    override func tableView(tableView: UITableView, cellForRowAtIndexPath indexPath: NSIndexPath) -> UITableViewCell {
        let identifier = (indexPath.section == 0) ? "queued" : "downloaded"
        let cell = tableView.dequeueReusableCellWithIdentifier(identifier)!
        
        if indexPath.section == 0 {
            cell.textLabel?.text = Downloader.sharedInstance.queue[indexPath.row].name
            cell.detailTextLabel?.text = (indexPath.row == 0) ? "Downloading… \(percentage)" : "Queued"
        } else {
            cell.textLabel?.text = Downloader.sharedInstance.downloadedFiles[indexPath.row]
        }
        return cell
    }
    
    
    
    // MARK: - Delete Files
    
    override func tableView(tableView: UITableView, editActionsForRowAtIndexPath indexPath: NSIndexPath) -> [UITableViewRowAction]? {
        if indexPath.section == 0 {
            if indexPath.row == 0 {
                return [
                    UITableViewRowAction(style: .Destructive, title: "Cancel") { action, indexPath in
                        Downloader.sharedInstance.currentRequest?.cancel()
                        if(Downloader.sharedInstance.queue.count > 0) { Downloader.sharedInstance.queue.removeFirst() }
                        self.tableView.beginUpdates()
                        self.tableView.deleteRowsAtIndexPaths([indexPath], withRowAnimation: .Automatic)
                        self.tableView.endUpdates()
                        self.showNoResultsIfRequired()
                    }
                ]
            } else {
                return [
                    UITableViewRowAction(style: .Destructive, title: "Remove") { action, indexPath in
                        Downloader.sharedInstance.queue.removeAtIndex(indexPath.row)
                        self.tableView.beginUpdates()
                        self.tableView.deleteRowsAtIndexPaths([indexPath], withRowAnimation: .Automatic)
                        self.tableView.endUpdates()
                        self.showNoResultsIfRequired()
                    }
                ]
            }
        } else {
            return [
                UITableViewRowAction(style: .Destructive, title: "Delete") { action, indexPath in
                    Downloader.sharedInstance.deleteFileAtIndex(indexPath.row)
                    self.tableView.beginUpdates()
                    self.tableView.deleteRowsAtIndexPaths([indexPath], withRowAnimation: .Automatic)
                    self.tableView.endUpdates()
                    self.showNoResultsIfRequired()
                },

                UITableViewRowAction(style: .Normal, title: "Share") { [unowned self] action, indexPath in
                    let path = Downloader.sharedInstance.downloadedFiles[indexPath.row]
                    let documentsUrl =  NSFileManager.defaultManager().URLsForDirectory(.DocumentDirectory, inDomains: .UserDomainMask).first!
                    let URL = documentsUrl.URLByAppendingPathComponent(path)!
                    let viewController = UIActivityViewController(activityItems: [URL], applicationActivities: nil)
                    let frame = self.tableView.rectForRowAtIndexPath(indexPath)
                    viewController.popoverPresentationController?.sourceView = self.tableView
                    viewController.popoverPresentationController?.sourceRect = frame
                    self.presentViewController(viewController, animated: true, completion: nil)
                },
            ]
        }
    }
    
    
    // MARK: - Play File
    
    override func tableView(tableView: UITableView, didSelectRowAtIndexPath indexPath: NSIndexPath) {
        if indexPath.section == 0 {
            tableView.deselectRowAtIndexPath(indexPath, animated: false)
        } else {
            if Downloader.sharedInstance.downloadedFiles.count > indexPath.row {
                performSegueWithIdentifier("showPlayer", sender: Downloader.sharedInstance.downloadedFiles[indexPath.row])
            }
        }
    }
    
    override func prepareForSegue(segue: UIStoryboardSegue, sender: AnyObject?) {
        if let vc = segue.destinationViewController as? AVPlayerViewController, let file = sender as? String {
            vc.delegate = PlayerDelegate.sharedInstance

            let documentsUrl =  NSFileManager.defaultManager().URLsForDirectory(.DocumentDirectory, inDomains: .UserDomainMask).first!
            let fileUrl = documentsUrl.URLByAppendingPathComponent(file)
            
            let player = AVPlayer(URL: fileUrl!)
            vc.player = player
            vc.player?.play()
            
        }
    }

}
