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

    override func numberOfSections(in tableView: UITableView) -> Int {
        // #warning Incomplete implementation, return the number of sections
        return 1
    }

    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        // #warning Incomplete implementation, return the number of rows
        return faqs.count
    }
    
    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "faqCell")!
        cell.textLabel?.text = faqs[indexPath.row].question
        return cell
    }
    
    override func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        tableView.deselectRow(at: indexPath, animated: true)
    }
    
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        if let vc = segue.destination as? AnswerViewController, let indexPath = tableView.indexPathForSelectedRow {
            vc.faq = faqs[indexPath.row]
        }
    }
    
    // MARK: - Network
    
    func getFAQs() {
        UIApplication.shared.isNetworkActivityIndicatorVisible = true
        Alamofire.request("https://ftch.in/api/faqs", method: .get)
            .responseJSON { response in
                UIApplication.shared.isNetworkActivityIndicatorVisible = false
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
