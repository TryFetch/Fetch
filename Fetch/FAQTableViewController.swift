//
//  FAQTableViewController.swift
//  Fetch
//
//  Created by Stephen Radford on 20/03/2016.
//  Copyright © 2016 Cocoon Development Ltd. All rights reserved.
//

import UIKit
import Alamofire
import SwiftyJSON

struct FAQ {
    var question: String?
    var answer: String?
}


class FAQTableViewController: UITableViewController {
    
    var faqs = [FAQ]()
    var overlay: LoaderView?
    
    override func viewDidLoad() {
        super.viewDidLoad()

        overlay = LoaderView(frame: tableView.frame)
        tableView.addSubview(overlay!.view)
        
        tableView.rowHeight = UITableViewAutomaticDimension
        tableView.estimatedRowHeight = 44
        
        getFAQs()
    }

    // MARK: - Table view data source

    override func numberOfSectionsInTableView(tableView: UITableView) -> Int {
        // #warning Incomplete implementation, return the number of sections
        return 1
    }

    override func tableView(tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        // #warning Incomplete implementation, return the number of rows
        return faqs.count
    }
    
    override func tableView(tableView: UITableView, cellForRowAtIndexPath indexPath: NSIndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCellWithIdentifier("faqCell")!
        cell.textLabel?.text = faqs[indexPath.row].question
        return cell
    }
    
    override func tableView(tableView: UITableView, didSelectRowAtIndexPath indexPath: NSIndexPath) {
        tableView.deselectRowAtIndexPath(indexPath, animated: true)
    }
    
    override func prepareForSegue(segue: UIStoryboardSegue, sender: AnyObject?) {
        if let vc = segue.destinationViewController as? AnswerViewController, indexPath = tableView.indexPathForSelectedRow {
            vc.faq = faqs[indexPath.row]
        }
    }
    
    // MARK: - Network
    
    func getFAQs() {
        UIApplication.sharedApplication().networkActivityIndicatorVisible = true
        Alamofire.request(.GET, "https://ftch.in/api/faqs")
            .responseJSON { response in
                UIApplication.sharedApplication().networkActivityIndicatorVisible = false
                if let data = response.result.value {
                    let json = JSON(data)
                    let faqs: [FAQ] = json.array!.map { f in
                        var faq = FAQ()
                        faq.question = f["question"].string
                        faq.answer = f["answer"].string
                        return faq
                    }
                    self.faqs = faqs
                    self.tableView.reloadData()
                    self.overlay?.hideWithAnimation()
                }
            }
    }

}
