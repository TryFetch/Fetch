//
//  RSSTableViewController.swift
//  Fetch
//
//  Created by Stephen Radford on 08/01/2016.
//  Copyright © 2016 Cocoon Development Ltd. All rights reserved.
//

import UIKit
import PutioKit

class RSSTableViewController: UITableViewController {
    
    var feeds: [Feed] = []
    
    var overlay: LoaderView?
    
    var noResults: NoResultsView?
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        overlay = LoaderView(frame: tableView.frame)
        tableView.addSubview(overlay!.view)
        
        noResults = NoResultsView(frame: tableView.frame, text: "Add an RSS feed to begin.")
        tableView.addSubview(noResults!)
        
        refreshControl?.addTarget(self, action: #selector(fetch), forControlEvents: UIControlEvents.ValueChanged)
        
        fetch(self)
    }
    
    func fetch(sender: AnyObject?) {
        Feeds.get { feeds, error in
            self.feeds = feeds
            self.tableView.reloadData()
            self.refreshControl?.endRefreshing()
            
            self.overlay?.hideWithAnimation()
            if feeds.count == 0 {
                self.noResults!.hidden = false
            } else {
                self.noResults!.hidden = true
            }
            
        }
    }

    // MARK: - Table view data source

    override func numberOfSectionsInTableView(tableView: UITableView) -> Int {
        return 1
    }

    override func tableView(tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return feeds.count
    }

    override func tableView(tableView: UITableView, cellForRowAtIndexPath indexPath: NSIndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCellWithIdentifier("rssCell", forIndexPath: indexPath)

        let feed = feeds[indexPath.row]
        
        cell.textLabel?.text = feed.title
        cell.imageView?.tintColor = (feed.paused != nil && feed.paused == true) ? .lightGrayColor() : .fetchGreen()

        return cell
    }
    
    
    // MARK: - Row Actions
    
    override func tableView(tableView: UITableView, editActionsForRowAtIndexPath indexPath: NSIndexPath) -> [UITableViewRowAction]? {
        
        let feed = feeds[indexPath.row]
        let deleteAction = UITableViewRowAction(style: UITableViewRowActionStyle.Default, title: "Delete", handler: deleteFeed)
        
        var title = "Pause"
        
        if feed.paused != nil && feed.paused == true {
            title = "Resume"
        }

        let additionalAction = UITableViewRowAction(style: .Normal, title: title, handler: pauseResumeFeed)
        additionalAction.backgroundColor = UIColor(hue: 0, saturation: 0, brightness: 0.25, alpha: 1)
        return [deleteAction, additionalAction]
    }
    
    /**
     Pause or resume a feed on the server
     
     - parameter action:    The row action that's being called
     - parameter indexPath: The indexPath for the row.
     */
    func pauseResumeFeed(action: UITableViewRowAction!, indexPath: NSIndexPath!) {
        let feed = feeds[indexPath.row]
        
        if feed.paused != nil && feed.paused == true {
            feed.paused = false
            feed.resume()
        } else {
            feed.paused = true
            feed.pause()
        }
        
        tableView.setEditing(false, animated: true)
        tableView.reloadRowsAtIndexPaths([indexPath], withRowAnimation: .None)
    }
    
    
    /**
     Delete the feed from the server and remove the row from the table. It will display the `noResults` view if necessary.
     
     - parameter action:    The row action that's being called
     - parameter indexPath: The indexPath for the row
     */
    func deleteFeed(action: UITableViewRowAction!, indexPath: NSIndexPath!) {
        
        let feed = feeds[indexPath.row]
        let alert = FetchAlertController(title: "Delete Feed", message: "Are you sure you want to feed: '\(feed.title!)'?", preferredStyle: .ActionSheet)
        
        alert.addAction(UIAlertAction(title: "Delete File", style: .Destructive) { action in
            
            feed.delete()
            self.feeds.removeAtIndex(indexPath.row)
            
            if self.feeds.count == 0 {
                self.noResults?.hidden = false
            }
            
            self.tableView.deleteRowsAtIndexPaths([indexPath], withRowAnimation: .Left)

        })
        
        alert.addAction(UIAlertAction(title: "Cancel", style: .Cancel){ action in
            self.tableView.setEditing(false, animated: true)
        })
        
        let cell = tableView.cellForRowAtIndexPath(indexPath)!
        
        alert.popoverPresentationController?.sourceView = cell
        alert.popoverPresentationController?.sourceRect = CGRect(x: cell.frame.width+65, y: 0, width: 80, height: cell.frame.height)
        
        presentViewController(alert, animated: true, completion: nil)
        
    }


}
