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
        
        refreshControl?.addTarget(self, action: #selector(fetch), for: UIControlEvents.valueChanged)
        
        fetch(self)
    }
    
    func fetch(_ sender: AnyObject?) {
        Feeds.get { feeds, error in
            self.feeds = feeds
            self.tableView.reloadData()
            self.refreshControl?.endRefreshing()
            
            self.overlay?.hideWithAnimation()
            if feeds.count == 0 {
                self.noResults!.isHidden = false
            } else {
                self.noResults!.isHidden = true
            }
            
        }
    }

    // MARK: - Table view data source

    override func numberOfSections(in tableView: UITableView) -> Int {
        return 1
    }

    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return feeds.count
    }

    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "rssCell", for: indexPath)

        let feed = feeds[indexPath.row]
        
        cell.textLabel?.text = feed.title

        if let paused = feed.paused, paused {
            cell.imageView?.tintColor = .lightGray
        } else {
            cell.imageView?.tintColor = .fetchGreen()
        }

        return cell
    }
    
    
    // MARK: - Row Actions
    
    override func tableView(_ tableView: UITableView, editActionsForRowAt indexPath: IndexPath) -> [UITableViewRowAction]? {
        
        let feed = feeds[indexPath.row]
        let deleteAction = UITableViewRowAction(style: UITableViewRowActionStyle.default, title: "Delete", handler: deleteFeed)
        
        var title = "Pause"
        
        if feed.paused != nil && feed.paused == true {
            title = "Resume"
        }

        let additionalAction = UITableViewRowAction(style: .normal, title: title, handler: pauseResumeFeed)
        additionalAction.backgroundColor = UIColor(hue: 0, saturation: 0, brightness: 0.25, alpha: 1)
        return [deleteAction, additionalAction]
    }
    
    /**
     Pause or resume a feed on the server
     
     - parameter action:    The row action that's being called
     - parameter indexPath: The indexPath for the row.
     */
    func pauseResumeFeed(_ action: UITableViewRowAction!, indexPath: IndexPath!) {
        let feed = feeds[indexPath.row]
        
        if feed.paused != nil && feed.paused == true {
            feed.paused = false
            feed.resume()
        } else {
            feed.paused = true
            feed.pause()
        }
        
        tableView.setEditing(false, animated: true)
        tableView.reloadRows(at: [indexPath], with: .none)
    }
    
    
    /**
     Delete the feed from the server and remove the row from the table. It will display the `noResults` view if necessary.
     
     - parameter action:    The row action that's being called
     - parameter indexPath: The indexPath for the row
     */
    func deleteFeed(_ action: UITableViewRowAction!, indexPath: IndexPath!) {
        
        let feed = feeds[indexPath.row]
        let alert = FetchAlertController(title: "Delete Feed", message: "Are you sure you want to feed: '\(feed.title!)'?", preferredStyle: .actionSheet)
        
        alert.addAction(UIAlertAction(title: "Delete File", style: .destructive) { action in
            
            feed.delete()
            self.feeds.remove(at: indexPath.row)
            
            if self.feeds.count == 0 {
                self.noResults?.isHidden = false
            }
            
            self.tableView.deleteRows(at: [indexPath], with: .left)

        })
        
        alert.addAction(UIAlertAction(title: "Cancel", style: .cancel) { action in
            self.tableView.setEditing(false, animated: true)
        })
        
        let cell = tableView.cellForRow(at: indexPath)!
        
        alert.popoverPresentationController?.sourceView = cell
        alert.popoverPresentationController?.sourceRect = CGRect(x: cell.frame.width+65, y: 0, width: 80, height: cell.frame.height)
        
        present(alert, animated: true, completion: nil)
        
    }


}
