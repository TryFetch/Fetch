//
//  TransfersTableViewController.swift
//  Fetch
//
//  Created by Stephen Radford on 25/05/2015.
//  Copyright (c) 2015 Cocoon Development Ltd. All rights reserved.
//

import UIKit
import Alamofire
import SwiftyJSON
import PutioKit

class TransfersTableViewController: UITableViewController {

    var transfers: [Transfer] = []
    var selectedIndex: Int?
    var overlay: LoaderView?
    var noTransfers: UIView?
    var timer: Timer?
    var detailViewController: UINavigationController?
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        splitViewController?.preferredDisplayMode = .allVisible
        
        // Setup refresh control
        refreshControl?.addTarget(self, action: #selector(refresh), for: UIControlEvents.valueChanged)
        
        // Setup a loader
        overlay = LoaderView(frame: tableView.frame)
        tableView.addSubview(overlay!.view)
        
        // Setup no transfers
        setupNoTransfers()
        
        // Fetch the transfers
        fetch()
        
        splitViewController?.view.backgroundColor = UIColor.fetchLighterBackground()
        
        let sb = UIStoryboard(name: "Transfers", bundle: nil)
        
        if let vc = sb.instantiateViewController(withIdentifier: "detailViewController") as? UINavigationController {
            detailViewController = vc
        }
        
    }
    
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        setupTimer()
    }
    
    override func viewDidDisappear(_ animated: Bool) {
        super.viewDidDisappear(animated)
        timer?.invalidate()
        timer = nil
    }
    
    
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        overlay = nil
        timer?.invalidate()
        timer = nil
    }
    
    override var preferredStatusBarStyle : UIStatusBarStyle {
        return .lightContent
    }

    // MARK: - Table view data source

    override func numberOfSections(in tableView: UITableView) -> Int {
        return 1
    }

    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return transfers.count
    }

    
    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "transfer", for: indexPath) 

        cell.textLabel?.text = transfers[indexPath.row].name
        cell.detailTextLabel?.text = transfers[indexPath.row].status_message
        
        return cell
    }

    
    // Override to support editing the table view.
    override func tableView(_ tableView: UITableView, commit editingStyle: UITableViewCellEditingStyle, forRowAt indexPath: IndexPath) {

        if editingStyle == .delete {
        
            // If we're in split view (i.e. not collapsed) then we need to change the detail view
            if selectedIndex == indexPath.row && !splitViewController!.isCollapsed {
                performSegue(withIdentifier: "showDetail", sender: nil)
            }
            
            let transfer = transfers[indexPath.row]
            transfer.destroy()
            transfers.remove(at: indexPath.row)
            tableView.deleteRows(at: [indexPath], with: .automatic)
            
            if self.transfers.count == 0 {
                self.noTransfers!.isHidden = false
            } else {
                self.noTransfers!.isHidden = true
            }
            
            
        }
        
    }

    
    // MARK: - Navigation
    
    override func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        
        let childvc: TransfersDetailTableViewController = detailViewController!.childViewControllers[0] as! TransfersDetailTableViewController
        childvc.transfer = transfers[indexPath.row]
        
        splitViewController?.showDetailViewController(detailViewController!, sender: self)
        
        tableView.deselectRow(at: indexPath, animated: true)
        
    }



    // MARK: - Network
    
    func refresh(_ sender: UIRefreshControl) {
        refreshControl?.beginRefreshing()
        fetch()
    }
    
    func reload() {
        overlay?.show()
        fetch()
    }
    
    func fetch() {
        
        Putio.get("transfers/list") { json, error in
            
            self.overlay?.hideWithAnimation()
            self.refreshControl?.endRefreshing()
            
            self.transfers = []
            if let transfers = json?["transfers"] {
                for (_, trans): (String, JSON) in transfers {
                    
                    let transfer = Transfer(id: trans["id"].int!, name: trans["name"].string!, status_message: trans["status_message"].string!, status: trans["status"].string!, percent_done: trans["percent_done"].int!, size: trans["size"].int64!, estimated_time: trans["estimated_time"].int64)
                    
                    self.transfers.append(transfer)
                    
                }
                
                if self.transfers.count == 0 {
                    self.noTransfers!.isHidden = false
                } else {
                    self.noTransfers!.isHidden = true
                }
                
                self.tableView.reloadData()
            }

            
        }
        
    }
    
    // MARK: - No Transfers
    
    func setupNoTransfers() {
        let frame = view.frame
        noTransfers = NoResultsView(frame: frame, text: "Add a transfer to begin.")
        view.addSubview(noTransfers!)
    }
    
    // MARK: - Clear Completed
    
    
    @IBAction func clearCompleted(_ sender: AnyObject) {
        
        let alert = FetchAlertController(title: "Clear Completed", message: "Do you want to clear all completed transfers?", preferredStyle: .alert)
        
        alert.addAction(UIAlertAction(title: "Yes", style: .default, handler: { action in
            self.cleanUp()
        }))
        
        alert.addAction(UIAlertAction(title: "No", style: .cancel, handler: nil))
        
        let subView = alert.view.subviews.first!
        let contentView = subView.subviews.first!
        for view in contentView.subviews[0].subviews {
            view.backgroundColor = UIColor.white
            view.alpha = 1
        }
        
        present(alert, animated: true, completion: nil)
        
    }

    func cleanUp() {
        
        UIApplication.shared.isNetworkActivityIndicatorVisible = true
        self.overlay?.show()
        
        let params = ["oauth_token": "\(Putio.accessToken!)"]
        Alamofire.request("\(Putio.api)transfers/clean", method: .post, parameters: params)
            .response { response in
                UIApplication.shared.isNetworkActivityIndicatorVisible = false
                self.fetch()
            }
        
    }
    
    
    // MARK: - Timer
    
    func intervalFetch(_ sender: Timer) {
        fetch()
    }
    
    func setupTimer() {
        if timer == nil {
            timer = Timer.scheduledTimer(timeInterval: 10, target: self, selector: #selector(intervalFetch), userInfo: nil, repeats: true)
        }
    }

}
